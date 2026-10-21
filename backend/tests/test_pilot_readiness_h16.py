"""
BusSense AI - Phase H16 Pilot Readiness & Real-World Data Ingestion Tests
Validates:
- Transit Data Ingestion Boundary (/api/ingest/*)
- Greater Kochi spatial coordinate bounds (Lat [9.80, 10.35], Lng [76.15, 76.55])
- Impossible speed rejection (>120 km/h)
- Timestamp sanity (future skew >5m rejection, stale >15m rejection)
- Monotonic sequencing and duplicate telemetry detection
- Strict zero-biometrics privacy enforcement
- CCTV aggregate occupancy recalculation
- Ingestion health and vehicle staleness monitoring
- Computer vision offline replay and temporal smoothing safety
- Demand forecasting evaluation metrics against persistence baseline
- Multi-factor recommendation engine edge cases and explainability
"""
import pytest
from datetime import datetime, timezone, timedelta
from fastapi.testclient import TestClient
from app.main import app
from app.core.config import settings
from app.core.security import create_access_token
from app.schemas.common import DataOrigin, CrowdLevel
from app.services.ingestion_service import ingestion_service
from app.services.gps_simulator import gps_simulator
from app.services.demand_forecaster import demand_forecaster
from app.services.recommendation_engine import recommendation_engine
try:
    from backend.cv.smoothing import TemporalStabilizer
    from backend.cv.occupancy import OccupancyCalculator
    from backend.cv.detector import YOLOPersonDetector
except ImportError:
    from cv.smoothing import TemporalStabilizer
    from cv.occupancy import OccupancyCalculator
    from cv.detector import YOLOPersonDetector

client = TestClient(app, raise_server_exceptions=False)

def create_auth_headers(role: str = "AUTHORITY") -> dict:
    token = create_access_token({
        "sub": "00000000-0000-0000-0000-000000000099",
        "email": f"{role.lower()}@bussense.kerala.gov.in",
        "role": role
    })
    return {"Authorization": f"Bearer {token}"}

# =========================================================================
# 1. Ingestion Boundary RBAC & Security Tests
# =========================================================================

def test_ingest_endpoints_reject_unauthenticated():
    """Ingest endpoints must return 401 Unauthorized without auth headers"""
    resp = client.post("/api/ingest/gps", json={"feed_id": "TEST", "records": []})
    assert resp.status_code == 401
    assert "Unauthorized" in resp.json()["detail"]

    resp_occ = client.post("/api/ingest/cctv-occupancy", json={})
    assert resp_occ.status_code == 401

    resp_hlth = client.get("/api/ingest/health")
    assert resp_hlth.status_code == 401

def test_ingest_endpoints_reject_passenger_and_conductor():
    """Only AUTHORITY or ADMIN roles can ingest transit data"""
    passenger_headers = create_auth_headers(role="PASSENGER")
    conductor_headers = create_auth_headers(role="DRIVER_CONDUCTOR")

    resp = client.get("/api/ingest/health", headers=passenger_headers)
    assert resp.status_code == 403
    assert "AUTHORITY or ADMIN" in resp.json()["detail"]

    resp2 = client.get("/api/ingest/health", headers=conductor_headers)
    assert resp2.status_code == 403

