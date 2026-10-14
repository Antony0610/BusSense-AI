"""
BusSense AI - Public Transit Service Alerts & Operational Advisories
Directly queries persistent Supabase PostgreSQL `alerts` table.
Standardizes access under canonical `/api/alerts` path.
"""
from fastapi import APIRouter, HTTPException
from typing import List, Optional
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.incidents import AlertResponse
from app.core.supabase import supabase_client

router = APIRouter(prefix="/alerts", tags=["Service Alerts & Advisories"])

@router.get("", response_model=ApiResponse[List[AlertResponse]])
async def list_service_alerts(active_only: bool = True):
    """
    Returns public transit service alerts, detours, and crowding advisories.
    Persisted in Supabase PostgreSQL `alerts` table.
    """
    query_params = {"order": "created_at.desc", "limit": "20"}
    if active_only:
        query_params["is_active"] = "eq.true"

    rows = await supabase_client.get("alerts", query_params)
    
    results: List[AlertResponse] = []
    for a in rows:
        results.append(AlertResponse(
            id=str(a.get("id")),
            title=a.get("title", "Transit Advisory"),
            message=a.get("message", ""),
            severity=a.get("severity", "INFO"),
            affected_route="Route 205",
            is_active=a.get("is_active", True),
            created_at=str(a.get("created_at", ""))
        ))

    return ApiResponse(
        data=results,
        data_origin=DataOrigin.LIVE,
        message=f"Retrieved {len(results)} service alerts"
    )

@router.get("/active", response_model=ApiResponse[List[AlertResponse]])
async def list_active_service_alerts():
    """
    Alias returning active service alerts currently impacting commuters.
    """
    return await list_service_alerts(active_only=True)

@router.get("/{alert_id}", response_model=ApiResponse[AlertResponse])
async def get_service_alert_by_id(alert_id: str):
    """
    Returns a specific service alert by alert UUID.
    """
    rows = await supabase_client.get("alerts", {"id": f"eq.{alert_id}"})
    if not rows:
        raise HTTPException(status_code=404, detail=f"Alert '{alert_id}' not found")

    a = rows[0]
    return ApiResponse(
        data=AlertResponse(
            id=str(a.get("id")),
            title=a.get("title", "Transit Advisory"),
            message=a.get("message", ""),
            severity=a.get("severity", "INFO"),
            affected_route="Route 205",
            is_active=a.get("is_active", True),
            created_at=str(a.get("created_at", ""))
        ),
        data_origin=DataOrigin.LIVE,
        message=f"Alert {alert_id} retrieved"
    )
