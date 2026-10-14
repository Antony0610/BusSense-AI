"""
BusSense AI - Centralized Realtime Event Bus & Connection Manager
Phase H12: Manages WebSockets, role-based topic filtering, event envelopes, and polling fallback buffers.
"""
import asyncio
from collections import deque
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional, Set
import uuid
from fastapi import WebSocket, WebSocketDisconnect
from app.schemas.realtime import (
    RealtimeEvent,
    RealtimeEventType,
    FreshnessInfo,
    RealtimeConnectionHealth
)
from app.schemas.common import DataOrigin


class AuthenticatedClient:
    def __init__(
        self,
        conn_id: str,
        websocket: WebSocket,
        user_id: str,
        role: str,
        topics: Set[str],
        bus_filter: Optional[str] = None
    ):
        self.conn_id = conn_id
        self.websocket = websocket
        self.user_id = user_id
        self.role = role
        self.topics = topics
        self.bus_filter = bus_filter
        self.connected_at = datetime.now(timezone.utc)


class RealtimeService:
    MAX_CONNECTIONS = 100
    BUFFER_CAPACITY = 100

    # Freshness thresholds in seconds
    FRESHNESS_THRESHOLDS = {
        "LIVE SENSOR TELEMETRY": 15.0,
        "SIMULATED TELEMETRY": 15.0,
        "CV REPLAY": 20.0,
        "MACHINE LEARNING PREDICTION": 120.0,
        "RECOMMENDATION": 180.0,
        "HUMAN-REPORTED INCIDENT": 300.0,
        "DEFAULT": 30.0
    }

    def __init__(self):
        self.public_connections: Set[WebSocket] = set()
        self.authenticated_clients: Dict[str, AuthenticatedClient] = {}
        self.event_buffer: deque[RealtimeEvent] = deque(maxlen=self.BUFFER_CAPACITY)
        self.events_published_count: int = 0
        self._lock = asyncio.Lock()

    @property
    def total_active_connections(self) -> int:
        return len(self.public_connections) + len(self.authenticated_clients)

    async def connect_public(self, websocket: Optional[WebSocket]) -> bool:
        """Connects an anonymous subscriber to public transit telemetry events."""
        if self.total_active_connections >= self.MAX_CONNECTIONS:
            if websocket is not None:
                await websocket.close(code=1013, reason="Maximum connection capacity reached")
            return False

        if websocket is not None:
            await websocket.accept()
            self.public_connections.add(websocket)
        return True

    def disconnect_public(self, websocket: WebSocket):
        """Removes a disconnected public client."""
        self.public_connections.discard(websocket)

    async def connect_authenticated(
        self,
        websocket: Optional[WebSocket],
        user_id: str,
        role: str,
        topics: Optional[Set[str]] = None,
        bus_filter: Optional[str] = None
    ) -> Optional[str]:
        """
        Connects an authenticated user to role-authorized streams.
        Enforces user ownership isolation: passengers receive personal notifications,
        conductors receive crew dispatches, authorities receive operational queues.
        """
        if self.total_active_connections >= self.MAX_CONNECTIONS:
            if websocket is not None:
                await websocket.close(code=1013, reason="Maximum connection capacity reached")
            return None

        if websocket is not None:
            await websocket.accept()
        conn_id = f"conn_{uuid.uuid4().hex[:12]}"
        client = AuthenticatedClient(
            conn_id=conn_id,
            websocket=websocket,
            user_id=user_id,
            role=role,
            topics=topics or {"public", "user"},
            bus_filter=bus_filter
        )
        self.authenticated_clients[conn_id] = client
        return conn_id

    def disconnect_authenticated(self, conn_id: str):
        """Removes an authenticated client connection."""
        if conn_id in self.authenticated_clients:
            del self.authenticated_clients[conn_id]

    async def publish_event(self, event: RealtimeEvent):
        """
        Publishes a typed RealtimeEvent across eligible subscribers and appends to fallback buffer.
        Guarantees:
        - In-memory ring buffer retains event for polling fallbacks.
        - Public events broadcast to public subscribers.
        - Personal notifications delivered ONLY to the target user_id.
        - Dead connections are pruned cleanly without failing other sends.
        """
        self.event_buffer.append(event)
        self.events_published_count += 1
        event_dict = event.model_dump()

        # 1. Broadcast public transit events to public subscribers
        is_private = (event.event_type == RealtimeEventType.USER_NOTIFICATION.value)
        if not is_private:
            stale_public = []
            for ws in list(self.public_connections):
                try:
                    await ws.send_json(event_dict)
                except Exception:
                    stale_public.append(ws)
            for ws in stale_public:
                self.disconnect_public(ws)

        # 2. Broadcast to authenticated subscribers based on RBAC and target user
        stale_auth = []
        for conn_id, client in list(self.authenticated_clients.items()):
            try:
                # Private user notifications: STRICT USER ISOLATION
                if is_private:
                    if client.user_id == event.entity_id:
                        await client.websocket.send_json(event_dict)
                    continue

                # Role-based topic filters
                if event.event_type in [RealtimeEventType.INCIDENT_UPDATE.value, RealtimeEventType.TRIP_STATUS_UPDATE.value]:
                    if client.role in ["DRIVER_CONDUCTOR", "AUTHORITY", "ADMIN"]:
                        await client.websocket.send_json(event_dict)
                    elif "public" in client.topics:
                        await client.websocket.send_json(event_dict)
                    continue

                # Bus-filter matching
                if client.bus_filter and event.entity_id != client.bus_filter and event.event_type == RealtimeEventType.BUS_LOCATION_UPDATE.value:
                    continue

                # Standard broadcast to authenticated clients
                await client.websocket.send_json(event_dict)
            except Exception:
                stale_auth.append(conn_id)

        for conn_id in stale_auth:
            self.disconnect_authenticated(conn_id)

    def get_recent_events(
        self,
        since_iso: Optional[str] = None,
        event_type: Optional[str] = None,
        limit: int = 50
    ) -> List[RealtimeEvent]:
        """
        Retrieves recent events from buffer for HTTP polling clients or reconnection catch-up.
        Excludes private USER_NOTIFICATION events to preserve privacy in public polling.
        """
        events: List[RealtimeEvent] = []
        for e in self.event_buffer:
            # Exclude private user notifications from public polling
            if e.event_type == RealtimeEventType.USER_NOTIFICATION.value:
                continue

            if event_type and e.event_type != event_type:
                continue

            if since_iso:
                try:
                    if e.occurred_at <= since_iso:
                        continue
                except Exception:
                    pass

            events.append(e)

        # Return latest up to limit
        return events[-limit:]

    def calculate_data_freshness(self, timestamp_iso: str, data_origin: str) -> FreshnessInfo:
        """
        Calculates age and staleness against configured freshness thresholds.
        Labels stale data honestly rather than masquerading stale readings as current.
        """
        now = datetime.now(timezone.utc)
        try:
            # Parse ISO string
            cleaned = timestamp_iso.replace("Z", "+00:00")
            dt = datetime.fromisoformat(cleaned)
            age = max(0.0, (now - dt).total_seconds())
        except Exception:
            age = 999.0

        threshold = self.FRESHNESS_THRESHOLDS.get(data_origin, self.FRESHNESS_THRESHOLDS["DEFAULT"])
        is_stale = age > threshold

        if is_stale:
            label = f"STALE • Age: {age:.0f}s (Threshold: {threshold:.0f}s)"
        else:
            label = f"FRESH • {age:.1f}s ago"

        return FreshnessInfo(
            last_updated_at=timestamp_iso,
            data_age_seconds=round(age, 1),
            is_stale=is_stale,
            freshness_label=label,
            source_type=data_origin
        )

    def get_health(self) -> RealtimeConnectionHealth:
        return RealtimeConnectionHealth(
            status="HEALTHY",
            active_public_connections=len(self.public_connections),
            active_authenticated_connections=len(self.authenticated_clients),
            events_published_total=self.events_published_count,
            in_memory_buffer_size=len(self.event_buffer),
            max_connection_limit=self.MAX_CONNECTIONS
        )


realtime_service = RealtimeService()
