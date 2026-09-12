"""Predictive demand and sustainability analytics endpoints."""
from __future__ import annotations

from fastapi import APIRouter, Query, status

from backend.database import get_all_buses, record_passenger_report
from backend.schemas import (
    DemandForecastResponse,
    PassengerReportRequest,
    PassengerReportResponse,
)
from backend.services.demand_ml import ml_engine

router = APIRouter(prefix="/api", tags=["Predictive Analytics & Reports"])


@router.get("/demand/forecast", response_model=DemandForecastResponse)
async def get_demand_forecast(
    route_number: str = Query("R1", description="Route number to forecast (e.g. R1, R2, R3, R4)"),
):
    """Predict 24-hour ahead passenger demand curve using pre-trained Random Forest (<15ms latency)."""
    return ml_engine.predict_route(route_number=route_number)


@router.get("/stats")
async def get_executive_stats():
    """Calculate fleet-wide KPIs, fuel savings, and environmental emissions reduction."""
    buses = get_all_buses()
    total_buses = len(buses)
    avg_occ = round(sum(b["occupancy_percentage"] for b in buses) / max(total_buses, 1), 1)

    overcrowded = [b for b in buses if b["occupancy_percentage"] >= 80.0]
    underused = [b for b in buses if b["occupancy_percentage"] <= 35.0]

    # Sustainability calculations: 1.8 L saved per underused service shifted, 0.9 L per balanced service
    fuel_saved_litres = round((len(underused) * 1.8) + (len(buses) * 0.45), 1)
    co2_saved_kg = round(fuel_saved_litres * 2.68, 1)

    # Bus Utilization Score (0-100 index where 85% occupancy is considered 100% optimal utilization)
    util_score = round(min(100.0, (avg_occ / 85.0) * 100.0), 1)

    return {
        "total_active_buses": total_buses,
        "average_fleet_occupancy": avg_occ,
        "bus_utilization_score": util_score,
        "overcrowding_alerts_count": len(overcrowded),
        "underutilized_count": len(underused),
        "fuel_saved_litres": fuel_saved_litres,
        "co2_saved_kg": co2_saved_kg,
        "overcrowded_buses": [b["bus_id"] for b in overcrowded],
    }


@router.post("/report", response_model=PassengerReportResponse, status_code=status.HTTP_201_CREATED)
async def submit_report(payload: PassengerReportRequest):
    """Commuter reporting endpoint for overcrowding or service disruptions."""
    result = record_passenger_report(
        message=payload.message,
        report_type=payload.report_type,
        user_id=payload.user_id,
        bus_id=payload.bus_id,
        latitude=payload.latitude,
        longitude=payload.longitude,
    )
    return {
        "id": result["id"],
        "status": "received",
        "message": "Report submitted successfully.",
        "created_at": result["created_at"],
    }
