"""
BusSense AI - Crowd Predictions & Smart Recommendations Schemas
"""
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from app.schemas.common import CrowdLevel, DataOrigin

class CrowdForecastPoint(BaseModel):
    time_offset: str # "NOW", "+15 MIN", "+30 MIN", "+60 MIN"
    minutes_from_now: int
    predicted_occupancy_pct: float
    crowd_level: CrowdLevel
    confidence: float
    data_origin: DataOrigin = DataOrigin.PREDICTION

class PredictionHorizonDetail(BaseModel):
    occupancy_pct: float
    crowd_level: CrowdLevel
    confidence: float

class PredictionHorizonMap(BaseModel):
    now: PredictionHorizonDetail
    plus_15m: PredictionHorizonDetail
    plus_30m: PredictionHorizonDetail
    plus_60m: PredictionHorizonDetail

class RoutePredictionSummary(BaseModel):
    bus_number: str
    route_number: str
    corridor_name: str
    horizon: PredictionHorizonMap
    data_origin: DataOrigin = DataOrigin.PREDICTION

class DetailedForecastItem(BaseModel):
    horizon_minutes: int
    occupancy_pct: float
    crowd_level: CrowdLevel
    confidence: float
    message: Optional[str] = None

class CurrentObservationDetail(BaseModel):
    occupancy_pct: float
    crowd_level: CrowdLevel
    passenger_count: int
    capacity: int
    data_origin: DataOrigin

class EvaluationMetricSummary(BaseModel):
    horizon_minutes: int
    baseline_mae: float
    model_mae: float
    baseline_rmse: float
    model_rmse: float
    mae_improvement_pct: float

class DetailedBusForecastResponse(BaseModel):
    bus_number: str
    route_number: str
    generated_at: str
    current: CurrentObservationDetail
    forecast: List[DetailedForecastItem]
    model_version: str
    training_data_quality: str
    status: str = "OPTIMAL"
    evaluation_metrics: Optional[List[EvaluationMetricSummary]] = None
    data_origin: DataOrigin = DataOrigin.PREDICTION


class BusRecommendationItem(BaseModel):
    bus_number: str
    route_number: str
    route_name: str
    operator_type: str
    eta_mins: int
    occupancy_pct: float
    crowd_level: CrowdLevel
    is_recommended: bool
    journey_score: float
    why_recommended: str
    crowd_saving_vs_alternative_pct: Optional[float] = None
    time_saving_mins: Optional[int] = None
    fare_inr: float
    predicted_occupancy_pct: Optional[float] = None
    predicted_crowd_level: Optional[CrowdLevel] = None
    data_quality: Optional[str] = "HIGH"
    score_breakdown: Optional[Dict[str, float]] = None
    data_origin: DataOrigin = DataOrigin.RECOMMENDATION

class JourneyPlanRequest(BaseModel):
    origin: Optional[str] = "Kaloor Metro Station, Kochi"
    destination: Optional[str] = "Vyttila Mobility Hub"
    origin_stop_id: Optional[str] = None
    destination_stop_id: Optional[str] = None
    preference: Optional[str] = "balanced"
    prefer_low_crowd: bool = True
    prefer_ac: bool = False

class JourneyPlanResponse(BaseModel):
    origin_stop: str
    destination_stop: str
    recommended_bus: BusRecommendationItem
    alternative_buses: List[BusRecommendationItem]
    route_distance_km: float
    estimated_travel_time_mins: int
    explanation: str
    preference: Optional[str] = "balanced"
    factors_considered: Optional[Dict[str, bool]] = None
    data_quality: Optional[str] = "HIGH"
    data_origin: DataOrigin = DataOrigin.RECOMMENDATION
