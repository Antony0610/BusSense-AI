"""
BusSense AI - Phase H18 Comprehensive Pilot Validation Suite
Validates:
1. Real transit data connectors & provider lifecycle (expiration, rate limiting, adapters)
2. GPS physical movement & map-matching stress tests (jumps, NaN, recovery, off-route)
3. CV ground-truth evaluation metrics (MAE, RMSE, MAPE, precision, recall, P95, zero-biometrics)
4. Demand forecasting validation (chronological 70/15/15 split, SMA & persistence baselines, residuals, feature importance)
5. Recommendation feedback loop & strictly advisory mode
6. Comprehensive pilot monitoring dashboard
"""
import math
import time
from datetime import datetime, timezone, timedelta
import pytest

from app.schemas.ingestion import (
    ExternalProviderRegisterRequest,
    GpsTelemetryBatchRequest,
    GpsTelemetryRecord,
    CctvOccupancyIngestRecord,
    PilotMonitoringDashboardResponse,
    TransitAdapterSpec
)
from app.schemas.common import DataOrigin
from app.services.ingestion_service import IngestionService, ingestion_service
from cv.evaluator import cv_evaluator, CVEvaluationReport
from app.services.demand_forecaster import demand_forecaster
from app.services.recommendation_engine import recommendation_engine
from app.schemas.prediction import (
    RecommendationImpressionRequest,
    RecommendationSelectionRequest,
    PilotForecastingEvaluationResponse
)

# -----------------------------------------------------------------------------
# 1. Real Transit Data Connectors & Provider Lifecycle
# -----------------------------------------------------------------------------

def test_provider_key_expiration():
    svc = IngestionService()
    past_iso = (datetime.now(timezone.utc) - timedelta(days=2)).isoformat()
    req = ExternalProviderRegisterRequest(
        provider_id="EXPIRED_FEED_PARTNER",
        provider_name="Expired Pilot Partner",
        allowed_feed_types=["AVL_GPS"],
        contact_email="expired@keralartc.com",
        expires_at=past_iso
    )
    resp, raw_key = svc.register_provider(req)
    assert resp.expires_at == past_iso

    # Verification should reject expired key
    valid, err, prov = svc.verify_provider_api_key(raw_key, feed_type="AVL_GPS")
    assert valid is False
    assert "PROVIDER_KEY_EXPIRED" in err

def test_provider_rate_limiting():
    svc = IngestionService()
    req = ExternalProviderRegisterRequest(
        provider_id="RATE_LIMITED_PARTNER",
        provider_name="Rate Limited Partner",
        allowed_feed_types=["AVL_GPS"],
        contact_email="limited@kochimetro.org",
        rate_limit_per_minute=3
    )
    resp, raw_key = svc.register_provider(req)

    # 3 allowed requests
    for _ in range(3):
        valid, err, _ = svc.verify_provider_api_key(raw_key, feed_type="AVL_GPS")
        assert valid is True
        assert err is None

    # 4th request must exceed rate limit
    valid, err, _ = svc.verify_provider_api_key(raw_key, feed_type="AVL_GPS")
    assert valid is False
    assert "RATE_LIMIT_EXCEEDED" in err

def test_preconfigured_transit_adapters():
    svc = IngestionService()
    adapters = svc.list_transit_adapters()
    assert len(adapters) >= 4
    adapter_ids = [a.adapter_id for a in adapters]
    assert "KSRTC_SWIFT_AVL_ADAPTER" in adapter_ids
    assert "KMRL_FEEDER_AVL_ADAPTER" in adapter_ids
    assert "CCTV_HEADCOUNT_GATEWAY_ADAPTER" in adapter_ids
    assert "KERALA_POLICE_DISRUPTION_ADAPTER" in adapter_ids

    # Verify zero biometrics standard in CCTV adapter
    cctv_ad = next(a for a in adapters if a.adapter_id == "CCTV_HEADCOUNT_GATEWAY_ADAPTER")
    assert cctv_ad.sample_payload.get("privacy_standard") == "PERSON_COUNTING_ONLY_NO_BIOMETRICS"
    assert "CV REPLAY" in cctv_ad.truth_label

# -----------------------------------------------------------------------------
# 2. GPS Physical Movement & Map-Matching Stress Tests
# -----------------------------------------------------------------------------

