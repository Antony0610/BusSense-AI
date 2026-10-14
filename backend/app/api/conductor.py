"""
BusSense AI - Conductor / Driver Operational Endpoints
Handles operational duty check-in, bus pairing, active trip cockpit transitions, and trip completion.
Strictly enforced by RBAC: requires DRIVER_CONDUCTOR or AUTHORITY credentials.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.conductor import (
    ConductorShiftResponse,
    ConductorCheckInRequest,
    ConductorPairRequest,
    ConductorTripActionRequest,
    ConductorTripCompletionResponse
)
from app.core.security import require_roles, TokenPayload
from app.services.conductor_service import conductor_service

router = APIRouter(prefix="/conductor", tags=["Conductor / Driver Operations"])

@router.get("/shift", response_model=ApiResponse[ConductorShiftResponse])
async def get_conductor_shift(
    current_user: TokenPayload = Depends(require_roles(["DRIVER_CONDUCTOR", "AUTHORITY"]))
):
    """
    Returns current operational shift, duty ID, and paired bus for the authenticated conductor.
    Protected endpoint: rejects unauthenticated (401) and PASSENGER (403).
    """
    shift = await conductor_service.get_shift(
        user_id=current_user.sub,
        full_name=current_user.full_name
    )
    return ApiResponse(
        data=shift,
        data_origin=DataOrigin.SIMULATED,
        message="Conductor shift details retrieved"
    )

@router.post("/check-in", response_model=ApiResponse[ConductorShiftResponse])
async def conductor_check_in(
    req: ConductorCheckInRequest,
    current_user: TokenPayload = Depends(require_roles(["DRIVER_CONDUCTOR", "AUTHORITY"]))
):
    """
    Initiates or confirms duty shift check-in for the authenticated conductor.
    """
    shift = await conductor_service.check_in(
        user_id=current_user.sub,
        full_name=current_user.full_name,
        duty_id=req.duty_id
    )
    return ApiResponse(
        data=shift,
        data_origin=DataOrigin.SIMULATED,
        message=f"Conductor checked in for duty {shift.duty_id}"
    )

@router.post("/pair", response_model=ApiResponse[ConductorShiftResponse])
async def conductor_pair_bus(
    req: ConductorPairRequest,
    current_user: TokenPayload = Depends(require_roles(["DRIVER_CONDUCTOR", "AUTHORITY"]))
):
    """
    Pairs the authenticated conductor with a specific transit vehicle and corridor route.
    """
    shift = await conductor_service.pair_bus(
        user_id=current_user.sub,
        full_name=current_user.full_name,
        bus_number=req.bus_number,
        route_number=req.route_number,
        trip_code=req.trip_code
    )
    return ApiResponse(
        data=shift,
        data_origin=DataOrigin.SIMULATED,
        message=f"Paired successfully with Bus {req.bus_number} on Route {req.route_number}"
    )

@router.post("/trips/start", response_model=ApiResponse[ConductorShiftResponse])
async def conductor_start_trip(
    req: ConductorTripActionRequest,
    current_user: TokenPayload = Depends(require_roles(["DRIVER_CONDUCTOR", "AUTHORITY"]))
):
    """
    Transitions the paired corridor trip to status = ACTIVE.
    """
    shift = await conductor_service.start_trip(
        user_id=current_user.sub,
        full_name=current_user.full_name,
        trip_id=req.trip_id
    )
    return ApiResponse(
        data=shift,
        data_origin=DataOrigin.SIMULATED,
        message="Trip started and active in corridor dispatch"
    )

@router.post("/trips/complete", response_model=ApiResponse[ConductorTripCompletionResponse])
async def conductor_complete_trip(
    req: ConductorTripActionRequest,
    current_user: TokenPayload = Depends(require_roles(["DRIVER_CONDUCTOR", "AUTHORITY"]))
):
    """
    Marks the active trip as COMPLETED, records duration and occupancy, and initiates layover staging.
    """
    summary = await conductor_service.complete_trip(
        user_id=current_user.sub,
        full_name=current_user.full_name,
        trip_id=req.trip_id
    )
    return ApiResponse(
        data=summary,
        data_origin=DataOrigin.SIMULATED,
        message="Trip completed successfully. Turnaround layover initiated."
    )
