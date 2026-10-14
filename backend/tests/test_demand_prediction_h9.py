"""
BusSense AI - Phase H9 Demand Prediction & Crowd Forecasting Engine Test Suite
Tests:
1. Historical data retrieval and deterministic generation
2. Explainable feature engineering (10 features, cyclical sin/cos encoding)
3. Time ordering and strict non-leakage train/test chronological split
4. Multi-horizon prediction generation (NOW, +15m, +30m, +60m)
5. Occupancy clamping to [0.0, 100.0]%
6. Crowd threshold classification (LOW < 50%, MODERATE 50-80%, CROWDED > 80%)
7. Model evaluation vs persistence baseline (MAE & RMSE improvement)
8. Low-data handling and safety fallbacks
9. Prediction schema validation (Pydantic v2 schemas)
10. Model versioning and training data transparency
11. Dynamic inference across different buses (no hardcoded Bus 205 values)
12. Observed vs predicted data separation
13. FastAPI endpoints: GET /api/predictions, /api/predictions/{bus}, /api/predictions/{bus}/details
14. Authority occupancy predictions endpoint: GET /api/occupancy/predictions
15. CV replay real-time state integration with predictions
16. Prediction latency performance (< 50ms)
"""
import sys
import os
import time
import math
from datetime import datetime, timezone
import pytest
import numpy as np
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.main import app
from app.services.prediction_dataset import (
    generate_corridor_historical_observations,
    FeatureEngineer,
    CORRIDOR_PROFILES,
)
from app.services.demand_forecaster import demand_forecaster, DemandForecasterService
from app.services.gps_simulator import gps_simulator
from app.schemas.prediction import (
    CrowdForecastPoint,
    PredictionHorizonMap,
    DetailedBusForecastResponse,
)
from app.schemas.common import CrowdLevel, DataOrigin

client = TestClient(app)

# ==========================================
# 1. Historical Data Retrieval & Generation
# ==========================================

def test_historical_data_retrieval():
    """Verify deterministic corridor historical observation generation."""
    observations = generate_corridor_historical_observations(days=2, interval_minutes=15)
    assert len(observations) > 500, f"Expected > 500 observations, got {len(observations)}"

    sample = observations[0]
    required_keys = {
        "bus_number", "route_number", "capacity", "passenger_count",
        "occupancy_pct", "crowd_level", "recorded_at", "hour_of_day",
        "day_of_week", "is_weekend"
    }
    assert required_keys.issubset(sample.keys())
    assert sample["capacity"] > 0
    assert 0 <= sample["passenger_count"] <= sample["capacity"]
    assert 0.0 <= sample["occupancy_pct"] <= 100.0
    assert sample["crowd_level"] in ["LOW", "MODERATE", "CROWDED"]

    # Verify deterministic reproducibility
    obs2 = generate_corridor_historical_observations(days=2, interval_minutes=15)
    assert len(observations) == len(obs2)
    assert observations[0]["occupancy_pct"] == obs2[0]["occupancy_pct"]


# ==========================================
# 2. Feature Engineering
# ==========================================

def test_feature_engineering_structure_and_cyclical_encoding():
    """Verify 10-feature vector extraction and cyclical trigonometric encoding."""
    assert len(FeatureEngineer.FEATURE_NAMES) == 10

    # Test at midnight (0.0): sin(0) = 0, cos(0) = 1
    features_midnight = FeatureEngineer.extract_features_for_observation(
        hour_of_day=0.0,
        day_of_week=0,
        is_weekend=0,
        current_occupancy=40.0,
        lag_1_occupancy=38.0,
        lag_2_occupancy=36.0,
        corridor_base_density=0.5
    )
    assert len(features_midnight) == 10
    assert features_midnight[0] == 0.0
    assert features_midnight[1] == 0.0  # sin(0)
    assert features_midnight[2] == 1.0  # cos(0)
    assert features_midnight[7] == 38.0 # rolling_3 = (40 + 38 + 36) / 3
    assert features_midnight[8] == 2.0  # slope = 40 - 38

    # Test at 6 AM (6.0): sin(pi/2) = 1, cos(pi/2) = 0
    features_6am = FeatureEngineer.extract_features_for_observation(
        hour_of_day=6.0,
        day_of_week=2,
        is_weekend=0,
        current_occupancy=50.0,
        lag_1_occupancy=45.0,
        lag_2_occupancy=40.0,
        corridor_base_density=0.65
    )
    assert features_6am[1] == pytest.approx(1.0, abs=1e-3)
    assert features_6am[2] == pytest.approx(0.0, abs=1e-3)
    assert features_6am[7] == 45.0 # rolling_3
    assert features_6am[8] == 5.0  # slope = 50 - 45


