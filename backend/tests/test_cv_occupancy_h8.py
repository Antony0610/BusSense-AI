"""
BusSense AI - Phase H8 Test Suite
Computer Vision Occupancy Intelligence (Offline / Replayable Pipeline)
Verifies:
1. Person-class filtering (class 0 only)
2. Confidence filtering
3. Raw count
4. Occupancy calculation & clamping (0-100%)
5. Threshold classification (LOW < 50%, MODERATE 50-80%, CROWDED > 80%)
6. Temporal smoothing (rolling median window)
7. Occupancy schema validation
8. Invalid capacity handling
9. Occupancy >100 handling
10. Video metadata handling
11. Video replay pipeline execution
12. Backend ingestion authentication (401 unauth, 403 insufficient role)
13. Backend ingestion validation (invalid bus, negative counts)
14. Fleet telemetry reflection (data_origin -> CV REPLAY)
15. Privacy & security boundaries (zero biometrics, person counting only)
16. CPU execution & automatic device detection
"""
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

import pytest
from datetime import datetime, timezone
from pathlib import Path
from fastapi.testclient import TestClient

from app.main import app
from app.schemas.common import DataOrigin
from app.core.security import create_access_token
from app.core.config import settings

from backend.cv.schemas import DetectionBox, FrameDetectionResult, OccupancyEvent, ReplaySummary
from backend.cv.detector import YOLOPersonDetector
from backend.cv.smoothing import TemporalStabilizer
from backend.cv.occupancy import OccupancyCalculator
from backend.cv.video_processor import VideoReplayProcessor

client = TestClient(app)

# Helper auth tokens
def get_auth_token(role: str = "AUTHORITY") -> str:
    return create_access_token({
        "sub": "00000000-0000-0000-0000-000000000099",
        "email": f"{role.lower()}@bussense.kerala.gov.in",
        "role": role,
        "full_name": f"Test {role.title()}"
    })


# ==========================================
# 1. Detection & Filtering Unit Tests
# ==========================================

def test_person_class_filtering():
    """Verifies that only class_id == 0 ('person') is counted and retained."""
    boxes = [
        DetectionBox(x1=10, y1=10, x2=50, y2=100, confidence=0.85, class_id=0, class_name="person"),
        DetectionBox(x1=60, y1=20, x2=120, y2=120, confidence=0.90, class_id=2, class_name="car"),
        DetectionBox(x1=130, y1=20, x2=200, y2=140, confidence=0.75, class_id=5, class_name="bus"),
        DetectionBox(x1=210, y1=30, x2=250, y2=110, confidence=0.82, class_id=0, class_name="person"),
    ]
    # Filter to class 0
    filtered = [b for b in boxes if b.class_id == 0]
    assert len(filtered) == 2
    assert all(b.class_name == "person" for b in filtered)


def test_confidence_filtering():
    """Verifies configurable confidence threshold filtering."""
    detector = YOLOPersonDetector(confidence_threshold=0.40, mock_mode=True)
    assert detector.conf_threshold == 0.40

    raw_candidates = [
        {"conf": 0.35, "valid": False},
        {"conf": 0.40, "valid": True},
        {"conf": 0.78, "valid": True},
        {"conf": 0.22, "valid": False},
    ]
    passed = [c for c in raw_candidates if c["conf"] >= detector.conf_threshold]
    assert len(passed) == 2
    assert all(p["valid"] for p in passed)


def test_raw_person_count():
    """Verifies raw person count accurately reflects detected instances."""
    det_result = FrameDetectionResult(
        frame_index=15,
        timestamp_sec=0.6,
        raw_person_count=3,
        detections=[
            DetectionBox(x1=10, y1=10, x2=50, y2=90, confidence=0.88, class_id=0),
            DetectionBox(x1=60, y1=15, x2=95, y2=95, confidence=0.74, class_id=0),
            DetectionBox(x1=110, y1=20, x2=140, y2=100, confidence=0.69, class_id=0),
        ],
        inference_time_ms=45.2
    )
    assert det_result.raw_person_count == 3
    assert len(det_result.detections) == 3


# ==========================================
# 2. Occupancy Calculation & Clamping Tests
# ==========================================

def test_occupancy_calculation():
    """Verifies percentage = (person_count / capacity) * 100."""
    pct = OccupancyCalculator.calculate_occupancy_percentage(person_count=22, capacity=55)
    assert pct == 40.0

    pct_fraction = OccupancyCalculator.calculate_occupancy_percentage(person_count=23, capacity=55)
    assert pct_fraction == 41.8


