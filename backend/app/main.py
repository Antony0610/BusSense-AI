"""
BusSense AI - Core FastAPI Intelligence Application
Climate-smart public transit intelligence platform.
Core flow: SEE -> SENSE -> PREDICT -> RECOMMEND -> OPTIMIZE
"""
import asyncio
from typing import Optional
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.services.gps_simulator import gps_simulator
from app.api import (
    auth,
    buses,
    routes,
    stops,
    occupancy,
    recommendations,
    tickets,
    incidents,
    analytics,
    ai,
    trips,
    locations,
    crowd,
    predictions,
    alerts,
    payments,
    user,
    conductor,
    realtime,
    notifications
)
from app.schemas.realtime import RealtimeEvent, RealtimeEventType
from app.services.realtime_service import realtime_service
from app.core.security import get_current_user


# Active WebSocket connections for live telemetry broadcast
class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in list(self.active_connections):
            try:
                await connection.send_json(message)
            except Exception:
                self.disconnect(connection)

ws_manager = ConnectionManager()

_active_crowd_alerts = set()

# Background task for corridor simulation updates
async def run_simulation_loop():
    while True:
        try:
            gps_simulator.tick_simulation()
            # Broadcast updated positions to connected clients
            telemetry = gps_simulator.get_all_buses()
            await ws_manager.broadcast({
                "type": "FLEET_TELEMETRY_UPDATE",
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "buses": telemetry
            })
            await realtime_service.publish_event(RealtimeEvent(
                event_type=RealtimeEventType.FLEET_TELEMETRY_UPDATE.value,
                entity_id="fleet_all",
                data_origin=DataOrigin.SIMULATED.value,
                payload={"buses": telemetry}
            ))

            # Deduplicated crowding alert monitoring (persists directly to Supabase)
            for bus in telemetry:
                bus_num = bus.get("bus_number")
                occ = bus.get("occupancy_pct", 0)
                if occ >= 80.0 and bus_num not in _active_crowd_alerts:
                    bus_rec = await supabase_client.get_bus_by_number(bus_num)
                    if bus_rec:
                        existing = await supabase_client.get("alerts", {
                            "affected_bus_id": f"eq.{bus_rec['id']}",
                            "is_active": "eq.true"
                        })
                        if not existing:
                            await supabase_client.post("alerts", {
                                "title": f"High Crowding Alert — Bus {bus_num}",
                                "message": f"Bus {bus_num} has reached {occ:.1f}% capacity on primary corridor.",
                                "severity": "WARNING",
                                "affected_bus_id": bus_rec["id"],
                                "is_active": True
                            })
                            # Publish ALERT_UPDATE via realtime service
                            await realtime_service.publish_event(RealtimeEvent(
                                event_type=RealtimeEventType.ALERT_UPDATE.value,
                                entity_id=str(bus_rec["id"]),
                                data_origin=DataOrigin.SIMULATED.value,
                                payload={
                                    "title": f"High Crowding Alert — Bus {bus_num}",
                                    "message": f"Bus {bus_num} has reached {occ:.1f}% capacity on primary corridor.",
                                    "severity": "WARNING",
                                    "bus_number": bus_num,
                                    "occupancy_pct": occ
                                }
                            ))
                    _active_crowd_alerts.add(bus_num)
                elif occ < 70.0 and bus_num in _active_crowd_alerts:
                    _active_crowd_alerts.discard(bus_num)
                    bus_rec = await supabase_client.get_bus_by_number(bus_num)
                    if bus_rec:
                        await supabase_client.patch("alerts", "affected_bus_id", bus_rec["id"], {
                            "is_active": False
                        })
        except Exception as e:
            print(f"[Simulation Error] {e}")
        await asyncio.sleep(settings.SIMULATION_INTERVAL_SECONDS)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Launch background simulation worker
    sim_task = asyncio.create_task(run_simulation_loop())
    print("[BusSense AI] Background GPS & Occupancy simulation loop started.")
    yield
    # Shutdown: Cancel simulation worker
    sim_task.cancel()
    print("[BusSense AI] Background simulation stopped.")

app = FastAPI(
    title="BusSense AI Platform API",
    description="Climate-smart public bus intelligence platform API combining CCTV/YOLOv8 occupancy, GPS tracking, demand forecasting and explainable recommendations.",
    version="1.0.0",
    lifespan=lifespan
)