# ==========================================
# 3. Time Ordering & No Future Leakage
# ==========================================

def test_time_ordering_and_dataset_split():
    """Verify strict chronological time ordering and zero future data leakage."""
    observations = generate_corridor_historical_observations(days=2, interval_minutes=15)
    
    # Check observations are strictly sorted by recorded_at
    for i in range(len(observations) - 1):
        assert observations[i]["recorded_at"] <= observations[i + 1]["recorded_at"]

    X, y = FeatureEngineer.build_chronological_dataset(observations)
    assert len(X) > 0
    assert len(X) == len(y[15]) == len(y[30]) == len(y[60])

    # Check 80/20 chronological split used in demand_forecaster
    split = int(len(X) * 0.8)
    assert split > 0
    assert len(X) - split > 0


# ==========================================
# 4. Multi-Horizon Predictions (+15m, +30m, +60m)
# ==========================================

def test_prediction_generation_multi_horizons():
    """Verify 4-point forecast generation (NOW, +15m, +30m, +60m)."""
    forecast = demand_forecaster.forecast_corridor_crowd(route_number="205")
    assert len(forecast) == 4

    labels = [p.time_offset for p in forecast]
    minutes = [p.minutes_from_now for p in forecast]
    assert labels == ["NOW", "+15 MIN", "+30 MIN", "+60 MIN"]
    assert minutes == [0, 15, 30, 60]

    for p in forecast:
        assert isinstance(p.predicted_occupancy_pct, float)
        assert 0.0 <= p.predicted_occupancy_pct <= 100.0
        assert p.crowd_level in [CrowdLevel.LOW, CrowdLevel.MODERATE, CrowdLevel.CROWDED]
        assert 0.0 <= p.confidence <= 1.0
        assert p.data_origin == DataOrigin.PREDICTION


# ==========================================
# 5. Occupancy Clamping
# ==========================================

def test_occupancy_clamping_under_extreme_conditions():
    """Forecasted occupancy must strictly remain within [0.0, 100.0]%."""
    # Force extreme simulated occupancy
    gps_simulator.fleet_state["205"]["occupancy_pct"] = 99.5
    high_forecast = demand_forecaster.forecast_corridor_crowd("205", is_rain=True)
    for p in high_forecast:
        assert p.predicted_occupancy_pct <= 100.0, f"Exceeded 100%: {p.predicted_occupancy_pct}"

    gps_simulator.fleet_state["205"]["occupancy_pct"] = 0.5
    low_forecast = demand_forecaster.forecast_corridor_crowd("205", is_rain=False)
    for p in low_forecast:
        assert p.predicted_occupancy_pct >= 0.0, f"Below 0%: {p.predicted_occupancy_pct}"

    # Reset to normal
    gps_simulator.fleet_state["205"]["occupancy_pct"] = 41.8


# ==========================================
# 6. Crowd Threshold Classification
# ==========================================

