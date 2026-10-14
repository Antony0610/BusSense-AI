"""
BusSense AI - Authority Analytics & AI Decision Queue Endpoints
"""
from fastapi import APIRouter, Depends
from app.schemas.common import ApiResponse, DataOrigin
from app.core.security import require_roles, TokenPayload

router = APIRouter(prefix="/analytics", tags=["Authority Analytics & AI Operations"])

@router.get("/command-overview", response_model=ApiResponse[dict])
async def get_command_overview(current_user: TokenPayload = Depends(require_roles(["AUTHORITY"]))):
    """
    Core telemetry for Authority Command Center HUD.
    Strictly protected: requires AUTHORITY or ADMIN role.
    """
    return ApiResponse(
        data={
            "network_status": "OPTIMAL_FLOW",
            "active_buses_count": 5,
            "total_fleet_registered": 14,
            "average_network_occupancy_pct": 58.4,
            "on_time_reliability_pct": 94.2,
            "crowding_alerts_count": 1, # Bus 14A at capacity
            "service_incidents_count": 1,
            "co2_saved_today_kg": 420.5,
            "active_corridors": [
                {"name": "Aluva ➔ Vyttila Priority", "code": "R12_205", "status": "ON_SCHEDULE", "avg_speed": 34.5},
                {"name": "Fort Kochi ➔ Infopark", "code": "R12_14A", "status": "CROWDED_SLOW", "avg_speed": 22.0},
                {"name": "Kaloor ➔ Infopark Tech Line", "code": "R12_12", "status": "OPTIMAL", "avg_speed": 38.0}
            ]
        },
        data_origin=DataOrigin.SIMULATED,
        message="Authority command overview telemetry retrieved"
    )

@router.get("/ai-decision-queue", response_model=ApiResponse[list])
async def get_ai_decision_queue(current_user: TokenPayload = Depends(require_roles(["AUTHORITY"]))):
    """
    Human-in-the-loop AI operational decision recommendations.
    Strictly protected: requires AUTHORITY or ADMIN role.
    """
    return ApiResponse(
        data=[
            {
                "id": "dec-001",
                "trigger": "Predictive Peak Inflow + Showers at Kakkanad",
                "prediction": "Route 12 Infopark corridor predicted to reach 92% crowding between 17:30 - 18:30.",
                "recommendation": "Deploy standby feeder unit (KL-07-BW-1209) from Kaloor depot at 17:15.",
                "expected_impact": "-24% crowd reduction on primary corridor; 140 additional passenger capacity.",
                "status": "PENDING_OFFICER_CLEARANCE",
                "data_origin": "PREDICTION -> RECOMMENDATION -> HUMAN DECISION"
            }
        ],
        data_origin=DataOrigin.RECOMMENDATION
    )

from app.core.supabase import supabase_client

@router.get("/reports", response_model=ApiResponse[list])
async def get_operational_reports(current_user: TokenPayload = Depends(require_roles(["AUTHORITY"]))):
    """
    Regional transit operations archive and compliance reports.
    Reads directly from Supabase PostgreSQL table `reports`.
    Strictly protected: requires AUTHORITY or ADMIN role.
    """
    rows = await supabase_client.get("reports", {"order": "created_at.desc"})
    if not rows:
        # Seed initial operational report into Supabase
        seed_report = {
            "report_type": "WEEKLY_OPERATIONS",
            "title": "Weekly Greater Kochi Transit Operations Report (Week 38)",
            "period_start": "2026-09-18T00:00:00Z",
            "period_end": "2026-09-25T23:59:59Z",
            "summary_metrics": {
                "trips_total": 840,
                "on_time_pct": 94.2,
                "avg_occupancy_pct": 56.4,
                "carbon_offset_kg": 3420.0
            }
        }
        inserted = await supabase_client.post("reports", seed_report)
        rows = [inserted] if inserted else []

    formatted = []
    for r in rows:
        metrics = r.get("summary_metrics", {})
        formatted.append({
            "id": r["id"],
            "title": r["title"],
            "period": f"{r.get('period_start', '')[:10]} – {r.get('period_end', '')[:10]}",
            "trips_total": metrics.get("trips_total", 840),
            "on_time_pct": metrics.get("on_time_pct", 94.2),
            "avg_occupancy_pct": metrics.get("avg_occupancy_pct", 56.4),
            "carbon_offset_kg": metrics.get("carbon_offset_kg", 3420.0)
        })

    return ApiResponse(
        data=formatted,
        data_origin=DataOrigin.SIMULATED,
        message="Operational reports retrieved from database"
    )