from app.core.supabase import supabase_client

# CORS Middleware with restricted configured origins (Never wildcard with credentials)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# Register API Routers
app.include_router(auth.router, prefix="/api")
app.include_router(buses.router, prefix="/api")
app.include_router(routes.router, prefix="/api")
app.include_router(stops.router, prefix="/api")
app.include_router(occupancy.router, prefix="/api")
app.include_router(recommendations.router, prefix="/api")
app.include_router(tickets.router, prefix="/api")
app.include_router(incidents.router, prefix="/api")
app.include_router(analytics.router, prefix="/api")
app.include_router(ai.router, prefix="/api")
app.include_router(trips.router, prefix="/api")
app.include_router(locations.router, prefix="/api")
app.include_router(crowd.router, prefix="/api")
app.include_router(predictions.router, prefix="/api")
app.include_router(alerts.router, prefix="/api")
app.include_router(payments.router, prefix="/api")
app.include_router(user.router, prefix="/api")
app.include_router(conductor.router, prefix="/api")
app.include_router(realtime.router, prefix="/api")
app.include_router(notifications.router, prefix="/api")


@app.get("/")
async def root():
    return {
        "platform": "BusSense AI Intelligence Platform",
        "status": "OPERATIONAL",
        "city": settings.DEFAULT_TRANSIT_CITY,
        "cv_mode": settings.CV_MODE,
        "demo_mode": settings.DEMO_MODE,
        "version": "1.0.0",
        "docs_url": "/docs",
        "data_origin_standard": "All synthetic values strictly labeled as SIMULATED / PREDICTION / RECOMMENDATION"
    }

@app.get("/health")
async def health_check():
    is_connected = await supabase_client.ping()
    return {
        "status": "healthy" if is_connected else "degraded",
        "supabase_connected": is_connected,
        "supabase_project": settings.SUPABASE_URL,
        "active_buses": len(gps_simulator.fleet_state),
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

@app.websocket("/ws/telemetry")
async def websocket_telemetry_endpoint(websocket: WebSocket):
    """
    Public transit telemetry stream.
    Broadcasts real-time vehicle positions, occupancy, and public alerts.
    """
    connected = await realtime_service.connect_public(websocket)
    if not connected:
        return

    # Immediately send initial state
    await websocket.send_json({
        "type": "INITIAL_FLEET_STATE",
        "buses": gps_simulator.get_all_buses()
    })
    try:
        while True:
            # Keep connection open and receive optional ping messages
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text("pong")
    except WebSocketDisconnect:
        realtime_service.disconnect_public(websocket)


@app.websocket("/ws/live")
async def websocket_authenticated_endpoint(websocket: WebSocket, token: Optional[str] = None):
    """
    Authenticated realtime stream with RBAC topic filtering and personal user notifications.
    Supports token via query parameter or initial AUTH handshake message.
    """
    user_payload = None
    if token:
        try:
            user_payload = await get_current_user(token)
        except Exception:
            await websocket.close(code=1008, reason="Invalid authentication credentials")
            return
    else:
        # Accept connection temporarily to await AUTH frame
        await websocket.accept()
        try:
            auth_frame = await asyncio.wait_for(websocket.receive_json(), timeout=5.0)
            if auth_frame.get("type") == "AUTH" and auth_frame.get("token"):
                user_payload = await get_current_user(auth_frame["token"])
            else:
                await websocket.close(code=1008, reason="AUTH handshake expected")
                return
        except Exception:
            await websocket.close(code=1008, reason="Authentication handshake timeout")
            return

    # User authenticated: connect to realtime service
    conn_id = await realtime_service.connect_authenticated(
        websocket=websocket,
        user_id=user_payload.sub,
        role=user_payload.role,
        topics={"public", "user", user_payload.role.lower()}
    )
    if not conn_id:
        return

    # Emit confirmation frame
    await websocket.send_json({
        "type": "AUTH_SUCCESS",
        "user_id": user_payload.sub,
        "role": user_payload.role,
        "timestamp": datetime.now(timezone.utc).isoformat()
    })

    try:
        while True:
            msg = await websocket.receive_text()
            if msg == "ping":
                await websocket.send_text("pong")
    except WebSocketDisconnect:
        realtime_service.disconnect_authenticated(conn_id)
