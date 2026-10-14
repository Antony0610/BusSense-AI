"""
BusSense AI - Occupancy Calculation & Crowd Classification
Phase H8: Standardized Capacity Model & Crowd Tier Evaluation
Thresholds:
LOW < 50%
MODERATE 50% – 80%
CROWDED > 80%
"""
from typing import Optional
try:
    from backend.cv.schemas import OccupancyEvent
except ImportError:
    from cv.schemas import OccupancyEvent
from datetime import datetime, timezone

class OccupancyCalculator:
    """
    Computes clamped occupancy percentage and standard BusSense crowd tiers.
    """
    @staticmethod
    def calculate_occupancy_percentage(person_count: int, capacity: int) -> float:
        """
        Calculates: (person_count / capacity) * 100, clamped to [0.0, 100.0].
        Raises ValueError if capacity <= 0.
        """
        if capacity <= 0:
            raise ValueError(f"Bus capacity must be greater than 0, got {capacity}")
        if person_count < 0:
            person_count = 0

        raw_pct = (person_count / capacity) * 100.0
        clamped_pct = max(0.0, min(100.0, raw_pct))
        return round(clamped_pct, 1)

    @staticmethod
    def classify_crowd_tier(occupancy_pct: float) -> str:
        """
        Unified BusSense threshold definitions:
        LOW < 50.0%
        MODERATE 50.0% - 80.0%
        CROWDED > 80.0%
        """
        if occupancy_pct < 50.0:
            return "LOW"
        elif occupancy_pct <= 80.0:
            return "MODERATE"
        else:
            return "CROWDED"

    @classmethod
    def evaluate(
        cls,
        raw_count: int,
        stabilized_count: int,
        capacity: int,
        bus_number: str = "205",
        source: str = "CV_REPLAY",
        model: str = "YOLOv8n",
        confidence_threshold: float = 0.40,
        inference_time_ms: Optional[float] = None,
        fps: Optional[float] = None,
        frame_number: Optional[int] = None,
    ) -> OccupancyEvent:
        """
        Builds a validated OccupancyEvent model.
        """
        pct = cls.calculate_occupancy_percentage(stabilized_count, capacity)
        crowd_tier = cls.classify_crowd_tier(pct)

        return OccupancyEvent(
            bus_number=bus_number,
            timestamp=datetime.now(timezone.utc).isoformat(),
            raw_person_count=raw_count,
            stabilized_person_count=stabilized_count,
            capacity=capacity,
            occupancy_percentage=pct,
            crowd_level=crowd_tier,
            source=source,
            model=model,
            confidence_threshold=confidence_threshold,
            inference_time_ms=inference_time_ms,
            fps=fps,
            frame_number=frame_number,
            privacy_standard="PERSON_COUNTING_ONLY_NO_BIOMETRICS",
        )
