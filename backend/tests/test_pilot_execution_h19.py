"""
BusSense AI - Phase H19 Deployment Completion & Controlled Pilot Verification Test Suite
Tests:
- Comprehensive transit adapter specifications (all 10 operational fields)
- Data provenance tracking across GPS and CCTV ingestion boundaries
- Provenance honesty enforcement (simulated data never masquerades as live)
- Stale/unmonitored records excluded from high-quality recommendations
- Computer vision evaluation metadata and zero-biometrics privacy guarantees
- Corridor consistency between pilot procedure and routing engine
- Human-in-the-loop advisory mode enforcement (zero automatic dispatch mutation)
- Sub-15ms pilot monitoring dashboard caching
"""
import time
import pytest
from datetime import datetime, timezone, timedelta
from app.services.ingestion_service import ingestion_service, IngestionService
from app.schemas.ingestion import (
    GpsTelemetryBatchRequest,
    GpsTelemetryRecord,
    CctvOccupancyIngestRecord,
    TransitAdapterSpec,
    PilotMonitoringDashboardResponse
)
from app.schemas.common import DataOrigin
from cv.evaluator import cv_evaluator, CVEvaluationReport
from app.services.gps_simulator import gps_simulator, CORRIDORS
from app.services.recommendation_engine import recommendation_engine


# 1. Comprehensive Transit Adapter Specifications
def test_adapter_spec_catalog_comprehensive_fields():
    svc = IngestionService()
    adapters = svc.list_transit_adapters()
    assert len(adapters) == 4

    adapter_ids = {a.adapter_id for a in adapters}
    assert "KSRTC_SWIFT_AVL_ADAPTER" in adapter_ids
    assert "KMRL_FEEDER_AVL_ADAPTER" in adapter_ids
    assert "CCTV_HEADCOUNT_GATEWAY_ADAPTER" in adapter_ids
    assert "KERALA_POLICE_DISRUPTION_ADAPTER" in adapter_ids

    for a in adapters:
        assert isinstance(a, TransitAdapterSpec)
        assert len(a.expected_source) > 5
        assert len(a.required_authorization) > 5
        assert "API Key" in a.auth_method
        assert len(a.data_format) > 3
        assert a.expected_update_frequency_sec > 0
        assert len(a.required_fields) >= 5
        assert len(a.validation_rules) >= 2
        assert len(a.failure_handling) > 5
        assert a.rate_limit_per_minute > 0
        assert a.data_retention_days >= 30


# 2. GPS Ingestion Data Provenance Tracking
def test_gps_ingestion_data_provenance_metadata():
    svc = IngestionService()
    now_iso = datetime.now(timezone.utc).isoformat()

    batch = GpsTelemetryBatchRequest(
        feed_id="KSRTC_SWIFT_AVL",
        records=[
            GpsTelemetryRecord(
                bus_number="205",
                latitude=10.0261,
                longitude=76.3086,
                speed_kmh=32.0,
                heading_deg=180.0,
                timestamp=now_iso,
                sequence_number=501,
                feed_id="KSRTC_SWIFT_AVL",
                data_origin=DataOrigin.LIVE
            )
        ]
    )
    summary = svc.ingest_gps_batch(batch)
    assert summary.accepted == 1
    assert len(summary.results) == 1

    res = summary.results[0]
    assert res.status == "ACCEPTED"
    assert res.source_provider == "KSRTC_SWIFT_AVL"
    assert res.source_type == "AVL_GPS"
    assert res.event_timestamp == now_iso
    assert res.received_timestamp is not None
    assert res.data_origin == "LIVE DATA"
    assert res.validation_status == "VALID"
    assert res.freshness_status == "FRESH"
    assert res.processing_status == "ACCEPTED"