def test_gps_nan_and_inf_rejection():
    now_iso = datetime.now(timezone.utc).isoformat()

    # Pydantic schema boundary rejects NaN/Inf
    with pytest.raises(Exception):
        GpsTelemetryRecord(
            bus_number="205",
            latitude=float("nan"),
            longitude=76.3080,
            timestamp=now_iso,
            data_origin=DataOrigin.LIVE
        )

    with pytest.raises(Exception):
        GpsTelemetryRecord(
            bus_number="205",
            latitude=10.0270,
            longitude=float("inf"),
            timestamp=now_iso,
            data_origin=DataOrigin.LIVE
        )

def test_gps_sudden_jump_impossible_velocity():
    svc = IngestionService()
    t0 = datetime.now(timezone.utc) - timedelta(seconds=60)
    
    # First ping at Aluva (10.1000, 76.3500)
    b1 = GpsTelemetryBatchRequest(
        feed_id="TEST_FEED",
        records=[
            GpsTelemetryRecord(
                bus_number="205",
                latitude=10.1000,
                longitude=76.3500,
                speed_kmh=30.0,
                timestamp=t0.isoformat(),
                sequence_number=1,
                data_origin=DataOrigin.LIVE
            )
        ]
    )
    res1 = svc.ingest_gps_batch(b1)
    assert res1.accepted == 1

    # Second ping 2 seconds later at Vyttila (9.9700, 76.3200) -> ~15 km jump in 2s (>25,000 km/h!)
    t1 = t0 + timedelta(seconds=2)
    b2 = GpsTelemetryBatchRequest(
        feed_id="TEST_FEED",
        records=[
            GpsTelemetryRecord(
                bus_number="205",
                latitude=9.9700,
                longitude=76.3200,
                speed_kmh=40.0,
                timestamp=t1.isoformat(),
                sequence_number=2,
                data_origin=DataOrigin.LIVE
            )
        ]
    )
    res2 = svc.ingest_gps_batch(b2)
    assert res2.rejected == 1
    assert "IMPOSSIBLE_SPEED_OR_GPS_JUMP" in res2.results[0].reason

def test_gps_signal_recovery_and_off_route_tracking():
    svc = IngestionService()
    init_recoveries = svc.stats.get("signal_recoveries", 0)
    init_off_route = svc.stats.get("off_route_events", 0)

    t0 = datetime.now(timezone.utc) - timedelta(seconds=120)
    b1 = GpsTelemetryBatchRequest(
        feed_id="TEST_FEED",
        records=[
            GpsTelemetryRecord(
                bus_number="14A",
                latitude=9.9922,
                longitude=76.2974,
                timestamp=t0.isoformat(),
                sequence_number=10,
                data_origin=DataOrigin.LIVE
            )
        ]
    )
    svc.ingest_gps_batch(b1)

    # Next ping arrives after 45 seconds (> 30s gap = recovery)
    t1 = t0 + timedelta(seconds=45)
    b2 = GpsTelemetryBatchRequest(
        feed_id="TEST_FEED",
        records=[
            GpsTelemetryRecord(
                bus_number="14A",
                latitude=9.9925,
                longitude=76.2980,
                timestamp=t1.isoformat(),
                sequence_number=11,
                data_origin=DataOrigin.LIVE
            )
        ]
    )
    svc.ingest_gps_batch(b2)
    assert svc.stats["signal_recoveries"] > init_recoveries

    # Off-route ping (>500m off corridor, within physical speed 60s @ 66 km/h)
    t2 = t1 + timedelta(seconds=60)
    b_off = GpsTelemetryBatchRequest(
        feed_id="TEST_FEED",
        records=[
            GpsTelemetryRecord(
                bus_number="14A",
                latitude=9.9850, # Off corridor (>500m deviation from Kaloor & MG Road waypoints)
                longitude=76.3050,
                speed_kmh=45.0,
                timestamp=t2.isoformat(),
                sequence_number=12,
                data_origin=DataOrigin.LIVE
            )
        ]
    )
    res_off = svc.ingest_gps_batch(b_off)
    assert res_off.accepted == 1
    assert "WARNING_OFF_ROUTE" in res_off.results[0].reason
    assert svc.stats["off_route_events"] > init_off_route

# -----------------------------------------------------------------------------
# 3. CV Ground-Truth Validation Metrics
# -----------------------------------------------------------------------------

