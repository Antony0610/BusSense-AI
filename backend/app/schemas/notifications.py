"""
BusSense AI - Commuter & Crew Notification Schemas
Phase H12: In-app notification domain with deduplication and provenance metadata
"""
from typing import Optional
from datetime import datetime, timezone
import uuid
from pydantic import BaseModel, Field
from app.schemas.common import DataOrigin


class NotificationResponse(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    user_id: str
    title: str
    body: str
    notification_type: str = "BUS_ARRIVAL"
    is_read: bool = False
    created_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    dedup_key: Optional[str] = None
    severity: str = "INFO"
    data_origin: str = DataOrigin.SIMULATED.value


class NotificationCreateRequest(BaseModel):
    user_id: str
    title: str
    body: str
    notification_type: str = "TRANSIT_ALERT"
    dedup_key: Optional[str] = None
    severity: str = "INFO"


class UnreadCountResponse(BaseModel):
    user_id: str
    unread_count: int


class MarkAllReadResponse(BaseModel):
    user_id: str
    marked_count: int
    success: bool = True
