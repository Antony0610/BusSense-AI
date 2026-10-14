"""
BusSense AI - Bus Fleet & Real-time Telemetry Endpoints
"""
from fastapi import APIRouter, HTTPException
from typing import List
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.fleet import BusTelemetry
from app.services.gps_simulator import gps_simulator
from app.core.supabase import supabase_client

router = APIRouter(prefix="/buses", tags=["Buses & Fleet Telemetry"])

@router.get("", response_model=ApiResponse[List[BusTelemetry]])
async def list_all_active_buses():
    """
    Returns live telemetry for all buses in the active transit network.
    Includes GPS coordinates, occupancy %, crowd level, speed, and ETA.
    """
    buses = gps_simulator.get_all_buses()
    return ApiResponse(
        data=buses,
        data_origin=DataOrigin.SIMULATED,
        message="Active fleet telemetry retrieved"
    )

@router.get("/{bus_number}", response_model=ApiResponse[BusTelemetry])
async def get_bus_by_number(bus_number: str):
    """
    Returns live telemetry, occupancy, and next stop ETA for a specific bus (e.g. '205', '14A').
    """
    telemetry = gps_simulator.get_bus_telemetry(bus_number)
    if not telemetry:
        raise HTTPException(status_code=404, detail=f"Bus {bus_number} not found in active fleet")
    return ApiResponse(
        data=telemetry,
        data_origin=DataOrigin.SIMULATED,
        message=f"Telemetry for Bus {bus_number}"
    )