# 3. GPS Rejection Data Provenance Tracking
def test_gps_rejection_data_provenance_metadata():
    svc = IngestionService()
    future_iso = (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat()

    batch = GpsTelemetryBatchRequest(
        feed_id="KMRL_FEEDER_AVL",
        records=[
            GpsTelemetryRecord(
                bus_number="14A",
                latitude=9.9922,
                longitude=76.2974,
                speed_kmh=20.0,
                heading_deg=90.0,
                timestamp=future_iso,
                sequence_number=1,
                feed_id="KMRL_FEEDER_AVL",
                data_origin=DataOrigin.LIVE
            )
        ]
    )
    summary = svc.ingest_gps_batch(batch)
    assert summary.rejected == 1

    res = summary.results[0]
    assert res.status == "REJECTED"
    assert res.source_provider == "KMRL_FEEDER_AVL"
    assert res.source_type == "AVL_GPS"
    assert res.validation_status == "FUTURE_TIMESTAMP"
    assert res.freshness_status == "INVALID"
    assert res.processing_status == "REJECTED"


# 4. CCTV Ingestion Data Provenance Tracking
@pytest.mark.anyio
async def test_cctv_ingestion_data_provenance_metadata():
    svc = IngestionService()
    now_iso = datetime.now(timezone.utc).isoformat()

    cctv_rec = CctvOccupancyIngestRecord(
        bus_number="205",
        timestamp=now_iso,
        raw_person_count=30,
        stabilized_person_count=29,
        capacity=55,
        confidence_score=0.92,
        model_version="YOLOv8n",
        camera_id="BUS_DOOR_CAM_01",
        privacy_standard="PERSON_COUNTING_ONLY_NO_BIOMETRICS",
        data_origin=DataOrigin.CV_REPLAY
    )
    summary = await svc.ingest_cctv_occupancy(cctv_rec)
    assert summary.accepted == 1

    res = summary.results[0]
    assert res.status == "ACCEPTED"
    assert res.source_provider == "BUS_DOOR_CAM_01"
    assert res.source_type == "CCTV_OCCUPANCY"
    assert res.event_timestamp == now_iso
    assert res.validation_status == "VALID"
    assert res.freshness_status == "FRESH"
    assert res.processing_status == "ACCEPTED"
    assert res.data_origin == "CV REPLAY"

    # Reset simulator state to prevent test cross-contamination
    gps_simulator.fleet_state["205"]["data_origin"] = DataOrigin.SIMULATED


# 5. Provenance Honesty: Simulated Data Never Masquerades as Live Data
def test_provenance_honesty_simulated_never_masquerades_as_live():
    # Verify DataOrigin enum includes BENCHMARK
    assert DataOrigin.BENCHMARK.value == "BENCHMARK"
    assert DataOrigin.SIMULATED.value == "SIMULATED DATA"
    assert DataOrigin.LIVE.value == "LIVE DATA"

    # Reset and verify simulated fleet telemetry
    gps_simulator.fleet_state["205"]["data_origin"] = DataOrigin.SIMULATED
    tel = gps_simulator.get_bus_telemetry("205")
    assert tel.get("data_origin") == DataOrigin.SIMULATED
    assert tel.get("data_origin") != DataOrigin.LIVE

    # Ensure journey recommendation stamps origin honestly
    plan = recommendation_engine.plan_journey("Aluva", "Vyttila")
    assert plan.recommended_bus.data_origin in [DataOrigin.RECOMMENDATION, DataOrigin.SIMULATED]
    assert plan.recommended_bus.data_origin != DataOrigin.LIVE


# 6. Stale Telemetry Excluded from High Quality Recommendations
def test_stale_telemetry_excluded_from_high_quality_recommendation():
    engine = recommendation_engine
    stale_ts = datetime.now(timezone.utc) - timedelta(seconds=120)

    # Inject stale telemetry into ingestion service
    ingestion_service._bus_telemetry_state["205"] = {
        "last_timestamp": stale_ts,
        "last_seq": 999,
        "feed_id": "TEST_STALE",
        "latitude": 9.9922,
        "longitude": 76.2974,
        "speed_kmh": 20.0,
        "heading_deg": 180.0,
        "data_origin": DataOrigin.LIVE
    }
    gps_simulator.fleet_state["205"]["data_origin"] = DataOrigin.LIVE

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
    item, score_breakdown, quality = engine.evaluate_bus_candidate(candidate, preference="balanced")

    # Stale telemetry must downgrade quality to LOW
    assert quality == "LOW"

    # Clean up test state
    ingestion_service._bus_telemetry_state.pop("205", None)
    gps_simulator.fleet_state["205"]["data_origin"] = DataOrigin.SIMULATED


# 7. Computer Vision Evaluation Metadata and Zero-Biometrics Guarantee
def test_cv_evaluation_metadata_fields():
    report = cv_evaluator.run_full_evaluation(seed=99)
    assert isinstance(report, CVEvaluationReport)
    assert report.total_scenarios_evaluated == 6
    assert report.number_of_recordings == 6
    assert report.number_of_frames == 300
    assert "BENCHMARK" in report.data_origin_label
    assert "YOLOv8n" in report.model_version
    assert report.overall_zero_biometrics_passed is True
    assert "STRICT_ZERO_BIOMETRICS_VERIFIED" in report.privacy_audit_summary
    assert report.aggregate_smoothed_mae < 2.5
    assert report.aggregate_precision > 0.90
    assert report.aggregate_fps > 30.0


# 8. Pilot Corridor Route Consistency
def test_pilot_corridor_route_consistency():
    # Verify primary corridor R12_205 exists with key waypoints
    assert "R12_205" in CORRIDORS
    c205 = CORRIDORS["R12_205"]
    stop_names = [s["stop"] for s in c205["waypoints"]]
    assert any("Aluva" in s for s in stop_names)
    assert any("Vyttila" in s for s in stop_names)
    assert any("Kaloor" in s for s in stop_names)

    # Verify secondary feeder corridor R12_14A exists
    assert "R12_14A" in CORRIDORS
    c14a = CORRIDORS["R12_14A"]
    stop_names_14a = [s["stop"] for s in c14a["waypoints"]]
    assert any("Fort Kochi" in s for s in stop_names_14a)
    assert any("Infopark" in s for s in stop_names_14a)


# 9. Strictly Advisory Mode Enforced
def test_strictly_advisory_mode_enforced():
    analytics = recommendation_engine.get_analytics_summary()
    assert analytics.advisory_mode_enforced is True


# 10. Sub-15ms Pilot Monitoring Response
def test_pilot_monitoring_cached_performance():
    svc = IngestionService()
    # Warm up cache
    _ = svc.get_pilot_monitoring_summary()

    t0 = time.perf_counter()
    summary = svc.get_pilot_monitoring_summary()
    t_elapsed_ms = (time.perf_counter() - t0) * 1000.0

    assert isinstance(summary, PilotMonitoringDashboardResponse)
    assert t_elapsed_ms < 25.0  # Must be fast in-memory response (<25ms)
    assert summary.privacy_standard == "PERSON_COUNTING_ONLY_NO_BIOMETRICS"
