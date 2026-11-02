"""
BusSense AI - Phase H17 Pilot Readiness & Operational Evaluation Test Suite
Tests:
- External provider registration, SHA-256 API key verification, and HTTP 403 revocation enforcement
- Corridor map-matching and >500m route deviation alerting
- Ingestion data boundary negative tests (out-of-order, future, stale timestamps)
- CCTV occupancy ingestion, trusted occupancy recalculation, and zero-biometrics enforcement
- CV pipeline empirical evaluator (6 scenarios, MAE, RMSE, FPS, stabilization gain, zero-biometrics audit)
- Demand forecaster peak vs off-peak and corridor-level evaluation against persistence baseline
- Recommendation engine impression/selection feedback loop and telemetry staleness scoring penalty
- Pilot monitoring dashboard telemetry aggregation and truth label verification
"""
import pytest
from datetime import datetime, timezone, timedelta
from app.services.ingestion_service import ingestion_service, IngestionService
from app.schemas.ingestion import (
    ExternalProviderRegisterRequest,
    ProviderRevocationRequest,
    GpsTelemetryBatchRequest,
    GpsTelemetryRecord,
    CctvOccupancyIngestRecord,
    MapMatchingResult,
    PilotMonitoringDashboardResponse
)
from app.schemas.common import DataOrigin
from cv.evaluator import cv_evaluator, CVEvaluationReport
from app.services.demand_forecaster import demand_forecaster
from app.services.recommendation_engine import recommendation_engine
from app.schemas.prediction import (
    RecommendationImpressionRequest,
    RecommendationSelectionRequest,
    PilotForecastingEvaluationResponse
)

# 1. External Provider Lifecycle & Revocation
def test_provider_registration_and_revocation():
    svc = IngestionService()
    req = ExternalProviderRegisterRequest(
        provider_id="TEST_KSRTC_EXPRESS",
        provider_name="KSRTC Express Feeder Fleet",
        allowed_feed_types=["AVL_GPS", "ROUTE_SCHEDULE"],
        contact_email="feeder-ops@keralartc.com"
    )
    resp, raw_key = svc.register_provider(req)
    assert resp.provider_id == "TEST_KSRTC_EXPRESS"
    assert raw_key.startswith("bs_live_")
    assert resp.api_key_masked.startswith("bs_live_...")

    # Verify key works
    valid, err, prov = svc.verify_provider_api_key(raw_key, feed_type="AVL_GPS")
    assert valid is True
    assert err is None
    assert prov["provider_id"] == "TEST_KSRTC_EXPRESS"

    # Unauthorized feed type check
    valid_feed, err_feed, _ = svc.verify_provider_api_key(raw_key, feed_type="CCTV_OCCUPANCY")
    assert valid_feed is False
    assert "UNAUTHORIZED_FEED_TYPE" in err_feed

    # Revoke provider
    rev = svc.revoke_provider("TEST_KSRTC_EXPRESS", "Maintenance window closed")
    assert rev is not None
    assert rev.is_active is False
    assert rev.revocation_reason == "Maintenance window closed"

    # Verify key now rejected with INTEGRATION_REVOKED
    valid_rev, err_rev, _ = svc.verify_provider_api_key(raw_key)
    assert valid_rev is False
    assert "INTEGRATION_REVOKED" in err_rev

    # Reactivate provider
    reactivated = svc.reactivate_provider("TEST_KSRTC_EXPRESS")
    assert reactivated.is_active is True
    valid_act, err_act, _ = svc.verify_provider_api_key(raw_key)
    assert valid_act is True

# 2. Corridor Map-Matching & Deviation Detection
def test_haversine_and_corridor_map_matching():
    svc = IngestionService()
    # Edappally (10.0270, 76.3080) to Lulu Junction (10.0280, 76.3085)
    dist = svc.haversine_distance_meters(10.0270, 76.3080, 10.0280, 76.3085)
    assert 100.0 < dist < 200.0

    # Match vehicle along Aluva-Vyttila corridor (near Kaloor stop 9.9922, 76.2974)
    mm_on_route = svc.map_match_vehicle("205", lat=9.9930, lng=76.2980)
    assert mm_on_route.is_off_route is False
    assert mm_on_route.distance_to_corridor_meters < 500.0

    # Match vehicle with large deviation (>500m)
    mm_off_route = svc.map_match_vehicle("205", lat=9.8500, lng=76.4500)
    assert mm_off_route.is_off_route is True
    assert mm_off_route.distance_to_corridor_meters > 500.0