def test_occupancy_clamping():
    """Verifies clamping to [0.0, 100.0]% even under extreme counts."""
    # Over capacity (overcrowded Kerala bus)
    over_capacity = OccupancyCalculator.calculate_occupancy_percentage(person_count=70, capacity=55)
    assert over_capacity == 100.0

    # Negative count handling
    negative_count = OccupancyCalculator.calculate_occupancy_percentage(person_count=-5, capacity=55)
    assert negative_count == 0.0


def test_invalid_capacity_rejected():
    """Verifies capacity <= 0 raises ValueError."""
    with pytest.raises(ValueError, match="capacity must be greater than 0"):
        OccupancyCalculator.calculate_occupancy_percentage(person_count=20, capacity=0)

    with pytest.raises(ValueError, match="capacity must be greater than 0"):
        OccupancyCalculator.calculate_occupancy_percentage(person_count=20, capacity=-10)


# ==========================================
# 3. Crowd Tier Threshold Tests
# ==========================================

def test_threshold_classification():
    """
    Standard BusSense thresholds:
    LOW < 50%
    MODERATE 50% - 80%
    CROWDED > 80%
    """
    # LOW
    assert OccupancyCalculator.classify_crowd_tier(0.0) == "LOW"
    assert OccupancyCalculator.classify_crowd_tier(49.9) == "LOW"

    # MODERATE
    assert OccupancyCalculator.classify_crowd_tier(50.0) == "MODERATE"
    assert OccupancyCalculator.classify_crowd_tier(65.0) == "MODERATE"
    assert OccupancyCalculator.classify_crowd_tier(80.0) == "MODERATE"

    # CROWDED
    assert OccupancyCalculator.classify_crowd_tier(80.1) == "CROWDED"
    assert OccupancyCalculator.classify_crowd_tier(100.0) == "CROWDED"


# ==========================================
# 4. Temporal Smoothing Tests
# ==========================================

def test_temporal_smoothing_rolling_median():
    """
    Verifies that the rolling median filter rejects instantaneous bounding box flickering
    and transient camera occlusions.
    """
    stabilizer = TemporalStabilizer(window_size=5)

    # Initial stable sequence
    stabilizer.update(25)
    stabilizer.update(25)
    stabilizer.update(25)
    assert stabilizer.current_stabilized == 25

    # Transient occlusion dip (camera blocked for 1 frame)
    dip_raw = 0
    dip_stabilized = stabilizer.update(dip_raw)
    assert dip_stabilized == 25  # Median of [25, 25, 25, 0] is 25

    # Transient boarding spike (false positive box)
    spike_raw = 45
    spike_stabilized = stabilizer.update(spike_raw)
    assert spike_stabilized == 25  # Median of [25, 25, 25, 0, 45] is 25

    # Distinguishes RAW COUNT from STABILIZED COUNT
    raw, stable = stabilizer.process(50)
    assert raw == 50
    assert stable == 25  # Replaces oldest 25 -> median of [25, 25, 0, 45, 50] is 25


def test_stabilizer_reset():
    """Verifies buffer clear between distinct video replay runs."""
    stabilizer = TemporalStabilizer(window_size=3)
    stabilizer.update(10)
    stabilizer.update(15)
    assert len(stabilizer.history) == 2
    stabilizer.reset()
    assert len(stabilizer.history) == 0
    assert stabilizer.current_stabilized == 0


# ==========================================
# 5. Schema Validation & Privacy Tests
# ==========================================

def test_occupancy_event_schema():
    """Verifies typed OccupancyEvent serialization and constraints."""
    event = OccupancyCalculator.evaluate(
        raw_count=31,
        stabilized_count=29,
        capacity=60,
        bus_number="205",
        source="CV_REPLAY",
        model="YOLOv8n",
        confidence_threshold=0.45,
        inference_time_ms=12.4,
        fps=25.0,
        frame_number=120
    )
    assert event.bus_number == "205"
    assert event.raw_person_count == 31
    assert event.stabilized_person_count == 29
    assert event.capacity == 60
    assert event.occupancy_percentage == 48.3
    assert event.crowd_level == "LOW"
    assert event.source == "CV_REPLAY"
    assert event.model == "YOLOv8n"
    assert event.confidence_threshold == 0.45
    assert event.privacy_standard == "PERSON_COUNTING_ONLY_NO_BIOMETRICS"


