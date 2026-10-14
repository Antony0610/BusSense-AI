"""
BusSense AI - Occupancy & Crowd Forecasting Endpoints
"""
from fastapi import APIRouter, Depends, Header, HTTPException, status
from typing import List, Dict, Any, Optional
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.prediction import CrowdForecastPoint
from app.services.demand_forecaster import demand_forecaster
from app.services.gps_simulator import gps_simulator
from app.core.security import get_current_user, TokenPayload
from app.core.config import settings

try:
    from backend.cv.schemas import OccupancyEvent
    from backend.cv.occupancy import OccupancyCalculator
except ImportError:
    from cv.schemas import OccupancyEvent
    from cv.occupancy import OccupancyCalculator

router = APIRouter(prefix="/occupancy", tags=["Occupancy & Crowd Estimation"])

from app.core.supabase import supabase_client
from app.schemas.realtime import RealtimeEvent, RealtimeEventType
from app.services.realtime_service import realtime_service

async def verify_cv_ingest_auth(
    authorization: Optional[str] = Header(None),
    x_internal_secret: Optional[str] = Header(None)
):
    """
    Enforces authentication for CV replay ingestion (Section 16).
    Rejects unauthorized access with HTTP 401.
    Rejects insufficient roles with HTTP 403.
    Permits AUTHORITY or ADMIN JWT Bearer token, or valid X-Internal-Secret header.
    """
    if x_internal_secret and x_internal_secret == settings.SECRET_KEY:
        return {"auth": "internal_secret", "role": "ADMIN"}

    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        user: TokenPayload = await get_current_user(token)
        if user.role not in ["AUTHORITY", "ADMIN"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Requires AUTHORITY or ADMIN role. Current: {user.role}"
            )
        return {"auth": "bearer", "role": user.role}

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Unauthorized CV replay ingestion. Provide valid AUTHORITY/ADMIN Bearer token or X-Internal-Secret header.",
        headers={"WWW-Authenticate": "Bearer"}
    )

@router.get("/forecast/{bus_number}", response_model=ApiResponse[List[CrowdForecastPoint]])
async def get_bus_crowd_forecast(bus_number: str = "205"):
    """
    Returns 4-point crowd forecast: NOW, +15 MIN, +30 MIN, +60 MIN
    Calculated via scikit-learn model with weather, time-of-day, and corridor historical density.
    Persists prediction snapshots to Supabase PostgreSQL table `crowd_predictions`.
    """
    forecast = demand_forecaster.forecast_corridor_crowd(route_number=bus_number)
    
    # Asynchronously persist prediction snapshot to Supabase
    try:
        route_rec = await supabase_client.get_route_by_number(bus_number)
        route_id = route_rec["id"] if route_rec else "00000000-0000-0000-0000-000000000101"
        stop_id = "00000000-0000-0000-0000-000000000001"
        
        # Persist the 30-min horizon projection
        pred_30 = next((p for p in forecast if p.time_offset == "+30 MIN"), forecast[0])
        await supabase_client.post("crowd_predictions", {
            "route_id": route_id,
            "stop_id": stop_id,
            "time_horizon_mins": 30,
            "predicted_occupancy_pct": pred_30.predicted_occupancy_pct,
            "predicted_crowd_level": pred_30.crowd_level,
            "confidence_score": 0.880,
            "contributing_factors": pred_30.factors,
            "data_origin": "PREDICTION"
        })
    except Exception as e:
        print(f"[Supabase Prediction Warning] {e}")

    return ApiResponse(
        data=forecast,
        data_origin=DataOrigin.PREDICTION,
        message=f"Crowd forecast trajectory for Bus {bus_number}"
    )

@router.get("/live/{bus_number}", response_model=ApiResponse[dict])
async def get_live_occupancy(bus_number: str = "205"):
    telemetry = gps_simulator.get_bus_telemetry(bus_number)
    origin = telemetry.get("data_origin", DataOrigin.SIMULATED)
    return ApiResponse(
        data={
            "bus_number": bus_number,
            "passenger_count": telemetry.get("passenger_count", 23),
            "capacity": telemetry.get("capacity", 55),
            "occupancy_percentage": telemetry.get("occupancy_pct", 41.8),
            "crowd_level": telemetry.get("crowd_level", "LOW"),
            "detection_source": telemetry.get("detection_source", "YOLOv8_CCTV_Camera"),
            "privacy_standard": "PERSON_COUNTING_ONLY_NO_FACIAL_RECOGNITION"
        },
        data_origin=origin
    )