def test_ingest_endpoints_accept_internal_secret():
    """X-Internal-Secret matching SECRET_KEY is accepted for backend gateways"""
    headers = {"X-Internal-Secret": settings.SECRET_KEY}
    resp = client.get("/api/ingest/health", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["service"] == "transit_ingestion_boundary"

# =========================================================================
# 2. GPS / AVL Telemetry Ingestion & Spatial Bounds Tests
# =========================================================================

def test_gps_ingest_rejects_out_of_bounds_coordinates():
    """Rejects coordinates outside Greater Kochi bounding box [9.80-10.35 N, 76.15-76.55 E]"""
    headers = create_auth_headers(role="AUTHORITY")
    now_iso = datetime.now(timezone.utc).isoformat()

    # Latitude too far north (e.g. Kasaragod: 12.51 N)
    payload_north = {
        "feed_id": "AVL_TEST_FEED",
        "records": [{
            "bus_number": "205",
            "latitude": 12.5100,
            "longitude": 76.3000,
            "speed_kmh": 30.0,
            "heading_deg": 180.0,
            "timestamp": now_iso
        }]
    }
    resp = client.post("/api/ingest/gps", json=payload_north, headers=headers)
    assert resp.status_code == 422 # Pydantic field_validator rejects immediately

    # Longitude too far west (Arabian Sea: 75.50 E)
    payload_west = {
        "feed_id": "AVL_TEST_FEED",
        "records": [{
            "bus_number": "205",
            "latitude": 9.9922,
            "longitude": 75.5000,
            "speed_kmh": 30.0,
            "heading_deg": 180.0,
            "timestamp": now_iso
        }]
    }
    resp2 = client.post("/api/ingest/gps", json=payload_west, headers=headers)
    assert resp2.status_code == 422

def test_gps_ingest_rejects_impossible_speed():
    """Rejects speeds > 120 km/h on urban Kerala corridors"""
    headers = create_auth_headers(role="AUTHORITY")
    now_iso = datetime.now(timezone.utc).isoformat()

    payload = {
        "feed_id": "AVL_TEST_FEED",
        "records": [{
            "bus_number": "205",
            "latitude": 9.9922,
            "longitude": 76.2974,
            "speed_kmh": 185.0, # Impossible speed
            "heading_deg": 90.0,
            "timestamp": now_iso
        }]
    }
    resp = client.post("/api/ingest/gps", json=payload, headers=headers)
    assert resp.status_code == 422

def test_gps_ingest_rejects_future_timestamps():
    """Rejects timestamps more than 5 minutes ahead of server time"""
    headers = create_auth_headers(role="AUTHORITY")
    future_time = (datetime.now(timezone.utc) + timedelta(minutes=15)).isoformat()

    payload = {
        "feed_id": "AVL_TEST_FEED",
        "records": [{
            "bus_number": "205",
            "latitude": 9.9922,
            "longitude": 76.2974,
            "speed_kmh": 25.0,
            "heading_deg": 90.0,
            "timestamp": future_time,
            "sequence_number": 9001
        }]
    }
    resp = client.post("/api/ingest/gps", json=payload, headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["rejected"] == 1
    assert "FUTURE_TIMESTAMP" in data["results"][0]["reason"]

def test_gps_ingest_rejects_stale_records_unless_historical():
    """Rejects records older than 15 minutes unless is_historical=True"""
    headers = create_auth_headers(role="AUTHORITY")
    stale_time = (datetime.now(timezone.utc) - timedelta(minutes=45)).isoformat()

    # 1. Stale with is_historical=False -> REJECTED
    payload_stale = {
        "feed_id": "AVL_TEST_FEED",
        "records": [{
            "bus_number": "205",
            "latitude": 9.9922,
            "longitude": 76.2974,
            "speed_kmh": 20.0,
            "heading_deg": 90.0,
            "timestamp": stale_time,
            "is_historical": False
        }]
    }
    resp = client.post("/api/ingest/gps", json=payload_stale, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["rejected"] == 1
    assert "STALE_TELEMETRY" in resp.json()["data"]["results"][0]["reason"]

    # 2. Stale with is_historical=True -> ACCEPTED as HISTORICAL
    payload_hist = {
        "feed_id": "AVL_HISTORICAL_FEED",
        "records": [{
            "bus_number": "205",
            "latitude": 9.9922,
            "longitude": 76.2974,
            "speed_kmh": 20.0,
            "heading_deg": 90.0,
            "timestamp": stale_time,
            "is_historical": True
        }]
    }
    resp2 = client.post("/api/ingest/gps", json=payload_hist, headers=headers)
    assert resp2.status_code == 200
    assert resp2.json()["data"]["accepted"] == 1
    assert resp2.json()["data"]["freshness_status"] == "HISTORICAL"

def test_gps_ingest_detects_monotonic_sequence_and_duplicates():
    """Detects duplicate sequence numbers and out-of-order timestamps"""
    headers = create_auth_headers(role="AUTHORITY")
    base_time = datetime.now(timezone.utc) - timedelta(seconds=60)

    # Packet 1: Seq 100
    t1 = (base_time + timedelta(seconds=1)).isoformat()
    resp1 = client.post("/api/ingest/gps", json={
        "feed_id": "AVL_MONO_TEST",
        "records": [{
            "bus_number": "TEST_BUS_01",
            "latitude": 9.9922,
            "longitude": 76.2974,
            "speed_kmh": 30.0,
            "heading_deg": 90.0,
            "timestamp": t1,
            "sequence_number": 100
        }]
    }, headers=headers)
    assert resp1.json()["data"]["accepted"] == 1

    # Packet 2: Seq 99 (Out-of-order sequence) -> REJECTED
    t2 = (base_time + timedelta(seconds=5)).isoformat()
    resp2 = client.post("/api/ingest/gps", json={
        "feed_id": "AVL_MONO_TEST",
        "records": [{
            "bus_number": "TEST_BUS_01",
            "latitude": 9.9930,
            "longitude": 76.2980,
            "speed_kmh": 32.0,
            "heading_deg": 90.0,
            "timestamp": t2,
            "sequence_number": 99
        }]
    }, headers=headers)
    assert resp2.json()["data"]["rejected"] == 1
    assert "DUPLICATE_OR_OUT_OF_ORDER_SEQUENCE" in resp2.json()["data"]["results"][0]["reason"]

# =========================================================================
# 3. CCTV Occupancy Ingestion & Zero-Biometrics Privacy Tests
# =========================================================================

def test_cctv_occupancy_enforces_zero_biometrics():
    """Rejects any biometric attempts and strictly enforces zero-biometric schema"""
    headers = create_auth_headers(role="AUTHORITY")
    now_iso = datetime.now(timezone.utc).isoformat()

    # Attempt to submit with facial recognition flag
    payload_bad = {
        "bus_number": "205",
        "timestamp": now_iso,
        "raw_person_count": 22,
        "stabilized_person_count": 20,
        "capacity": 55,
        "privacy_standard": "BIOMETRIC_FACIAL_RECOGNITION"
    }
    resp = client.post("/api/ingest/cctv-occupancy", json=payload_bad, headers=headers)
    assert resp.status_code == 422 # Validator strictly blocks biometrics

def test_cctv_occupancy_recalculates_trusted_percentage():
    """Recalculates occupancy percentage and sets crowd tier independently"""
    headers = create_auth_headers(role="AUTHORITY")
    now_iso = datetime.now(timezone.utc).isoformat()

    payload = {
        "bus_number": "205",
        "timestamp": now_iso,
        "raw_person_count": 48,
        "stabilized_person_count": 45,
        "capacity": 50, # 45/50 = 90% -> CROWDED
        "confidence_score": 0.92,
        "model_version": "yolov8n_coco",
        "camera_id": "BUS_205_DOOR_01",
        "privacy_standard": "PERSON_COUNTING_ONLY_NO_BIOMETRICS"
    }
    resp = client.post("/api/ingest/cctv-occupancy", json=payload, headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["accepted"] == 1

    # Verify fleet state was updated with trusted 90.0% and CROWDED
    fleet_bus = gps_simulator.fleet_state["205"]
    assert fleet_bus["passenger_count"] == 45
    assert fleet_bus["occupancy_pct"] == 90.0
    assert fleet_bus["crowd_level"] == "CROWDED"

# =========================================================================
# 4. Route Schedule & Timetable Ingestion Tests
# =========================================================================

def test_route_schedule_ingest_validates_monotonic_stops():
    """Rejects route ingestion when stop sequences are out of order"""
    headers = create_auth_headers(role="AUTHORITY")

    payload_bad = {
        "route_number": "TEST_R1",
        "route_name": "Test Corrdior 1",
        "origin": "Aluva",
        "destination": "Edappally",
        "stops": [
            {"stop_id": "S1", "stop_name": "Aluva Metro", "stop_sequence": 2, "latitude": 10.1076, "longitude": 76.3533},
            {"stop_id": "S2", "stop_name": "Edappally Toll", "stop_sequence": 1, "latitude": 10.0261, "longitude": 76.3086}
        ]
    }
    resp = client.post("/api/ingest/routes-schedule", json=payload_bad, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["rejected"] == 2
    assert "NON_MONOTONIC_STOP_SEQUENCE" in resp.json()["data"]["results"][0]["reason"]

def test_route_schedule_ingest_accepts_valid_corridor():
    """Accepts valid route stops within Greater Kochi"""
    headers = create_auth_headers(role="AUTHORITY")

    payload_valid = {
        "route_number": "99A",
        "route_name": "Kalamassery to Vyttila Express",
        "origin": "Kalamassery",
        "destination": "Vyttila",
        "corridor_key": "R_99A",
        "stops": [
            {"stop_id": "S10", "stop_name": "Kalamassery", "stop_sequence": 1, "latitude": 10.0544, "longitude": 76.3197},
            {"stop_id": "S20", "stop_name": "Palarivattom", "stop_sequence": 2, "latitude": 10.0075, "longitude": 76.3115},
            {"stop_id": "S30", "stop_name": "Vyttila Hub", "stop_sequence": 3, "latitude": 9.9678, "longitude": 76.3182}
        ]
    }
    resp = client.post("/api/ingest/routes-schedule", json=payload_valid, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["accepted"] == 3

# =========================================================================
# 5. Service Disruption Ingestion Tests
# =========================================================================

def test_disruption_ingest_success():
    """Ingests service disruption and creates incident record"""
    headers = create_auth_headers(role="AUTHORITY")
    payload = {
        "route_number": "205",
        "cause": "TRAFFIC_CONGESTION",
        "severity": "MEDIUM",
        "description": "Heavy waterlogging near Kalamassery Premier Junction",
        "affected_stops": ["Kalamassery Premier Junction", "En route Kalamassery"],
        "estimated_duration_mins": 45,
        "is_active": True
    }
    resp = client.post("/api/ingest/disruptions", json=payload, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["accepted"] == 1
    assert resp.json()["data"]["feed_type"] == "DISRUPTION"

# =========================================================================
# 6. Ingestion Health & Staleness Monitoring Tests
# =========================================================================

def test_ingestion_health_monitoring():
    """Monitors active vehicles and flags stale feeds"""
    headers = create_auth_headers(role="AUTHORITY")
    resp = client.get("/api/ingest/health", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert "tracked_vehicles_count" in data
    assert "greater_kochi_bbox" in data
    assert data["greater_kochi_bbox"]["min_lat"] == 9.8000
    assert data["greater_kochi_bbox"]["max_lat"] == 10.3500

# =========================================================================
# 7. Computer Vision Pipeline & Smoothing Safety Tests
# =========================================================================

def test_cv_temporal_stabilizer_rejects_spurious_blips():
    """Temporal rolling median rejects momentary sensor spikes"""
    stabilizer = TemporalStabilizer(window_size=5)
    # Stream of counts: 20, 20, 21, 55 (momentary occlusion/flicker), 20
    counts = [20, 20, 21, 55, 20]
    results = [stabilizer.update(c) for c in counts]
    # At the spike (55), median of [20, 20, 21, 55] is 20.5 -> 20/21, NOT 55
    assert results[3] in [20, 21]
    assert results[4] == 20

def test_cv_occupancy_calculator_bounds():
    """OccupancyCalculator clamps ratios and classifies tiers accurately"""
    assert OccupancyCalculator.calculate_occupancy_percentage(0, 50) == 0.0
    assert OccupancyCalculator.calculate_occupancy_percentage(25, 50) == 50.0
    assert OccupancyCalculator.calculate_occupancy_percentage(60, 50) == 100.0 # Clamped to 100%

    assert OccupancyCalculator.classify_crowd_tier(20.0) == "LOW"
    assert OccupancyCalculator.classify_crowd_tier(55.0) == "MODERATE"
    assert OccupancyCalculator.classify_crowd_tier(85.0) == "CROWDED"

def test_cv_yolo_detector_missing_weights_fallback():
    """YOLOPersonDetector handles missing weights gracefully via mock mode"""
    detector = YOLOPersonDetector(model_path="non_existent_weights_path.pt")
    detector.load_model()
    assert detector.mock_mode is True
    res = detector.detect(frame=None)
    assert res.raw_person_count == 0
    assert res.detections == []

# =========================================================================
# 8. Demand Forecaster Evaluation & Persistence Comparison
# =========================================================================

def test_demand_forecaster_eval_metrics():
    """Validates multi-horizon evaluation metrics against persistence baseline"""
    metrics = demand_forecaster.evaluation_metrics
    assert 15 in metrics
    assert 30 in metrics
    assert 60 in metrics

    for h in [15, 30, 60]:
        m = metrics[h]
        assert "model_mae" in m
        assert "model_rmse" in m
        assert "baseline_mae" in m
        assert "baseline_rmse" in m
        assert m["model_mae"] >= 0.0
        assert m["model_rmse"] >= 0.0

def test_demand_forecaster_output_bounds():
    """Forecasted occupancy percentages must strictly stay between 0.0 and 100.0"""
    forecast = demand_forecaster.forecast_corridor_crowd(route_number="205")
    assert len(forecast) == 4
    for pt in forecast:
        assert 0.0 <= pt.predicted_occupancy_pct <= 100.0
        assert pt.crowd_level in [CrowdLevel.LOW, CrowdLevel.MODERATE, CrowdLevel.CROWDED]

# =========================================================================
# 9. Multi-Factor Recommendation Edge Cases & Explainability
# =========================================================================

def test_recommendation_handles_fallback_on_unknown_stops():
    """Recommendation engine handles unknown stops by safely falling back without crashing"""
    req = {
        "origin": "NonExistentStop_A",
        "destination": "NonExistentStop_B",
        "preference": "balanced"
    }
    resp = client.post("/api/recommendations/plan", json=req)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert "recommended_bus" in data
    assert data["recommended_bus"]["bus_number"] in ["205", "12", "14A"]
    assert "journey_score" in data["recommended_bus"]
    assert "why_recommended" in data["recommended_bus"]

def test_recommendation_explainability_and_truth_origin():
    """Recommendations explain scoring factors and retain RECOMMENDATION origin"""
    req = {
        "origin": "Aluva Metro Station",
        "destination": "Vyttila Mobility Hub",
        "preference": "balanced"
    }
    resp = client.post("/api/recommendations/plan", json=req)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert "recommended_bus" in data
    top = data["recommended_bus"]
    assert "journey_score" in top
    assert "why_recommended" in top
    assert len(top["why_recommended"]) > 0
    assert resp.json()["data_origin"] == "RECOMMENDATION"
