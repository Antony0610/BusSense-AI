"""
BusSense AI - Standardized Demand & Crowd Predictions Endpoints
Provides 4-horizon predictive crowd estimates: NOW, +15 MIN, +30 MIN, +60 MIN.
Reuses the central demand forecaster engine without duplicating business logic.
Data is strictly stamped as PREDICTION.
"""
from fastapi import APIRouter, HTTPException
from typing import List
from app.schemas.common import ApiResponse, DataOrigin, CrowdLevel
from app.schemas.prediction import (
    CrowdForecastPoint,
    PredictionHorizonDetail,
    PredictionHorizonMap,
    RoutePredictionSummary,
    DetailedBusForecastResponse,
)
from app.services.demand_forecaster import demand_forecaster
from app.services.gps_simulator import gps_simulator
from app.core.supabase import supabase_client

router = APIRouter(prefix="/predictions", tags=["Demand Predictions & Forecasting"])

CORRIDOR_METADATA = {
    "205": {"route_number": "12", "corridor_name": "Aluva Metro ➔ Vyttila Mobility Hub via Kaloor"},
    "14A": {"route_number": "14A", "corridor_name": "Fort Kochi ➔ Infopark Phase 1 via Kaloor"},
    "12": {"route_number": "12", "corridor_name": "Kaloor ➔ Infopark Express"}
}

def _build_horizon_map(points: List[CrowdForecastPoint]) -> PredictionHorizonMap:
    lookup = {p.time_offset: p for p in points}
    p_now = lookup.get("NOW", points[0])
    p_15 = lookup.get("+15 MIN", points[1] if len(points) > 1 else points[0])
    p_30 = lookup.get("+30 MIN", points[2] if len(points) > 2 else points[0])
    p_60 = lookup.get("+60 MIN", points[3] if len(points) > 3 else points[0])
    
    return PredictionHorizonMap(
        now=PredictionHorizonDetail(
            occupancy_pct=p_now.predicted_occupancy_pct,
            crowd_level=p_now.crowd_level,
            confidence=p_now.confidence
        ),
        plus_15m=PredictionHorizonDetail(
            occupancy_pct=p_15.predicted_occupancy_pct,
            crowd_level=p_15.crowd_level,
            confidence=p_15.confidence
        ),
        plus_30m=PredictionHorizonDetail(
            occupancy_pct=p_30.predicted_occupancy_pct,
            crowd_level=p_30.crowd_level,
            confidence=p_30.confidence
        ),
        plus_60m=PredictionHorizonDetail(
            occupancy_pct=p_60.predicted_occupancy_pct,
            crowd_level=p_60.crowd_level,
            confidence=p_60.confidence
        )
    )

@router.get("", response_model=ApiResponse[List[RoutePredictionSummary]])
async def list_fleet_predictions():
    """
    Returns crowd prediction horizon trajectories across all monitored transit corridors.
    Reuses the central demand forecaster engine.
    """
    results: List[RoutePredictionSummary] = []
    for bus_num, meta in CORRIDOR_METADATA.items():
        forecast_points = demand_forecaster.forecast_corridor_crowd(route_number=bus_num)
        horizon_map = _build_horizon_map(forecast_points)
        results.append(
            RoutePredictionSummary(
                bus_number=bus_num,
                route_number=meta["route_number"],
                corridor_name=meta["corridor_name"],
                horizon=horizon_map,
                data_origin=DataOrigin.PREDICTION
            )
        )

    return ApiResponse(
        data=results,
        data_origin=DataOrigin.PREDICTION,
        message="Fleet corridor crowd predictions retrieved"
    )

@router.get("/{bus_identifier}", response_model=ApiResponse[List[CrowdForecastPoint]])
async def get_bus_predictions(bus_identifier: str):
    """
    Returns 4-point crowd predictions (NOW, +15 MIN, +30 MIN, +60 MIN) for a specific bus.
    Accepts bus number (e.g. '205') or bus UUID.
    """
    bus_num = bus_identifier
    # Check if identifier is a UUID
    for b_n, state in gps_simulator.fleet_state.items():
        if state.get("bus_id") == bus_identifier:
            bus_num = b_n
            break

    if bus_num not in gps_simulator.fleet_state and bus_num not in CORRIDOR_METADATA:
        raise HTTPException(status_code=404, detail=f"No prediction model found for bus '{bus_identifier}'")

    forecast = demand_forecaster.forecast_corridor_crowd(route_number=bus_num)

    # Asynchronously persist prediction snapshot to Supabase crowd_predictions table
    try:
        route_rec = await supabase_client.get_route_by_number(bus_num)
        route_id = route_rec["id"] if route_rec else "00000000-0000-0000-0000-000000000101"
        stop_id = "00000000-0000-0000-0000-000000000001"
        pred_30 = next((p for p in forecast if p.time_offset == "+30 MIN"), forecast[0])
        await supabase_client.post("crowd_predictions", {
            "route_id": route_id,
            "stop_id": stop_id,
            "time_horizon_mins": 30,
            "predicted_occupancy_pct": pred_30.predicted_occupancy_pct,
            "predicted_crowd_level": pred_30.crowd_level.value if hasattr(pred_30.crowd_level, "value") else str(pred_30.crowd_level),
            "confidence_score": pred_30.confidence,
            "contributing_factors": {"corridor": bus_num, "horizon": "+30 MIN", "model": demand_forecaster.MODEL_VERSION},
            "data_origin": "PREDICTION"
        })
    except Exception as e:
        print(f"[Supabase Prediction Warning] {e}")

    return ApiResponse(
        data=forecast,
        data_origin=DataOrigin.PREDICTION,
        message=f"Crowd predictions for Bus {bus_num}"
    )

@router.get("/{bus_identifier}/details", response_model=ApiResponse[DetailedBusForecastResponse])
async def get_bus_prediction_details(bus_identifier: str, is_rain: bool = False):
    """
    Returns rich multi-horizon prediction details conforming to Phase H9 specification:
    current observation, forward horizons, evaluation metrics, and low-data status.
    """
    bus_num = bus_identifier
    for b_n, state in gps_simulator.fleet_state.items():
        if state.get("bus_id") == bus_identifier:
            bus_num = b_n
            break

    if bus_num not in gps_simulator.fleet_state and bus_num not in CORRIDOR_METADATA:
        raise HTTPException(status_code=404, detail=f"No prediction model found for bus '{bus_identifier}'")

    detailed = demand_forecaster.get_detailed_forecast(bus_number=bus_num, is_rain=is_rain)
    return ApiResponse(
        data=detailed,
        data_origin=DataOrigin.PREDICTION,
        message=f"Detailed crowd prediction for Bus {bus_num}"
    )