@router.post("/events", response_model=ApiResponse[OccupancyEvent])
async def ingest_occupancy_event(
    event: OccupancyEvent,
    auth_context: dict = Depends(verify_cv_ingest_auth)
):
    """
    Ingests a validated OccupancyEvent from the Computer Vision pipeline (Section 15).
    Strictly validates:
    - bus number exists in active fleet
    - capacity > 0
    - person counts >= 0
    - recalculates trusted occupancy percentage and verifies crowd tier (never blindly trust client percentage)
    - enforces source: CV_REPLAY
    Updates in-memory fleet state and persists event to Supabase occupancy_readings.
    """
    # 1. Validate bus existence in active fleet
    if event.bus_number not in gps_simulator.fleet_state:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Bus number '{event.bus_number}' not found in active fleet"
        )

    # 2. Validate capacity & counts
    if event.capacity <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Vehicle capacity must be greater than 0"
        )
    if event.raw_person_count < 0 or event.stabilized_person_count < 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Person count cannot be negative"
        )

    # 3. Recalculate trusted occupancy percentage (do not trust arbitrary client ratio)
    trusted_pct = OccupancyCalculator.calculate_occupancy_percentage(
        event.stabilized_person_count,
        event.capacity
    )
    trusted_crowd_level = OccupancyCalculator.classify_crowd_tier(trusted_pct)

    # 4. Enforce trusted values on event model
    event.occupancy_percentage = trusted_pct
    event.crowd_level = trusted_crowd_level
    event.source = "CV_REPLAY"
    event.privacy_standard = "PERSON_COUNTING_ONLY_NO_BIOMETRICS"

    # 5. Update GPS simulator fleet state
    gps_simulator.update_from_cv_event(
        bus_number=event.bus_number,
        passenger_count=event.stabilized_person_count,
        capacity=event.capacity,
        occupancy_pct=trusted_pct,
        crowd_level=trusted_crowd_level,
        detection_source=f"{event.model}_CV_Replay"
    )

    # 6. Asynchronously persist to Supabase occupancy_readings table (Section 17)
    try:
        bus_info = gps_simulator.fleet_state.get(event.bus_number, {})
        bus_id = bus_info.get("bus_id", "a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa")
        await supabase_client.post("occupancy_readings", {
            "bus_id": bus_id,
            "passenger_count": event.stabilized_person_count,
            "capacity": event.capacity,
            "occupancy_pct": trusted_pct,
            "crowd_level": trusted_crowd_level,
            "detection_source": f"{event.model}_CV_Replay",
            "data_origin": "CV_REPLAY"
        })
    except Exception as db_err:
        print(f"[Supabase Persistence Warning] {db_err}")

    # 7. Publish RealtimeEvent for real-time fleet occupancy update
    await realtime_service.publish_event(RealtimeEvent(
        event_type=RealtimeEventType.OCCUPANCY_UPDATE.value,
        entity_id=event.bus_number,
        data_origin="CV REPLAY",
        payload=event.model_dump()
    ))

    return ApiResponse(
        data=event,
        data_origin=DataOrigin.CV_REPLAY,
        message=f"Occupancy event ingested for Bus {event.bus_number} (CV REPLAY)"
    )

@router.get("/predictions", response_model=ApiResponse[dict])
async def get_occupancy_predictions(bus_number: str = "205"):
    """
    Frontend compatibility endpoint returning structured 4-horizon dictionary:
    { "now": {...}, "plus_15m": {...}, "plus_30m": {...}, "plus_60m": {...} }
    Reuses demand_forecaster engine without duplicate logic.
    """
    forecast = demand_forecaster.forecast_corridor_crowd(route_number=bus_number)
    lookup = {p.time_offset: p for p in forecast}
    p_now = lookup.get("NOW", forecast[0])
    p_15 = lookup.get("+15 MIN", forecast[1] if len(forecast) > 1 else forecast[0])
    p_30 = lookup.get("+30 MIN", forecast[2] if len(forecast) > 2 else forecast[0])
    p_60 = lookup.get("+60 MIN", forecast[3] if len(forecast) > 3 else forecast[0])

    return ApiResponse(
        data={
            "now": {"occupancy_pct": p_now.predicted_occupancy_pct, "crowd_level": p_now.crowd_level.value if hasattr(p_now.crowd_level, "value") else str(p_now.crowd_level), "confidence": p_now.confidence},
            "plus_15m": {"occupancy_pct": p_15.predicted_occupancy_pct, "crowd_level": p_15.crowd_level.value if hasattr(p_15.crowd_level, "value") else str(p_15.crowd_level), "confidence": p_15.confidence},
            "plus_30m": {"occupancy_pct": p_30.predicted_occupancy_pct, "crowd_level": p_30.crowd_level.value if hasattr(p_30.crowd_level, "value") else str(p_30.crowd_level), "confidence": p_30.confidence},
            "plus_60m": {"occupancy_pct": p_60.predicted_occupancy_pct, "crowd_level": p_60.crowd_level.value if hasattr(p_60.crowd_level, "value") else str(p_60.crowd_level), "confidence": p_60.confidence}
        },
        data_origin=DataOrigin.PREDICTION,
        message=f"4-horizon occupancy predictions for Bus {bus_number}"
    )