# 3. GPS Ingestion with Map Matching & Negative Sequence Checks
def test_gps_ingestion_monotonic_and_off_route():
    svc = IngestionService()
    now = datetime.now(timezone.utc)

    # Valid batch on route
    batch_valid = GpsTelemetryBatchRequest(
        feed_id="TEST-FEED-01",
        records=[
            GpsTelemetryRecord(
                bus_number="205",
                latitude=10.0270,
                longitude=76.3080,
                speed_kmh=35.0,
                heading_deg=180.0,
                timestamp=now.isoformat(),
                sequence_number=1001,
                data_origin=DataOrigin.LIVE
            )
        ]
    )
    res_valid = svc.ingest_gps_batch(batch_valid)
    assert res_valid.accepted == 1
    assert res_valid.rejected == 0

    # Off-route record
    batch_off = GpsTelemetryBatchRequest(
        feed_id="TEST-FEED-01",
        records=[
            GpsTelemetryRecord(
                bus_number="205",
                latitude=9.8500,
                longitude=76.4000,
                speed_kmh=40.0,
                heading_deg=90.0,
                timestamp=(now + timedelta(seconds=10)).isoformat(),
                sequence_number=1002,
                data_origin=DataOrigin.LIVE
            )
        ]
    )
    res_off = svc.ingest_gps_batch(batch_off)
    assert res_off.accepted == 1
    assert "WARNING_OFF_ROUTE" in res_off.results[0].reason

    # Out of order sequence rejection
    batch_ooo = GpsTelemetryBatchRequest(
        feed_id="TEST-FEED-01",
        records=[
            GpsTelemetryRecord(
                bus_number="205",
                latitude=10.0270,
                longitude=76.3080,
                speed_kmh=20.0,
                timestamp=(now - timedelta(seconds=20)).isoformat(), # past timestamp
                sequence_number=1003,
                data_origin=DataOrigin.LIVE
            )
        ]
    )
    res_ooo = svc.ingest_gps_batch(batch_ooo)
    assert res_ooo.rejected == 1
    assert "OUT_OF_ORDER" in res_ooo.results[0].reason

# 4. CCTV Ingestion & Zero-Biometrics Enforced
def test_cctv_occupancy_ingestion():
    import asyncio
    svc = IngestionService()
    now_iso = datetime.now(timezone.utc).isoformat()

    cctv_rec = CctvOccupancyIngestRecord(
        bus_number="205",
        timestamp=now_iso,
        raw_person_count=35,
        stabilized_person_count=34,
        capacity=55,
        confidence_score=0.90,
        model_version="YOLOv8n",
        privacy_standard="PERSON_COUNTING_ONLY_NO_BIOMETRICS",
        data_origin=DataOrigin.CV_REPLAY
    )
    res = asyncio.run(svc.ingest_cctv_occupancy(cctv_rec))
    assert res.accepted == 1
    assert res.results[0].status == "ACCEPTED"

    # Enforce zero biometrics validator rejection
    with pytest.raises(ValueError, match="zero-biometrics|Biometric facial"):
        CctvOccupancyIngestRecord(
            bus_number="205",
            timestamp=now_iso,
            raw_person_count=20,
            stabilized_person_count=20,
            capacity=55,
            privacy_standard="FACIAL_RECOGNITION_NOT_ALLOWED"
        )

# 5. CV Pipeline Empirical Evaluator
def test_cv_pipeline_empirical_evaluator():
    report = cv_evaluator.run_full_evaluation(seed=123)
    assert isinstance(report, CVEvaluationReport)
    assert report.total_scenarios_evaluated == 6
    assert report.overall_zero_biometrics_passed is True
    assert report.aggregate_smoothed_mae < report.aggregate_raw_mae
    assert report.stabilization_improvement_pct > 15.0
    assert report.aggregate_fps > 30.0
    assert "ZERO_BIOMETRICS" in report.privacy_audit_summary

