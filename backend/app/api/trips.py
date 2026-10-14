"""
BusSense AI - Active Trips & Scheduled Service Endpoints
Provides structured trip lifecycle telemetry backed by Supabase PostgreSQL and live corridor simulation.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from datetime import datetime, timezone
from app.schemas.common import ApiResponse, DataOrigin, CrowdLevel
from app.schemas.fleet import TripResponse
from app.core.security import get_current_user, TokenPayload
from app.core.supabase import supabase_client
from app.services.gps_simulator import gps_simulator

router = APIRouter(prefix="/trips", tags=["Trips & Corridors"])

async def _build_trip_response(trip_row: dict, telemetry: dict) -> TripResponse:
    bus_number = telemetry.get("bus_number", "205")
    route_number = telemetry.get("route_number", "12")
    return TripResponse(
        trip_id=str(trip_row.get("id")),
        trip_code=trip_row.get("trip_code", f"TRIP-{bus_number}"),
        bus_id=str(trip_row.get("bus_id")),
        bus_number=bus_number,
        route_id=str(trip_row.get("route_id")),
        route_number=route_number,
        current_status=trip_row.get("status", "IN_TRANSIT"),
        current_stop=telemetry.get("current_stop", "Palarivattom Jn"),
        next_stop=telemetry.get("next_stop", "Kaloor Central Stand"),
        started_at=trip_row.get("scheduled_departure", datetime.now(timezone.utc).isoformat()),
        estimated_arrival=trip_row.get("scheduled_arrival", datetime.now(timezone.utc).isoformat()),
        occupancy_pct=float(telemetry.get("occupancy_pct", 41.8)),
        crowd_level=telemetry.get("crowd_level", CrowdLevel.LOW),
        data_origin=DataOrigin.SIMULATED
    )

@router.get("", response_model=ApiResponse[List[TripResponse]])
async def list_active_trips(current_user: TokenPayload = Depends(get_current_user)):
    """
    Returns active corridor trips in the transit network.
    Combines persistent Supabase trip records with live GPS simulation telemetry.
    Protected endpoint: requires authenticated token (PASSENGER, DRIVER_CONDUCTOR, or AUTHORITY).
    """
    # 1. Query persistent trips from Supabase
    db_trips = await supabase_client.get("trips", {"order": "scheduled_departure.asc", "limit": "20"})
    
    fleet_telemetry = {t["bus_id"]: t for t in gps_simulator.get_all_buses()}
    # Also index by bus_number in case IDs differ
    bus_num_map = {"205": "a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa", "14A": "b2222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "12": "e5555555-eeee-eeee-eeee-eeeeeeeeeeee"}
    reverse_bus_map = {v: k for k, v in bus_num_map.items()}

    results: List[TripResponse] = []
    
    if db_trips:
        for row in db_trips:
            b_id = str(row.get("bus_id"))
            telemetry = fleet_telemetry.get(b_id)
            if not telemetry:
                b_num = reverse_bus_map.get(b_id, "205")
                telemetry = gps_simulator.get_bus_telemetry(b_num)
            trip_resp = await _build_trip_response(row, telemetry)
            results.append(trip_resp)
    else:
        # Fallback to simulation fleet if table has no active rows
        for b_num, bus_state in gps_simulator.fleet_state.items():
            telemetry = gps_simulator.get_bus_telemetry(b_num)
            results.append(TripResponse(
                trip_id=f"trip-sim-{b_num}",
                trip_code=f"TRIP-{b_num}-ACTIVE",
                bus_id=bus_state["bus_id"],
                bus_number=b_num,
                route_id="00000000-0000-0000-0000-000000000101",
                route_number=telemetry.get("route_number", "12"),
                current_status="IN_TRANSIT",
                current_stop=telemetry.get("current_stop", "Palarivattom Jn"),
                next_stop=telemetry.get("next_stop", "Kaloor Central Stand"),
                started_at=datetime.now(timezone.utc).isoformat(),
                estimated_arrival=datetime.now(timezone.utc).isoformat(),
                occupancy_pct=float(telemetry.get("occupancy_pct", 41.8)),
                crowd_level=telemetry.get("crowd_level", CrowdLevel.LOW),
                data_origin=DataOrigin.SIMULATED
            ))

    return ApiResponse(
        data=results,
        data_origin=DataOrigin.SIMULATED,
        message=f"Retrieved {len(results)} active corridor trips"
    )

@router.get("/{trip_id}", response_model=ApiResponse[TripResponse])
async def get_trip_by_id(trip_id: str, current_user: TokenPayload = Depends(get_current_user)):
    """
    Returns specific active trip details by Trip UUID or trip code.
    Protected endpoint: requires authenticated token.
    """
    # 1. Search Supabase by id or trip_code
    rows = await supabase_client.get("trips", {"id": f"eq.{trip_id}"})
    if not rows:
        rows = await supabase_client.get("trips", {"trip_code": f"eq.{trip_id}"})

    if rows:
        trip_row = rows[0]
        b_id = str(trip_row.get("bus_id"))
        telemetry = gps_simulator.fleet_state.get(b_id)
        if not telemetry:
            # Map by known bus IDs
            for b_num, state in gps_simulator.fleet_state.items():
                if state["bus_id"] == b_id:
                    telemetry = gps_simulator.get_bus_telemetry(b_num)
                    break
        if not telemetry:
            telemetry = gps_simulator.get_bus_telemetry("205")
        
        trip_resp = await _build_trip_response(trip_row, telemetry)
        return ApiResponse(
            data=trip_resp,
            data_origin=DataOrigin.SIMULATED,
            message=f"Trip {trip_id} details retrieved"
        )

    # 2. Check simulation fallback by bus number or sim id
    for b_num, bus_state in gps_simulator.fleet_state.items():
        if trip_id in (f"trip-sim-{b_num}", f"TRIP-{b_num}", b_num):
            telemetry = gps_simulator.get_bus_telemetry(b_num)
            trip_resp = TripResponse(
                trip_id=f"trip-sim-{b_num}",
                trip_code=f"TRIP-{b_num}-ACTIVE",
                bus_id=bus_state["bus_id"],
                bus_number=b_num,
                route_id="00000000-0000-0000-0000-000000000101",
                route_number=telemetry.get("route_number", "12"),
                current_status="IN_TRANSIT",
                current_stop=telemetry.get("current_stop", "Palarivattom Jn"),
                next_stop=telemetry.get("next_stop", "Kaloor Central Stand"),
                started_at=datetime.now(timezone.utc).isoformat(),
                estimated_arrival=datetime.now(timezone.utc).isoformat(),
                occupancy_pct=float(telemetry.get("occupancy_pct", 41.8)),
                crowd_level=telemetry.get("crowd_level", CrowdLevel.LOW),
                data_origin=DataOrigin.SIMULATED
            )
            return ApiResponse(
                data=trip_resp,
                data_origin=DataOrigin.SIMULATED,
                message=f"Trip {trip_id} details retrieved"
            )

    raise HTTPException(status_code=404, detail=f"Trip '{trip_id}' not found")