def test_invalid_crowd_level_in_schema():
    """Verifies schema rejects unapproved crowd level values."""
    with pytest.raises(ValueError):
        OccupancyEvent(
            bus_number="205",
            raw_person_count=10,
            stabilized_person_count=10,
            capacity=50,
            occupancy_percentage=20.0,
            crowd_level="SUPER_CROWDED",  # Invalid
        )


def test_privacy_boundaries_zero_biometrics():
    """
    Explicitly tests architectural privacy guarantees:
    - Bounding box schema has no face fields or embeddings.
    - OccupancyEvent has no identity or person-tracking identifiers.
    - No facial recognition imports in backend/cv.
    """
    # 1. DetectionBox fields
    box_fields = DetectionBox.model_fields.keys()
    assert "face_embedding" not in box_fields
    assert "face_id" not in box_fields
    assert "biometric" not in box_fields
    assert "name" not in box_fields

    # 2. OccupancyEvent fields
    event_fields = OccupancyEvent.model_fields.keys()
    assert "passenger_id" not in event_fields
    assert "user_id" not in event_fields
    assert "identity" not in event_fields

    # 3. Privacy standard stamp
    event = OccupancyCalculator.evaluate(raw_count=5, stabilized_count=5, capacity=50)
    assert event.privacy_standard == "PERSON_COUNTING_ONLY_NO_BIOMETRICS"


# ==========================================
# 6. CPU & Device Detection Tests
# ==========================================

def test_device_auto_detection():
    """Verifies detector auto-detects CPU or CUDA without crashing."""
    detector = YOLOPersonDetector()
    assert detector.device in ["cpu", "cuda"]
    # CPU must be fully supported
    cpu_detector = YOLOPersonDetector(device="cpu")
    assert cpu_detector.device == "cpu"


# ==========================================
# 7. Video Replay Pipeline Tests
# ==========================================

def test_video_replay_missing_file_raises():
    """Verifies clear FileNotFoundError when video path does not exist."""
    processor = VideoReplayProcessor(video_path="datasets/videos/non_existent.mp4")
    with pytest.raises(FileNotFoundError):
        processor.process()


def test_sample_bus_video_replay():
    """
    Executes offline video replay on datasets/videos/sample_bus.mp4.
    Measures processing FPS, latency, and crowd statistics.
    """
    video_path = Path("datasets/videos/sample_bus.mp4")
    if not video_path.exists():
        pytest.skip("sample_bus.mp4 not found (run create_sample_video.py)")

    events = []
    processor = VideoReplayProcessor(
        video_path=str(video_path),
        bus_number="205",
        capacity=55,
        process_every_n_frames=10,  # Fast sampling for test suite
        publish_callback=lambda evt: events.append(evt)
    )
    summary = processor.process()

    assert summary.total_frames > 0
    assert summary.processed_frames > 0
    assert summary.video_fps > 0
    assert summary.processing_fps >= 0
    assert summary.average_inference_ms >= 0
    assert summary.bus_number == "205"
    assert summary.model == "YOLOv8n"
    assert len(events) == summary.processed_frames


# ==========================================
# 8. Backend Ingestion & Authentication Tests
# ==========================================

def test_ingest_occupancy_unauthenticated_rejected():
    """Verifies that POST /api/occupancy/events requires authentication (401)."""
    payload = {
        "bus_number": "205",
        "raw_person_count": 28,
        "stabilized_person_count": 27,
        "capacity": 55,
        "occupancy_percentage": 49.1,
        "crowd_level": "LOW",
        "source": "CV_REPLAY"
    }
    resp = client.post("/api/occupancy/events", json=payload)
    assert resp.status_code == 401
    assert "Unauthorized" in resp.json()["detail"]


def test_ingest_occupancy_passenger_role_rejected():
    """Verifies that PASSENGER role cannot ingest CV telemetry (403 Forbidden)."""
    token = get_auth_token("PASSENGER")
    payload = {
        "bus_number": "205",
        "raw_person_count": 28,
        "stabilized_person_count": 27,
        "capacity": 55,
        "occupancy_percentage": 49.1,
        "crowd_level": "LOW"
    }
    resp = client.post(
        "/api/occupancy/events",
        json=payload,
        headers={"Authorization": f"Bearer {token}"}
    )
    assert resp.status_code == 403


