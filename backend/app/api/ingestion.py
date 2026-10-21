"""
BusSense AI - Transit Ingestion Endpoints (Phase H16)
Provides secure, strictly-validated data boundary endpoints for:
- Vehicle GPS / AVL real-time feeds
- CCTV-derived aggregate passenger headcounts (zero-biometric)
- Route schedules, stops, and timetables
- Service disruptions and incident feeds
- Ingestion telemetry health and staleness monitoring
"""
from fastapi import APIRouter, Depends, Header, HTTPException, status
from typing import Optional, Dict, Any
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.ingestion import (
    GpsTelemetryBatchRequest,
    CctvOccupancyIngestRecord,
    RouteScheduleIngestRequest,
    DisruptionIngestRecord,
    IngestSummaryResponse
)
from app.services.ingestion_service import ingestion_service
from app.core.security import get_current_user, TokenPayload
from app.core.config import settings

router = APIRouter(prefix="/ingest", tags=["Transit Data Ingestion Boundary"])

async def verify_ingest_auth(
    authorization: Optional[str] = Header(None),
    x_internal_secret: Optional[str] = Header(None)
) -> dict:
    """
    Enforces authentication for transit data boundary ingestion.
    Permits AUTHORITY or ADMIN JWT Bearer token, or valid X-Internal-Secret header.
    Rejects unauthorized access with HTTP 401.
    Rejects insufficient roles with HTTP 403.
    """
    if x_internal_secret and x_internal_secret == settings.SECRET_KEY:
        return {"auth": "internal_secret", "role": "ADMIN"}

    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        user: TokenPayload = await get_current_user(token)
        if user.role not in ["AUTHORITY", "ADMIN"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Transit ingestion requires AUTHORITY or ADMIN role. Current: {user.role}"
            )
        return {"auth": "bearer", "role": user.role}

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Unauthorized transit data ingestion. Provide valid AUTHORITY/ADMIN Bearer token or X-Internal-Secret header.",
        headers={"WWW-Authenticate": "Bearer"}
    )

@router.post("/gps", response_model=ApiResponse[IngestSummaryResponse])
async def ingest_gps_telemetry(
    batch: GpsTelemetryBatchRequest,
    auth_context: dict = Depends(verify_ingest_auth)
):
    """
    Ingests a batch of AVL / GPS vehicle location records.
    Validates:
    - Bounding box: Greater Kochi operational corridor [9.80-10.35 N, 76.15-76.55 E]
    - Speed sanity: 0.0 to 120.0 km/h
    - Heading sanity: 0.0 to 359.9 deg
    - Timestamp sanity: rejects future (>5m) and stale (>15m if not historical)
    - Monotonic sequencing and duplicate detection per bus
    """
    summary = ingestion_service.ingest_gps_batch(batch)
    return ApiResponse(
        data=summary,
        data_origin=summary.data_origin,
        message=f"GPS telemetry batch processed: {summary.accepted} accepted, {summary.rejected} rejected"
    )

@router.post("/cctv-occupancy", response_model=ApiResponse[IngestSummaryResponse])
async def ingest_cctv_occupancy(
    record: CctvOccupancyIngestRecord,
    auth_context: dict = Depends(verify_ingest_auth)
):
    """
    Ingests aggregate passenger headcounts derived from CCTV cameras.
    Enforces zero-biometric policy (person counting only).
    Recalculates trusted occupancy percentage and crowd tier.
    """
    summary = await ingestion_service.ingest_cctv_occupancy(record)
    return ApiResponse(
        data=summary,
        data_origin=summary.data_origin,
        message=f"CCTV aggregate occupancy processed for Bus {record.bus_number}"
    )

@router.post("/routes-schedule", response_model=ApiResponse[IngestSummaryResponse])
async def ingest_route_schedule(
    schedule: RouteScheduleIngestRequest,
    auth_context: dict = Depends(verify_ingest_auth)
):
    """
    Ingests route definition and ordered stop sequences with timetable timings.
    Validates monotonic stop sequence and Greater Kochi coordinates.
    """
    summary = ingestion_service.ingest_route_schedule(schedule)
    return ApiResponse(
        data=summary,
        data_origin=summary.data_origin,
        message=f"Route schedule processed for {schedule.route_number}: {summary.accepted} stops accepted"
    )

@router.post("/disruptions", response_model=ApiResponse[IngestSummaryResponse])
async def ingest_disruption(
    disruption: DisruptionIngestRecord,
    auth_context: dict = Depends(verify_ingest_auth)
):
    """
    Ingests service disruption, road blockage, or incident records.
    Broadcasts realtime notification and persists to incident ledger.
    """
    summary = await ingestion_service.ingest_disruption(disruption)
    return ApiResponse(
        data=summary,
        data_origin=summary.data_origin,
        message=f"Service disruption recorded for Route {disruption.route_number}"
    )

@router.get("/health", response_model=ApiResponse[Dict[str, Any]])
async def get_ingestion_health(
    auth_context: dict = Depends(verify_ingest_auth)
):
    """
    Returns real-time health metrics of the transit ingestion boundary:
    tracked vehicle count, stale telemetry warnings, dropped packets, and Greater Kochi bbox.
    """
    health = ingestion_service.get_ingest_health()
    return ApiResponse(
        data=health,
        data_origin=DataOrigin.LIVE,
        message="Transit ingestion boundary health status"
    )
