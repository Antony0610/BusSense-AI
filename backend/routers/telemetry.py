"""Telemetry and live vehicle location endpoints."""
from __future__ import annotations

from typing import Optional
from fastapi import APIRouter, Header, HTTPException, Query, status

from backend.config import settings
from backend.database import get_all_buses, update_bus_telemetry
from backend.schemas import BusResponse, TelemetryIngestRequest, TelemetryResponse
from backend.services.gps_telemetry_sim import step_simulation

router = APIRouter(prefix="/api", tags=["Live Telemetry & Fleet"])


@router.get("/buses", response_model=list[BusResponse])
async def list_buses(
    operator: Optional[str] = Query(None, description="Filter by KSRTC or PRIVATE"),
    route: Optional[str] = Query(None, description="Filter by Route Number (e.g. R1)"),
):
    """Retrieve all active buses with real-time PostGIS coordinates and occupancy metrics."""
    return get_all_buses(operator=operator, route=route)


@router.post("/telemetry/ingest", response_model=TelemetryResponse, status_code=status.HTTP_201_CREATED)
async def ingest_telemetry(
    payload: TelemetryIngestRequest,
    x_edge_api_key: Optional[str] = Header(None, alias="X-Edge-API-Key"),
):
    """Secure ingestion endpoint for Edge YOLOv8 person detectors and bus telematics units."""
    if x_edge_api_key and x_edge_api_key != settings.EDGE_API_KEY:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Invalid Edge API Key")

    record = update_bus_telemetry(
        bus_id=payload.bus_id,
        route_number=payload.route_number,
        latitude=payload.latitude,
        longitude=payload.longitude,
        passenger_count=payload.passenger_count,
        capacity=payload.capacity,
        speed_kmh=payload.speed_kmh,
        heading_deg=payload.heading_deg,
        source=payload.source,
    )
    return {
        "status": "ingested",
        "bus_id": record["bus_id"],
        "passenger_count": record["passenger_count"],
        "occupancy_percentage": record["occupancy_percentage"],
        "seat_availability": record["seat_availability"],
        "crowd_tier": record["crowd_tier"],
        "timestamp": record["timestamp"],
    }


@router.post("/telemetry/step-sim")
async def trigger_simulation_step():
    """Manually advance the physics-based GPS movement simulation for all Kerala routes."""
    updates = step_simulation()
    return {"status": "simulated", "vehicles_updated": len(updates)}