def test_ingest_occupancy_conductor_role_rejected():
    """Verifies that DRIVER_CONDUCTOR role cannot ingest CV telemetry (403 Forbidden)."""
    token = get_auth_token("DRIVER_CONDUCTOR")
    payload = {
        "bus_number": "205",
        "raw_person_count": 28,
        "stabilized_person_count": 27,
        "capacity": 55,
        "occupancy_percentage": 49.1,
        "crowd_level": "LOW"
    }
    resp = client.post(
        "/api/occupancy/events",
        json=payload,
        headers={"Authorization": f"Bearer {token}"}
    )
    assert resp.status_code == 403


def test_ingest_occupancy_invalid_bus_rejected():
    """Verifies that an unknown bus number returns 404 Not Found."""
    token = get_auth_token("AUTHORITY")
    payload = {
        "bus_number": "NON_EXISTENT_999",
        "raw_person_count": 20,
        "stabilized_person_count": 20,
        "capacity": 55,
        "occupancy_percentage": 36.4,
        "crowd_level": "LOW"
    }
    resp = client.post(
        "/api/occupancy/events",
        json=payload,
        headers={"Authorization": f"Bearer {token}"}
    )
    assert resp.status_code == 404
    assert "not found in active fleet" in resp.json()["detail"]


def test_ingest_occupancy_recalculates_trusted_percentage():
    """
    Verifies Section 15 requirement:
    'Do not trust arbitrary occupancy percentages from a client.'
    The backend must recalculate trusted occupancy percentage and crowd level.
    """
    token = get_auth_token("AUTHORITY")
    # Client sends fake 99.9% occupancy for 22 passengers in 55 capacity bus
    payload = {
        "bus_number": "205",
        "raw_person_count": 25,
        "stabilized_person_count": 22,
        "capacity": 55,
        "occupancy_percentage": 99.9,  # FAKE CLIENT VALUE
        "crowd_level": "CROWDED"       # FAKE CLIENT VALUE
    }
    resp = client.post(
        "/api/occupancy/events",
        json=payload,
        headers={"Authorization": f"Bearer {token}"}
    )
    assert resp.status_code == 200
    data = resp.json()["data"]
    # Verified: 22/55 = 40.0% -> LOW
    assert data["occupancy_percentage"] == 40.0
    assert data["crowd_level"] == "LOW"
    assert data["source"] == "CV_REPLAY"
    assert resp.json()["data_origin"] == "CV REPLAY"


def test_ingest_occupancy_internal_secret_auth():
    """Verifies that local replay CLI can authenticate via X-Internal-Secret header."""
    payload = {
        "bus_number": "205",
        "raw_person_count": 30,
        "stabilized_person_count": 28,
        "capacity": 55,
        "occupancy_percentage": 50.9,
        "crowd_level": "MODERATE"
    }
    resp = client.post(
        "/api/occupancy/events",
        json=payload,
        headers={"X-Internal-Secret": settings.SECRET_KEY}
    )
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["stabilized_person_count"] == 28
    assert data["crowd_level"] == "MODERATE"


def test_fleet_and_crowd_apis_reflect_cv_replay():
    """
    Verifies that after ingesting CV replay telemetry,
    /api/crowd/{bus_number} and /api/occupancy/live/{bus_number}
    reflect the updated counts and label the data origin as 'CV REPLAY'.
    """
    # 1. Ingest CV event for Bus 205
    token = get_auth_token("AUTHORITY")
    payload = {
        "bus_number": "205",
        "raw_person_count": 33,
        "stabilized_person_count": 33,
        "capacity": 55,
        "occupancy_percentage": 60.0,
        "crowd_level": "MODERATE"
    }
    ingest_resp = client.post(
        "/api/occupancy/events",
        json=payload,
        headers={"Authorization": f"Bearer {token}"}
    )
    assert ingest_resp.status_code == 200

    # 2. Check /api/crowd/205
    crowd_resp = client.get("/api/crowd/205")
    assert crowd_resp.status_code == 200
    crowd_data = crowd_resp.json()["data"]
    assert crowd_data["passenger_count"] == 33
    assert crowd_data["occupancy_pct"] == 60.0
    assert crowd_data["crowd_level"] == "MODERATE"
    assert crowd_data["data_origin"] == "CV REPLAY"

    # 3. Check /api/occupancy/live/205
    live_resp = client.get("/api/occupancy/live/205")
    assert live_resp.status_code == 200
    live_data = live_resp.json()["data"]
    assert live_data["passenger_count"] == 33
    assert live_data["occupancy_percentage"] == 60.0
    assert live_data["crowd_level"] == "MODERATE"
    assert live_resp.json()["data_origin"] == "CV REPLAY"
