"""
BusSense AI - Computer Vision Occupancy Intelligence Module
Phase H8: Offline / Replayable Video Pipeline
SEE -> COUNT -> SENSE -> PUBLISH
Privacy: Class 'person' bounding box counting only. No biometrics or facial recognition.
"""
try:
    from backend.cv.schemas import (
        DetectionBox,
        FrameDetectionResult,
        OccupancyEvent,
        ReplaySummary,
    )
    from backend.cv.smoothing import TemporalStabilizer
    from backend.cv.occupancy import OccupancyCalculator
    from backend.cv.detector import YOLOPersonDetector
    from backend.cv.video_processor import VideoReplayProcessor
except ImportError:
    from cv.schemas import (
        DetectionBox,
        FrameDetectionResult,
        OccupancyEvent,
        ReplaySummary,
    )
    from cv.smoothing import TemporalStabilizer
    from cv.occupancy import OccupancyCalculator
    from cv.detector import YOLOPersonDetector
    from cv.video_processor import VideoReplayProcessor

__all__ = [
    "DetectionBox",
    "FrameDetectionResult",
    "OccupancyEvent",
    "ReplaySummary",
    "TemporalStabilizer",
    "OccupancyCalculator",
    "YOLOPersonDetector",
    "VideoReplayProcessor",
]