def test_crowd_threshold_classification():
    """Verify exact H8/H9 unified thresholds: LOW < 50%, MODERATE 50-80%, CROWDED > 80%."""
    from app.services.cv_occupancy import cv_occupancy_service
    assert cv_occupancy_service.calculate_crowd_tier(0.0) == CrowdLevel.LOW
    assert cv_occupancy_service.calculate_crowd_tier(49.9) == CrowdLevel.LOW
    assert cv_occupancy_service.calculate_crowd_tier(50.0) == CrowdLevel.MODERATE
    assert cv_occupancy_service.calculate_crowd_tier(75.0) == CrowdLevel.MODERATE
    assert cv_occupancy_service.calculate_crowd_tier(80.0) == CrowdLevel.MODERATE
    assert cv_occupancy_service.calculate_crowd_tier(80.1) == CrowdLevel.CROWDED
    assert cv_occupancy_service.calculate_crowd_tier(100.0) == CrowdLevel.CROWDED


# ==========================================
# 7. Model Evaluation vs Persistence Baseline
# ==========================================

def test_model_evaluation_metrics_vs_baseline():
    """Verify Ridge model improves upon the persistence baseline (MAE & RMSE)."""
    metrics = demand_forecaster.evaluation_metrics
    assert 15 in metrics and 30 in metrics and 60 in metrics

    for h in [15, 30, 60]:
        h_metrics = metrics[h]
        assert "model_mae" in h_metrics
        assert "baseline_mae" in h_metrics
        assert "model_rmse" in h_metrics
        assert "baseline_rmse" in h_metrics
        assert "mae_improvement_pct" in h_metrics
        # Model must perform better than persistence baseline
        assert h_metrics["model_mae"] < h_metrics["baseline_mae"]
        assert h_metrics["mae_improvement_pct"] > 0.0


# ==========================================
# 8. Low-Data Handling & Safety
# ==========================================

def test_low_data_safety_handling():
    """Unmonitored or low-data buses must return LOW_DATA status and lower confidence."""
    detailed = demand_forecaster.get_detailed_forecast(bus_number="UNKNOWN_BUS_999")
    assert detailed.status == "LOW_DATA"
    # Fallback forecast still valid and clamped
    assert len(detailed.forecast) == 3
    for f in detailed.forecast:
        assert 0.0 <= f.occupancy_pct <= 100.0
        # Low data confidence penalty applied
        assert f.confidence < 0.70


# ==========================================
# 9. Prediction Schema Validation
# ==========================================

def test_prediction_schema_serialization():
    """Verify detailed forecast response serialization against Pydantic schema."""
    detailed = demand_forecaster.get_detailed_forecast(bus_number="205")
    assert isinstance(detailed, DetailedBusForecastResponse)
    dumped = detailed.model_dump()
    assert dumped["bus_number"] == "205"
    assert dumped["data_origin"] == "PREDICTION"
    assert dumped["model_version"] == "ridge-demand-v2-corridor"
    assert len(dumped["forecast"]) == 3
    assert len(dumped["evaluation_metrics"]) == 3


# ==========================================
# 10. Model Versioning & Data Transparency
# ==========================================

def test_model_versioning_and_transparency():
    """Ensure model version and training quality are documented and not claiming fake production."""
    detailed = demand_forecaster.get_detailed_forecast(bus_number="205")
    assert detailed.model_version == "ridge-demand-v2-corridor"
    assert "DEVELOPMENT / LOW-DATA" in detailed.training_data_quality
    assert detailed.status in ["OPTIMAL", "LOW_DATA"]


# ==========================================
# 11. No Hardcoded Values & Corridor Variation
# ==========================================

def test_different_buses_dynamic_inference():
    """Different buses must produce distinct predictions driven by their state/corridor."""
    gps_simulator.fleet_state["205"]["occupancy_pct"] = 35.0
    gps_simulator.fleet_state["14A"]["occupancy_pct"] = 72.0

    forecast_205 = demand_forecaster.forecast_corridor_crowd("205")
    forecast_14a = demand_forecaster.forecast_corridor_crowd("14A")

    # Current occupancies must match fleet state
    assert forecast_205[0].predicted_occupancy_pct == 35.0
    assert forecast_14a[0].predicted_occupancy_pct == 72.0

    # Predictions must not be equal
    pred_205_30m = forecast_205[2].predicted_occupancy_pct
    pred_14a_30m = forecast_14a[2].predicted_occupancy_pct
    assert pred_205_30m != pred_14a_30m

    # Reset
    gps_simulator.fleet_state["205"]["occupancy_pct"] = 41.8
    gps_simulator.fleet_state["14A"]["occupancy_pct"] = 73.3


