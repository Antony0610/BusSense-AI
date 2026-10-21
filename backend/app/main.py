"""
BusSense AI - Core FastAPI Intelligence Application
Climate-smart public transit intelligence platform.
Core flow: SEE -> SENSE -> PREDICT -> RECOMMEND -> OPTIMIZE
Hardened for Production Readiness (H14):
- Strict startup environment and security validation
- Standardized container orchestrator probes (/health/live, /health/ready with 200/503)
- Correlation ID middleware (X-Request-ID)
- Centralized sanitized error handling preventing internal/traceback leakage
- Structured Python logging
"""
import asyncio
import uuid
from typing import Optional
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Request, Response, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.logging import setup_logging, get_logger
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
    notifications,
    ingestion
)
from app.schemas.realtime import RealtimeEvent, RealtimeEventType
from app.schemas.common import DataOrigin
from app.services.realtime_service import realtime_service
from app.core.security import get_current_user
from app.core.supabase import supabase_client

# Initialize structured logging
setup_logging()
logger = get_logger("bussense.main")


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
            logger.error("[Simulation Error] %s", str(e))
        await asyncio.sleep(settings.SIMULATION_INTERVAL_SECONDS)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Validate environment configuration
    settings.validate_security_and_environment()
    logger.info(
        "[BusSense AI] Application starting in environment: %s (debug=%s, demo_mode=%s)",
        settings.ENVIRONMENT, settings.DEBUG, settings.DEMO_MODE
    )
    sim_task = asyncio.create_task(run_simulation_loop())
    logger.info("[BusSense AI] Background GPS & Occupancy simulation loop started.")
    yield
    # Shutdown: Cancel simulation worker
    sim_task.cancel()
    logger.info("[BusSense AI] Background simulation stopped.")

app = FastAPI(
    title="BusSense AI Platform API",
    description="Climate-smart public bus intelligence platform API combining CCTV/YOLOv8 occupancy, GPS tracking, demand forecasting and explainable recommendations.",
    version="1.0.0",
    lifespan=lifespan
)

# Correlation ID Middleware (attaches and preserves X-Request-ID header)
@app.middleware("http")
async def correlation_id_middleware(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
    request.state.request_id = request_id
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response

# Centralized Unhandled Exception Handler (Prevents stack trace / database internals leakage)
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
    logger.error("Unhandled server exception [request_id=%s]: %s", request_id, str(exc), exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Internal server error",
            "code": "INTERNAL_SERVER_ERROR",
            "message": "An unexpected server error occurred. Please contact support with this request ID.",
            "request_id": request_id,
            "timestamp": datetime.now(timezone.utc).isoformat()
        },
        headers={"X-Request-ID": request_id}
    )

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
app.include_router(ingestion.router, prefix="/api")


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

@app.get("/health/live", tags=["System Health"])
async def liveness_probe():
    """
    Liveness probe for container orchestrators (Docker / Kubernetes / ECS).
    Returns HTTP 200 while process is responsive. Does not check external dependencies.
    """
    return {
        "status": "alive",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": "1.0.0"
    }

@app.get("/health/ready", tags=["System Health"])
async def readiness_probe(response: Response):
    """
    Readiness probe checking genuine critical dependencies (Supabase PostgreSQL).
    Returns HTTP 200 when ready to accept traffic; returns HTTP 503 when degraded.
    Bounded 2.0-second timeout; sanitized without leaking credentials or SQL details.
    """
    is_connected = await supabase_client.ping(timeout=2.0)
    now_iso = datetime.now(timezone.utc).isoformat()
    if is_connected:
        return {
            "status": "ready",
            "database": "connected",
            "timestamp": now_iso,
            "version": "1.0.0"
        }
    else:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {
            "status": "unready",
            "database": "disconnected",
            "detail": "Critical database dependency unreachable",
            "timestamp": now_iso,
            "version": "1.0.0"
        }

@app.get("/health", tags=["System Health"])
async def health_check():
    """
    Backwards-compatible health check endpoint.
    Sanitized to prevent internal URL/credential leakage.
    """
    is_connected = await supabase_client.ping(timeout=2.5)
    return {
        "status": "healthy" if is_connected else "degraded",
        "supabase_connected": is_connected,
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
