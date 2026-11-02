"""
BusSense AI - Crowd Predictions & Smart Recommendations Schemas
"""
from typing import Optional, List, Dict, Any
from datetime import datetime, timezone
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

class RecommendationImpressionRequest(BaseModel):
    journey_id: str
    recommended_bus_number: str
    presented_alternatives_count: int
    preference: str = "balanced"
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())

class RecommendationSelectionRequest(BaseModel):
    journey_id: str
    selected_bus_number: str
    was_recommended_bus: bool
    selection_reason: Optional[str] = None
    crowd_level_at_selection: Optional[str] = None
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())

class RecommendationAnalyticsResponse(BaseModel):
    total_impressions: int
    total_selections: int
    recommended_bus_selections: int
    alternative_selections: int
    compliance_rate_pct: float
    crowd_savings_achieved_avg_pct: float
    stale_telemetry_penalties_applied: int
    avg_waiting_time_delta_mins: Optional[float] = None
    predicted_vs_observed_occupancy_delta: Optional[float] = None
    recommendation_availability_pct: float = 100.0
    advisory_mode_enforced: bool = True
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())

class HorizonEvaluationDetail(BaseModel):
    horizon_minutes: int
    model_mae: float
    model_rmse: float
    baseline_mae: float
    baseline_rmse: float
    mae_improvement_pct: float
    sma_baseline_mae: Optional[float] = None
    sma_baseline_rmse: Optional[float] = None
    sma_mae_improvement_pct: Optional[float] = None
    mean_residual: Optional[float] = None
    residual_std: Optional[float] = None
    residual_skewness: Optional[float] = None

class PeakOffPeakEvaluation(BaseModel):
    peak_hours_definition: str = "08:00-10:30, 17:00-19:30 IST"
    peak_sample_count: int
    offpeak_sample_count: int
    peak_metrics: Dict[int, HorizonEvaluationDetail]
    offpeak_metrics: Dict[int, HorizonEvaluationDetail]

class CorridorEvaluationDetail(BaseModel):
    corridor_key: str
    corridor_name: str
    sample_count: int
    horizons: Dict[int, HorizonEvaluationDetail]

class PilotForecastingEvaluationResponse(BaseModel):
    model_version: str
    training_data_quality: str
    total_samples: int
    train_split_pct: float
    validation_split_pct: float = 15.0
    test_split_pct: float
    overall_metrics: List[HorizonEvaluationDetail]
    peak_vs_offpeak: PeakOffPeakEvaluation
    corridor_evaluations: List[CorridorEvaluationDetail]
    feature_importance: Optional[Dict[str, float]] = None
    overfitting_risk_assessment: Optional[str] = "LOW (L2 regularization alpha=1.0, validation-checked, 10 engineered features)"
    residual_distribution: Optional[Dict[str, Dict[str, float]]] = None
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())

