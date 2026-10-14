"""
BusSense AI - Routes & Corridor Management Endpoints
"""
from fastapi import APIRouter, HTTPException, Depends
from typing import List
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.fleet import RouteModel
from app.core.supabase import supabase_client
from app.core.security import require_roles, TokenPayload

router = APIRouter(prefix="/routes", tags=["Routes & Corridors"])

# Static fallback corridor definitions matching Kerala network
KERALA_ROUTES = [
    {
        "id": "00000000-0000-0000-0000-000000000101",
        "route_number": "205",
        "route_name": "Aluva Metro ➔ Vyttila Mobility Hub via Kaloor",
        "corridor_type": "Fast Passenger Corridor",
        "start_stop": "Aluva Metro Station",
        "end_stop": "Vyttila Mobility Hub",
        "distance_km": 22.4,
        "estimated_duration_mins": 48,
        "color_code": "#123C35"
    },
    {
        "id": "00000000-0000-0000-0000-000000000102",
        "route_number": "14A",
        "route_name": "Fort Kochi ➔ Infopark Phase 1 via Kaloor",
        "corridor_type": "City Metro Feeder",
        "start_stop": "Fort Kochi Boat Jetty",
        "end_stop": "Infopark Phase 1 Express Bay",
        "distance_km": 26.5,
        "estimated_duration_mins": 62,
        "color_code": "#006C49"
    },
    {
        "id": "00000000-0000-0000-0000-000000000103",
        "route_number": "12",
        "route_name": "Kaloor Metro ➔ Infopark Phase 1 Corridor",
        "corridor_type": "Direct Tech Corridor",
        "start_stop": "Kaloor Metro Station",
        "end_stop": "Infopark Phase 1 Express Bay",
        "distance_km": 14.8,
        "estimated_duration_mins": 32,
        "color_code": "#2563EB"
    }
]

@router.get("", response_model=ApiResponse[List[RouteModel]])
async def list_routes():
    """Returns all active transport routes in the transit network"""
    routes_db = await supabase_client.get("routes")
    if routes_db:
        return ApiResponse(data=routes_db, data_origin=DataOrigin.LIVE)
    return ApiResponse(data=KERALA_ROUTES, data_origin=DataOrigin.SIMULATED)

@router.get("/{route_number}", response_model=ApiResponse[RouteModel])
async def get_route(route_number: str):
    for r in KERALA_ROUTES:
        if r["route_number"] == route_number:
            return ApiResponse(data=r, data_origin=DataOrigin.SIMULATED)
    raise HTTPException(status_code=404, detail="Route not found")

@router.post("", response_model=ApiResponse[RouteModel])
async def create_route(
    route: RouteModel,
    current_user: TokenPayload = Depends(require_roles(["AUTHORITY"]))
):
    """
    Authority Route Management: Create a new transit route corridor.
    Strictly protected: requires AUTHORITY or ADMIN role.
    """
    KERALA_ROUTES.append(route.dict())
    return ApiResponse(
        data=route,
        data_origin=DataOrigin.LIVE,
        message="Route corridor created successfully"
    )
