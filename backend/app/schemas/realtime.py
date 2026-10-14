"""
BusSense AI - Realtime Event Envelopes & Freshness Schemas
Phase H12: Typed schemas for WebSocket and Polling Realtime Architecture
"""
from typing import Dict, Any, Optional, List
from enum import Enum
from datetime import datetime, timezone
import uuid
from pydantic import BaseModel, Field
from app.schemas.common import DataOrigin


class RealtimeEventType(str, Enum):
    FLEET_TELEMETRY_UPDATE = "FLEET_TELEMETRY_UPDATE"
    BUS_LOCATION_UPDATE = "BUS_LOCATION_UPDATE"
    OCCUPANCY_UPDATE = "OCCUPANCY_UPDATE"
    PREDICTION_UPDATE = "PREDICTION_UPDATE"
    ALERT_UPDATE = "ALERT_UPDATE"
    INCIDENT_UPDATE = "INCIDENT_UPDATE"
    TRIP_STATUS_UPDATE = "TRIP_STATUS_UPDATE"
    USER_NOTIFICATION = "USER_NOTIFICATION"
    SYSTEM_HEARTBEAT = "SYSTEM_HEARTBEAT"


class RealtimeEvent(BaseModel):
    """
    Standard typed event envelope across WebSocket and polling fallbacks.
    Preserves UTC timestamps, entity identifiers, and transparent data origin labels.
    """
    event_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    event_type: str = Field(..., description="Category of transit update")
    entity_id: str = Field(..., description="Target entity ID (bus, route, incident, user, alert)")
    occurred_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    published_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    data_origin: str = Field(default=DataOrigin.SIMULATED.value, description="Transparent provenance label")
    schema_version: str = Field(default="1.0.0")
    payload: Dict[str, Any] = Field(default_factory=dict)


class RealtimeSubscriptionRequest(BaseModel):
    token: Optional[str] = None
    topics: List[str] = Field(default_factory=lambda: ["public"])
    bus_filter: Optional[str] = None


class FreshnessInfo(BaseModel):
    """Tracks age and staleness of transit telemetry."""
    last_updated_at: str
    data_age_seconds: float
    is_stale: bool
    freshness_label: str
    source_type: str


class RealtimeConnectionHealth(BaseModel):
    status: str = "HEALTHY"
    active_public_connections: int = 0
    active_authenticated_connections: int = 0
    events_published_total: int = 0
    in_memory_buffer_size: int = 0
    max_connection_limit: int = 100
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
