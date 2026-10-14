"""
BusSense AI - Computer Vision Schemas & Data Contracts
Phase H8: Offline / Replayable Video Pipeline
Strict Privacy: Contains person count & bounding boxes only. No identities, face embeddings, or demographics.
"""
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, field_validator
from datetime import datetime, timezone
try:
    from app.schemas.common import CrowdLevel
except ImportError:
    try:
        from backend.app.schemas.common import CrowdLevel
    except ImportError:
        from enum import Enum
        class CrowdLevel(str, Enum):
            LOW = "LOW"
            MODERATE = "MODERATE"
            CROWDED = "CROWDED"

class DetectionBox(BaseModel):
    """Anonymous bounding box coordinates for a detected person."""
    x1: float
    y1: float
    x2: float
    y2: float
    confidence: float = Field(ge=0.0, le=1.0)
    class_id: int = 0
    class_name: str = "person"

class FrameDetectionResult(BaseModel):
    """Inference output for a single processed video frame."""
    frame_index: int
    timestamp_sec: float
    raw_person_count: int
    detections: List[DetectionBox] = Field(default_factory=list)
    inference_time_ms: float = 0.0

class OccupancyEvent(BaseModel):
    """
    Standardized occupancy event produced by the CV pipeline.
    Published to FastAPI backend for consumption by Passenger, Conductor, and Authority clients.
    """
    bus_number: str
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    raw_person_count: int = Field(ge=0, description="Raw detected people in current frame")
    stabilized_person_count: int = Field(ge=0, description="Temporally smoothed passenger count")
    capacity: int = Field(gt=0, description="Vehicle maximum design capacity")
    occupancy_percentage: float = Field(ge=0.0, le=100.0, description="Clamped occupancy ratio (0-100%)")
    crowd_level: str = Field(description="LOW (<50%), MODERATE (50-80%), CROWDED (>80%)")
    source: str = Field(default="CV_REPLAY", description="Data origin stamp: CV_REPLAY or SIMULATED")
    model: str = Field(default="YOLOv8n", description="Object detection model utilized")
    confidence_threshold: float = Field(default=0.40, ge=0.0, le=1.0)
    inference_time_ms: Optional[float] = None
    fps: Optional[float] = None
    frame_number: Optional[int] = None
    privacy_standard: str = Field(
        default="PERSON_COUNTING_ONLY_NO_BIOMETRICS",
        description="Factual privacy policy stamp"
    )

    @field_validator("crowd_level")
    @classmethod
    def validate_crowd_level(cls, v: str) -> str:
        upper = v.upper()
        if upper not in ["LOW", "MODERATE", "CROWDED"]:
            raise ValueError(f"Invalid crowd_level: {v}. Must be LOW, MODERATE, or CROWDED.")
        return upper

class ReplaySummary(BaseModel):
    """Benchmark and replay summary statistics after video execution."""
    video_path: str
    bus_number: str
    total_frames: int
    processed_frames: int
    video_fps: float
    duration_seconds: float
    average_inference_ms: float
    processing_fps: float
    peak_occupancy_pct: float
    average_occupancy_pct: float
    crowd_distribution: Dict[str, int]
    events_published: int
    device: str
    model: str
