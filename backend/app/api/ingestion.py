"""
BusSense AI - Transit Ingestion Endpoints (Phase H16/H17)
Provides secure, strictly-validated data boundary endpoints for:
- Vehicle GPS / AVL real-time feeds
- CCTV-derived aggregate passenger headcounts (zero-biometric)
- Route schedules, stops, and timetables
- Service disruptions and incident feeds
- Ingestion telemetry health and staleness monitoring
- External provider lifecycle: registration, API key authentication, and revocation
- Real-time corridor map-matching and route deviation alerting
- Controlled field pilot monitoring dashboard
"""
from fastapi import APIRouter, Depends, Header, HTTPException, status
from typing import Optional, Dict, Any, List
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.ingestion import (
    GpsTelemetryBatchRequest,
    CctvOccupancyIngestRecord,
    RouteScheduleIngestRequest,
    DisruptionIngestRecord,
    IngestSummaryResponse,
    ExternalProviderRegisterRequest,
    ExternalProviderResponse,
    ProviderRevocationRequest,
    MapMatchingResult,
    PilotMonitoringDashboardResponse
)
from app.services.ingestion_service import ingestion_service
from app.core.security import get_current_user, TokenPayload
from app.core.config import settings

router = APIRouter(prefix="/ingest", tags=["Transit Data Ingestion Boundary"])

async def verify_ingest_auth(
    authorization: Optional[str] = Header(None),
    x_internal_secret: Optional[str] = Header(None, alias="X-Internal-Secret"),
    x_provider_api_key: Optional[str] = Header(None, alias="X-Provider-API-Key"),
    x_api_key: Optional[str] = Header(None, alias="X-API-Key")
) -> dict:
    """
    Enforces authentication for transit data boundary ingestion.
    Permits:
    1. Internal services via X-Internal-Secret header.
    2. Authority / Admin users via Bearer JWT token.
    3. External transit providers via X-Provider-API-Key or X-API-Key header.
    Rejects revoked integrations with HTTP 403.
    Rejects unauthorized access with HTTP 401.
    """
    if x_internal_secret and x_internal_secret == settings.SECRET_KEY:
        return {"auth": "internal_secret", "role": "ADMIN"}

    # Check external provider API key
    prov_key = x_provider_api_key or x_api_key
    if prov_key:
        valid, err_msg, provider = ingestion_service.verify_provider_api_key(prov_key)
        if not valid:
            if err_msg and "INTEGRATION_REVOKED" in err_msg:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Access denied: {err_msg}"
                )
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid provider credentials: {err_msg or 'Invalid API key'}"
            )
        return {
            "auth": "provider_api_key",
            "provider_id": provider["provider_id"],
            "role": "EXTERNAL_PROVIDER",
            "allowed_feed_types": provider.get("allowed_feed_types", [])
        }

    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        user: TokenPayload = await get_current_user(token)
        if user.role not in ["AUTHORITY", "ADMIN"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Transit ingestion requires AUTHORITY or ADMIN role. Current: {user.role}"
            )
        return {"auth": "bearer", "role": user.role, "user_id": getattr(user, "sub", "")}

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Unauthorized transit data ingestion. Provide valid AUTHORITY/ADMIN Bearer token, X-Provider-API-Key, or X-Internal-Secret.",
        headers={"WWW-Authenticate": "Bearer"}
    )

async def require_authority_role(
    authorization: Optional[str] = Header(None),
    x_internal_secret: Optional[str] = Header(None, alias="X-Internal-Secret")
) -> dict:
    """Enforces that an administrative or authority action is executed only by an AUTHORITY or ADMIN"""
    if x_internal_secret and x_internal_secret == settings.SECRET_KEY:
        return {"auth": "internal_secret", "role": "ADMIN"}

    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        user: TokenPayload = await get_current_user(token)
        if user.role not in ["AUTHORITY", "ADMIN"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Administrative provider management requires AUTHORITY or ADMIN role"
            )
        return {"auth": "bearer", "role": user.role, "user_id": getattr(user, "sub", "")}

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Unauthorized. Provide valid AUTHORITY or ADMIN credentials."
    )

