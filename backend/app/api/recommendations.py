"""
BusSense AI - Smart Bus Recommendation & Journey Planning (Phase H10)
Provides multi-factor, explainable transit recommendations balancing:
ETA, live crowding, H9 demand predictions, journey duration, and fare.
"""
from fastapi import APIRouter, Query, HTTPException, status
from typing import Optional, Dict, Any, List
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.prediction import JourneyPlanResponse, JourneyPlanRequest
from app.services.recommendation_engine import recommendation_engine, PREFERENCE_WEIGHTS
from app.core.supabase import supabase_client

router = APIRouter(prefix="/recommendations", tags=["Smart Recommendations & AI Scoring"])

VALID_PREFERENCES = {"balanced", "fastest", "least_crowded", "lowest_fare"}

@router.get("/plan", response_model=ApiResponse[JourneyPlanResponse])
async def plan_journey_get(
    origin: str = Query("Kaloor Metro Station, Kochi", description="Boarding stop name or location"),
    destination: str = Query("Vyttila Mobility Hub", description="Destination stop name or location"),
    preference: str = Query("balanced", description="Optimization preference: balanced, fastest, least_crowded, lowest_fare")
):
    """
    Computes explainable, data-grounded journey recommendations.
    Balances live telemetry, H9 demand prediction, travel time, and fare without hardcoded winners.
    """
    pref = preference.lower().strip()
    if pref not in VALID_PREFERENCES:
        pref = "balanced"

    plan = recommendation_engine.plan_journey(
        origin=origin,
        destination=destination,
        preference=pref
    )

    # Asynchronously persist recommendation snapshot to Supabase bus_recommendations table
    try:
        import asyncio
        async def _persist_recommendation_snapshot():
            try:
                await supabase_client.post("bus_recommendations", {
                    "origin_stop_id": "00000000-0000-0000-0000-000000000001",
                    "destination_stop_id": "00000000-0000-0000-0000-000000000002",
                    "recommended_bus_id": "a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    "alternative_bus_id": "b2222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    "journey_score": plan.recommended_bus.journey_score,
                    "why_recommended": plan.recommended_bus.why_recommended[:250],
                    "crowd_saving_pct": plan.recommended_bus.crowd_saving_vs_alternative_pct or 0.0,
                    "time_saving_mins": plan.recommended_bus.time_saving_mins or 0,
                    "data_origin": "RECOMMENDATION"
                })
            except Exception as db_err:
                print(f"[Supabase Recommendation Warning] {db_err}")

        asyncio.create_task(_persist_recommendation_snapshot())
    except Exception as task_err:
        print(f"[Supabase Recommendation Task Warning] {task_err}")

    return ApiResponse(
        data=plan,
        data_origin=DataOrigin.RECOMMENDATION,
        message=f"Smart transit recommendation generated ({pref} mode)"
    )

@router.post("/plan", response_model=ApiResponse[JourneyPlanResponse])
async def plan_journey_post(request: JourneyPlanRequest):
    """
    POST route for structured journey planning requests.
    Supports origin/destination stop IDs and commuter preferences.
    """
    origin = request.origin or request.origin_stop_id or "Kaloor Metro Station, Kochi"
    destination = request.destination or request.destination_stop_id or "Vyttila Mobility Hub"
    
    # Map boolean preference flags if preference string not explicit
    pref = (request.preference or "balanced").lower().strip()
    if pref not in VALID_PREFERENCES:
        if request.prefer_low_crowd:
            pref = "least_crowded"
        else:
            pref = "balanced"

    plan = recommendation_engine.plan_journey(
        origin=origin,
        destination=destination,
        preference=pref
    )

    return ApiResponse(
        data=plan,
        data_origin=DataOrigin.RECOMMENDATION,
        message=f"Smart transit recommendation generated ({pref} mode)"
    )

@router.get("/preferences", response_model=ApiResponse[List[Dict[str, Any]]])
async def get_supported_preferences():
    """
    Returns supported commuter recommendation optimization modes and factor weights.
    """
    modes = [
        {
            "id": "balanced",
            "name": "Balanced Comfort & Time",
            "description": "Harmonious trade-off between arrival time, cabin crowding, duration, and fare.",
            "weights": PREFERENCE_WEIGHTS["balanced"]
        },
        {
            "id": "fastest",
            "name": "Fastest Arrival",
            "description": "Prioritizes immediate departure and minimal in-transit duration.",
            "weights": PREFERENCE_WEIGHTS["fastest"]
        },
        {
            "id": "least_crowded",
            "name": "Calmest Cabin",
            "description": "Prioritizes lowest current and predicted passenger crowding for seated comfort.",
            "weights": PREFERENCE_WEIGHTS["least_crowded"]
        },
        {
            "id": "lowest_fare",
            "name": "Budget Friendly",
            "description": "Prioritizes the most economical transit fare.",
            "weights": PREFERENCE_WEIGHTS["lowest_fare"]
        }
    ]
    return ApiResponse(
        data=modes,
        data_origin=DataOrigin.RECOMMENDATION,
        message="Supported recommendation preferences"
    )
