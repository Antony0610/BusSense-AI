"""
BusSense AI - Standardized Fleet Crowd & Cabin Density Endpoints
Provides consistent cabin load levels, passenger counts, and capacity figures.
Enforces standard threshold classifications:
LOW: < 50%
MODERATE: 50% - 80%
CROWDED: > 80%
Privacy-First: Person counting bounding boxes only. Zero biometrics.
"""
from fastapi import APIRouter, HTTPException
from typing import List
from datetime import datetime, timezone
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.fleet import CrowdResponse
from app.services.gps_simulator import gps_simulator
from app.services.cv_occupancy import cv_occupancy_service

router = APIRouter(prefix="/crowd", tags=["Crowd & Cabin Occupancy"])

def _to_crowd_response(telemetry: dict) -> CrowdResponse:
    now_iso = datetime.now(timezone.utc).isoformat()
    return CrowdResponse(
        bus_id=telemetry["bus_id"],
        bus_number=telemetry["bus_number"],
        occupancy_pct=float(telemetry["occupancy_pct"]),
        passenger_count=int(telemetry["passenger_count"]),
        capacity=int(telemetry["capacity"]),
        crowd_level=telemetry["crowd_level"],
        detection_source=telemetry.get("detection_source", "Simulated_Camera_YOLOv8"),
        privacy_standard="PERSON_COUNTING_ONLY_NO_FACIAL_RECOGNITION",
        timestamp=now_iso,
        data_origin=telemetry.get("data_origin", DataOrigin.SIMULATED)
    )

@router.get("", response_model=ApiResponse[List[CrowdResponse]])
async def list_fleet_crowd_levels():
    """
    Returns standardized crowd level and passenger load metrics for all active buses.
    """
    buses = gps_simulator.get_all_buses()
    results = [_to_crowd_response(b) for b in buses]
    fleet_origin = DataOrigin.CV_REPLAY if any(b.get("data_origin") == DataOrigin.CV_REPLAY for b in buses) else DataOrigin.SIMULATED
    return ApiResponse(
        data=results,
        data_origin=fleet_origin,
        message="Active fleet crowd density retrieved"
    )

@router.get("/{bus_identifier}", response_model=ApiResponse[CrowdResponse])
async def get_bus_crowd_level(bus_identifier: str):
    """
    Returns crowd density metrics for a specific bus identified by bus number (e.g. '205') or bus UUID.
    """
    # 1. Search by bus_number
    telemetry = gps_simulator.get_bus_telemetry(bus_identifier)

    # 2. Search by bus_id
    if not telemetry:
        for b_num, state in gps_simulator.fleet_state.items():
            if state.get("bus_id") == bus_identifier:
                telemetry = gps_simulator.get_bus_telemetry(b_num)
                break

    if not telemetry:
        raise HTTPException(status_code=404, detail=f"Crowd telemetry for bus '{bus_identifier}' not found in active fleet")

    resp = _to_crowd_response(telemetry)
    return ApiResponse(
        data=resp,
        data_origin=resp.data_origin,
        message=f"Crowd level for Bus {telemetry['bus_number']}"
    )