@router.post("/providers", response_model=ApiResponse[ExternalProviderResponse])
async def register_external_provider(
    req: ExternalProviderRegisterRequest,
    auth_context: dict = Depends(require_authority_role)
):
    """
    Registers an external transit data provider (e.g. KSRTC AVL feed, KMRL Feeder telematic gateway).
    Generates a cryptographically secure API key and returns it once upon registration.
    """
    resp, raw_key = ingestion_service.register_provider(req)
    return ApiResponse(
        data=resp,
        data_origin=DataOrigin.LIVE,
        message=f"External provider '{req.provider_id}' registered successfully. Store API key safely."
    )

@router.get("/providers", response_model=ApiResponse[List[ExternalProviderResponse]])
async def list_external_providers(
    auth_context: dict = Depends(require_authority_role)
):
    """Lists all registered transit providers with masked API keys and lifecycle status."""
    providers = ingestion_service.list_providers()
    return ApiResponse(
        data=providers,
        data_origin=DataOrigin.LIVE,
        message=f"Retrieved {len(providers)} registered transit data providers"
    )

@router.post("/providers/{provider_id}/revoke", response_model=ApiResponse[ExternalProviderResponse])
async def revoke_external_provider(
    provider_id: str,
    req: ProviderRevocationRequest,
    auth_context: dict = Depends(require_authority_role)
):
    """
    Revokes an external transit provider integration.
    Immediate 403 FORBIDDEN is enforced on all subsequent ingestion attempts.
    """
    revoked = ingestion_service.revoke_provider(provider_id, req.reason)
    if not revoked:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Provider '{provider_id}' not found"
        )
    return ApiResponse(
        data=revoked,
        data_origin=DataOrigin.LIVE,
        message=f"Provider '{provider_id}' has been revoked. Reason: {req.reason}"
    )

@router.post("/providers/{provider_id}/reactivate", response_model=ApiResponse[ExternalProviderResponse])
async def reactivate_external_provider(
    provider_id: str,
    auth_context: dict = Depends(require_authority_role)
):
    """Reactivates a previously revoked transit provider integration."""
    active = ingestion_service.reactivate_provider(provider_id)
    if not active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Provider '{provider_id}' not found"
        )
    return ApiResponse(
        data=active,
        data_origin=DataOrigin.LIVE,
        message=f"Provider '{provider_id}' reactivated"
    )

@router.get("/map-match/{bus_number}", response_model=ApiResponse[MapMatchingResult])
async def get_corridor_map_matching(
    bus_number: str,
    auth_context: dict = Depends(verify_ingest_auth)
):
    """
    Returns real-time map-matching against the vehicle's assigned corridor.
    Calculates distance to nearest stop and alerts if off-route (>500m).
    """
    result = ingestion_service.map_match_vehicle(bus_number)
    return ApiResponse(
        data=result,
        data_origin=DataOrigin.ESTIMATE,
        message=f"Map-matching for bus '{bus_number}': deviation {result.distance_to_corridor_meters}m (off_route={result.is_off_route})"
    )

@router.get("/pilot-monitor", response_model=ApiResponse[PilotMonitoringDashboardResponse])
async def get_pilot_monitoring_dashboard(
    auth_context: dict = Depends(verify_ingest_auth)
):
    """
    Returns comprehensive Phase H17 field pilot monitoring telemetry.
    Audits live vs simulated distribution, freshness ratios, occupancy tiers,
    ingestion rates, provider counts, and privacy standards.
    """
    summary = ingestion_service.get_pilot_monitoring_summary()
    return ApiResponse(
        data=summary,
        data_origin=DataOrigin.LIVE,
        message="Phase H17 field pilot monitoring telemetry"
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
    - Real-time corridor map-matching and off-route alerting (>500m)
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

