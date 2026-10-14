"""
BusSense AI - Realtime Polling Fallbacks, Freshness & WebSocket Endpoints
Phase H12: Provides typed event streams, polling fallbacks, and connection diagnostics.
"""
from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect, status
from pydantic import BaseModel
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.realtime import (
    RealtimeEvent,
    FreshnessInfo,
    RealtimeConnectionHealth
)
from app.services.realtime_service import realtime_service
from app.core.security import get_current_user, TokenPayload

router = APIRouter(prefix="/realtime", tags=["Realtime Data & Freshness"])


class FreshnessRequest(BaseModel):
    timestamp: str
    data_origin: Optional[str] = "SIMULATED TELEMETRY"


@router.get("/events", response_model=ApiResponse[List[RealtimeEvent]])
async def get_recent_events(
    since: Optional[str] = Query(None, description="ISO timestamp cutoff for events"),
    event_type: Optional[str] = Query(None, description="Filter by event category"),
    limit: int = Query(50, ge=1, le=100)
):
    """
    HTTP polling fallback endpoint for clients when WebSocket connections are unavailable or degraded.
    Returns recent public events from the in-memory ring buffer.
    """
    events = realtime_service.get_recent_events(
        since_iso=since,
        event_type=event_type,
        limit=limit
    )
    return ApiResponse(
        data=events,
        data_origin=DataOrigin.SIMULATED,
        message=f"Retrieved {len(events)} realtime events from buffer"
    )


@router.get("/health", response_model=ApiResponse[RealtimeConnectionHealth])
async def get_realtime_health():
    """
    Returns connection capacity, subscriber counts, and event throughput metrics.
    """
    health = realtime_service.get_health()
    return ApiResponse(
        data=health,
        data_origin=DataOrigin.SIMULATED,
        message="Realtime service is operational"
    )


@router.post("/freshness", response_model=ApiResponse[FreshnessInfo])
async def check_data_freshness(req: FreshnessRequest):
    """
    Calculates data age and staleness against configured freshness thresholds.
    """
    info = realtime_service.calculate_data_freshness(
        timestamp_iso=req.timestamp,
        data_origin=req.data_origin or "SIMULATED TELEMETRY"
    )
    return ApiResponse(
        data=info,
        data_origin=DataOrigin.SIMULATED,
        message="Data freshness analyzed"
    )
