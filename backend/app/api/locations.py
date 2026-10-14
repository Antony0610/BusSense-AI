"""
BusSense AI - Real-time Vehicle Locations & GPS Telemetry Endpoints
Provides simulated corridor GPS coordinates, speed, heading, and stop progress.
"""
from fastapi import APIRouter, HTTPException
from typing import List
from datetime import datetime, timezone
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.fleet import LocationResponse
from app.services.gps_simulator import gps_simulator

router = APIRouter(prefix="/locations", tags=["Locations & GPS Telemetry"])

def _to_location_response(telemetry: dict) -> LocationResponse:
    now_iso = datetime.now(timezone.utc).isoformat()
    return LocationResponse(
        bus_id=telemetry["bus_id"],
        bus_number=telemetry["bus_number"],
        registration_number=telemetry.get("registration_number", "KL-07-CE-8821"),
        latitude=telemetry["latitude"],
        longitude=telemetry["longitude"],
        speed_kmh=telemetry["speed_kmh"],
        heading_deg=telemetry["heading_deg"],
        current_stop=telemetry["current_stop"],
        next_stop=telemetry["next_stop"],
        eta_next_stop_mins=telemetry["eta_next_stop_mins"],
        timestamp=now_iso,
        data_origin=DataOrigin.SIMULATED
    )

@router.get("", response_model=ApiResponse[List[LocationResponse]])
async def list_vehicle_locations():
    """
    Returns current live GPS coordinates for all active buses in the transit fleet.
    Coordinates are calculated by the corridor physics interpolator.
    Data is clearly marked as SIMULATED DATA.
    """
    buses = gps_simulator.get_all_buses()
    results = [_to_location_response(b) for b in buses]
    return ApiResponse(
        data=results,
        data_origin=DataOrigin.SIMULATED,
        message="Active fleet GPS locations retrieved"
    )

@router.get("/{bus_identifier}", response_model=ApiResponse[LocationResponse])
async def get_vehicle_location(bus_identifier: str):
    """
    Returns GPS location for a specific bus identified by bus number (e.g. '205', '14A') or bus UUID.
    """
    # 1. Search by bus_number in fleet_state
    telemetry = gps_simulator.get_bus_telemetry(bus_identifier)
    
    # 2. If not found by bus_number, search by bus_id
    if not telemetry:
        for b_num, state in gps_simulator.fleet_state.items():
            if state.get("bus_id") == bus_identifier:
                telemetry = gps_simulator.get_bus_telemetry(b_num)
                break

    if not telemetry:
        raise HTTPException(status_code=404, detail=f"Location for bus '{bus_identifier}' not found in active fleet")

    return ApiResponse(
        data=_to_location_response(telemetry),
        data_origin=DataOrigin.SIMULATED,
        message=f"Location retrieved for Bus {telemetry['bus_number']}"
    )