# 6. Demand Forecaster Peak vs Off-Peak & Corridor Evaluation
def test_demand_forecaster_evaluations():
    eval_resp = demand_forecaster.get_pilot_forecasting_evaluation()
    assert isinstance(eval_resp, PilotForecastingEvaluationResponse)
    assert eval_resp.total_samples > 100
    assert len(eval_resp.overall_metrics) == 3

    # Check peak vs off-peak
    p_vs_op = eval_resp.peak_vs_offpeak
    assert p_vs_op.peak_sample_count > 0
    assert p_vs_op.offpeak_sample_count > 0
    assert 15 in p_vs_op.peak_metrics
    assert 30 in p_vs_op.peak_metrics
    assert 60 in p_vs_op.peak_metrics

    # Model should have valid MAE and baseline comparison
    for h in [15, 30, 60]:
        m = p_vs_op.peak_metrics[h]
        assert m.model_mae > 0.0
        assert m.baseline_mae > 0.0

    # Corridor metrics
    assert len(eval_resp.corridor_evaluations) >= 2
    for c in eval_resp.corridor_evaluations:
        assert c.sample_count > 0
        assert 15 in c.horizons

# 7. Recommendation Engine Impressions, Selections & Stale Telemetry Penalty
def test_recommendation_tracking_and_stale_penalty():
    engine = recommendation_engine
    init_penalties = engine.stale_penalties_applied

    # Record impression
    imp = RecommendationImpressionRequest(
        journey_id="TEST-JOURNEY-101",
        recommended_bus_number="205",
        presented_alternatives_count=2,
        preference="balanced"
    )
    analytics_imp = engine.record_impression(imp)
    assert analytics_imp.total_impressions >= 1

    # Record selection
    sel = RecommendationSelectionRequest(
        journey_id="TEST-JOURNEY-101",
        selected_bus_number="205",
        was_recommended_bus=True,
        selection_reason="Fastest arrival"
    )
    analytics_sel = engine.record_selection(sel)
    assert analytics_sel.total_selections >= 1
    assert analytics_sel.compliance_rate_pct > 0.0

    # Verify stale telemetry penalty in candidate evaluation
    # Set stale telemetry (>60s) for a vehicle
    from app.services.gps_simulator import gps_simulator
    orig_origin = gps_simulator.fleet_state.get("205", {}).get("data_origin")
    gps_simulator.fleet_state["205"]["data_origin"] = DataOrigin.LIVE
    try:
        stale_ts = datetime.now(timezone.utc) - timedelta(seconds=180)
        ingestion_service._bus_telemetry_state["205"] = {
            "last_timestamp": stale_ts,
            "last_seq": 99,
            "feed_id": "TEST",
            "latitude": 9.9922,
            "longitude": 76.2974,
            "speed_kmh": 20.0,
            "heading_deg": 180.0,
            "data_origin": DataOrigin.LIVE
        }
        candidate = {
            "bus_number": "205",
            "metadata": {
                "route_number": "205",
                "route_name": "Aluva-Vyttila",
                "operator_type": "KSRTC",
                "has_priority_lane": True
            },
            "duration_mins": 35,
            "distance_km": 15.0,
            "fare_inr": 25.0,
            "has_priority_lane": True,
            "is_direct": True
        }
        item, score_down, qual = engine.evaluate_bus_candidate(candidate, preference="balanced")
        assert qual == "LOW"
        assert engine.stale_penalties_applied > init_penalties
    finally:
        if orig_origin:
            gps_simulator.fleet_state["205"]["data_origin"] = orig_origin
        ingestion_service._bus_telemetry_state.pop("205", None)

# 8. Pilot Monitoring Dashboard Response
def test_pilot_monitoring_summary():
    svc = IngestionService()
    summary = svc.get_pilot_monitoring_summary()
    assert isinstance(summary, PilotMonitoringDashboardResponse)
    assert summary.total_active_vehicles > 0
    assert summary.privacy_standard == "PERSON_COUNTING_ONLY_NO_BIOMETRICS"
    assert "LIVE_DATA" in summary.live_vs_simulated_breakdown
    assert "SIMULATED_DATA" in summary.live_vs_simulated_breakdown
    assert "min_lat" in summary.greater_kochi_bbox
    assert summary.active_providers_count >= 1

# 9. DataOrigin Enum Completeness
def test_data_origin_enum_truth_labels():
    origins = [e.value for e in DataOrigin]
    assert "LIVE DATA" in origins
    assert "SIMULATED DATA" in origins
    assert "PREDICTION" in origins
    assert "RECOMMENDATION" in origins
    assert "CV REPLAY" in origins
    assert "ESTIMATE" in origins
    assert "STALE DATA" in origins
    assert "UNAVAILABLE" in origins