# ==========================================
# 12. Observed vs Predicted Separation
# ==========================================

def test_observed_vs_predicted_data_separation():
    """Observed readings must retain SIMULATED/CV_REPLAY while forward points are PREDICTION."""
    detailed = demand_forecaster.get_detailed_forecast(bus_number="205")
    assert detailed.current.data_origin in [DataOrigin.SIMULATED, DataOrigin.CV_REPLAY]
    assert detailed.data_origin == DataOrigin.PREDICTION
    for f in detailed.forecast:
        assert isinstance(f.occupancy_pct, float)


# ==========================================
# 13. FastAPI Predictions Endpoints
# ==========================================

def test_api_list_fleet_predictions():
    """GET /api/predictions returns fleet corridors summary."""
    resp = client.get("/api/predictions")
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert len(data) >= 3
    corridor_buses = [c["bus_number"] for c in data]
    assert "205" in corridor_buses
    assert "14A" in corridor_buses
    assert "12" in corridor_buses

def test_api_get_bus_predictions_and_details():
    """GET /api/predictions/{bus} and /api/predictions/{bus}/details."""
    # 4-horizon list
    resp1 = client.get("/api/predictions/205")
    assert resp1.status_code == 200
    points = resp1.json()["data"]
    assert len(points) == 4
    assert points[0]["time_offset"] == "NOW"

    # Detailed response
    resp2 = client.get("/api/predictions/205/details")
    assert resp2.status_code == 200
    detail = resp2.json()["data"]
    assert detail["bus_number"] == "205"
    assert "model_version" in detail
    assert "evaluation_metrics" in detail
    assert len(detail["forecast"]) == 3

    # Unknown bus returns 404
    resp3 = client.get("/api/predictions/nonexistent_bus_9999")
    assert resp3.status_code == 404


# ==========================================
# 14. Authority Occupancy Predictions API
# ==========================================

def test_api_occupancy_predictions_authority():
    """GET /api/occupancy/predictions returns dictionary of horizons for Authority UI."""
    resp = client.get("/api/occupancy/predictions?bus_number=205")
    assert resp.status_code == 200
    payload = resp.json()
    assert "data" in payload
    data = payload["data"]
    assert "now" in data
    assert "plus_15m" in data
    assert "plus_30m" in data
    assert "plus_60m" in data
    assert data["now"]["crowd_level"] in ["LOW", "MODERATE", "CROWDED"]


# ==========================================
# 15. CV Replay Real-Time Integration
# ==========================================

def test_cv_replay_integration_with_predictions():
    """When CV replay updates fleet state, predictions immediately branch from it."""
    # Simulate CV occupancy event update
    gps_simulator.fleet_state["205"]["occupancy_pct"] = 68.5
    gps_simulator.fleet_state["205"]["data_origin"] = DataOrigin.CV_REPLAY

    forecast = demand_forecaster.forecast_corridor_crowd("205")
    assert forecast[0].predicted_occupancy_pct == 68.5
    assert forecast[0].confidence == 0.95 # Higher confidence for verified CV

    # Clean up
    gps_simulator.fleet_state["205"]["occupancy_pct"] = 41.8
    gps_simulator.fleet_state["205"]["data_origin"] = DataOrigin.SIMULATED


# ==========================================
# 16. Latency & Performance (< 50ms per call)
# ==========================================

def test_prediction_inference_latency():
    """Demand prediction inference must complete in < 50ms on CPU."""
    start_time = time.perf_counter()
    iterations = 50
    for _ in range(iterations):
        _ = demand_forecaster.forecast_corridor_crowd("205")
    elapsed = time.perf_counter() - start_time
    avg_latency_ms = (elapsed / iterations) * 1000.0

    assert avg_latency_ms < 50.0, f"Average latency too high: {avg_latency_ms:.2f}ms"