def test_cv_pipeline_evaluation_metrics():
    report = cv_evaluator.run_full_evaluation(seed=42)
    assert isinstance(report, CVEvaluationReport)
    assert report.total_scenarios_evaluated == 6
    assert report.overall_zero_biometrics_passed is True

    # Error metrics
    assert 0.0 < report.aggregate_smoothed_mae < 3.0
    assert 0.0 < report.aggregate_smoothed_rmse < 4.0
    assert 0.0 < report.aggregate_mape_pct < 15.0

    # Detection quality
    assert 0.90 <= report.aggregate_precision <= 1.0
    assert 0.85 <= report.aggregate_recall <= 1.0
    assert 0.90 <= report.aggregate_f1_score <= 1.0

    # Latency & throughput
    assert 10.0 <= report.aggregate_inference_ms <= 40.0
    assert report.aggregate_p95_inference_ms >= report.aggregate_inference_ms
    assert report.aggregate_fps >= 25.0
    assert report.stabilization_improvement_pct > 15.0

    # Scenario-level metrics
    for s in report.scenario_results:
        assert s.precision >= 0.80
        assert s.recall >= 0.70
        assert s.p95_inference_ms > 0.0
        assert s.mape_pct > 0.0
        assert s.zero_biometrics_verified is True

# -----------------------------------------------------------------------------
# 4. Demand Forecasting Chronological Validation & Baselines
# -----------------------------------------------------------------------------

def test_demand_forecasting_baselines_and_residuals():
    eval_resp = demand_forecaster.get_pilot_forecasting_evaluation()
    assert isinstance(eval_resp, PilotForecastingEvaluationResponse)
    assert eval_resp.train_split_pct == 70.0
    assert eval_resp.validation_split_pct == 15.0
    assert eval_resp.test_split_pct == 15.0

    # Check overall metrics contain both persistence and SMA baselines
    for metric in eval_resp.overall_metrics:
        assert metric.model_mae > 0.0
        assert metric.model_rmse > 0.0
        assert metric.baseline_mae > 0.0
        assert metric.sma_baseline_mae is not None
        assert metric.sma_baseline_mae > 0.0
        assert metric.sma_baseline_rmse is not None
        assert metric.mean_residual is not None
        assert metric.residual_std is not None
        assert metric.residual_skewness is not None

    # Check feature importance
    feat_imp = eval_resp.feature_importance
    assert feat_imp is not None
    assert len(feat_imp) == 10
    assert "current_occupancy" in feat_imp
    assert "corridor_density" in feat_imp
    assert math.isclose(sum(feat_imp.values()), 1.0, abs_tol=0.05)

    # Check overfitting risk assessment
    assert eval_resp.overfitting_risk_assessment is not None
    assert "LOW" in eval_resp.overfitting_risk_assessment

    # Check residual distributions
    assert eval_resp.residual_distribution is not None
    assert "+15m" in eval_resp.residual_distribution
    assert "+30m" in eval_resp.residual_distribution
    assert "+60m" in eval_resp.residual_distribution

# -----------------------------------------------------------------------------
# 5. Recommendation Engine Analytics & Strictly Advisory Mode
# -----------------------------------------------------------------------------

def test_recommendation_analytics_and_advisory_mode():
    engine = recommendation_engine
    
    # Generate a journey plan to populate delta tracking
    plan = engine.plan_journey(
        origin="Kaloor Metro Station, Kochi",
        destination="Vyttila Mobility Hub",
        preference="balanced"
    )
    assert plan.recommended_bus.is_recommended is True

    # Get analytics summary
    analytics = engine.get_analytics_summary()
    assert analytics.advisory_mode_enforced is True
    assert analytics.recommendation_availability_pct == 100.0
    assert analytics.avg_waiting_time_delta_mins is not None
    assert analytics.avg_waiting_time_delta_mins >= 0.0
    assert analytics.predicted_vs_observed_occupancy_delta is not None

# -----------------------------------------------------------------------------
# 6. Comprehensive Pilot Monitoring Summary
# -----------------------------------------------------------------------------

def test_pilot_monitoring_summary_enrichment():
    svc = IngestionService()
    summary = svc.get_pilot_monitoring_summary()
    assert isinstance(summary, PilotMonitoringDashboardResponse)

    # Check enrichment fields
    assert summary.forecaster_evaluation is not None
    assert "model_version" in summary.forecaster_evaluation
    assert summary.cv_metrics_summary is not None
    assert summary.cv_metrics_summary["zero_biometrics_passed"] is True
    assert summary.cv_metrics_summary["precision"] >= 0.90
    assert summary.recommendation_analytics_summary is not None
    assert summary.recommendation_analytics_summary["advisory_mode_enforced"] is True

    assert summary.failed_ingestion_events_count >= 0
    assert summary.off_route_alerts_count >= 0
    assert summary.signal_recoveries_count >= 0
    assert summary.privacy_standard == "PERSON_COUNTING_ONLY_NO_BIOMETRICS"
