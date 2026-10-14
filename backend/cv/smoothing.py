"""
BusSense AI - Temporal Stabilization & Smoothing
Phase H8: Explainable Frame-to-Frame Outlier Rejection
Method: Rolling Median Window
Why: Rejects transient camera occlusions, bounding box flickering, and instantaneous boarding blips
without asymptotic lag.
"""
from collections import deque
import statistics
from typing import List, Tuple

class TemporalStabilizer:
    """
    Explainable rolling median temporal smoother.
    Maintains a FIFO queue of recent raw detection counts and computes
    the median value as the stabilized passenger estimate.
    """
    def __init__(self, window_size: int = 5):
        if window_size < 1:
            raise ValueError("window_size must be at least 1")
        self.window_size = window_size
        self._history = deque(maxlen=window_size)

    def update(self, raw_count: int) -> int:
        """
        Ingests a new raw person count and outputs the stabilized count.
        """
        if raw_count < 0:
            raw_count = 0
        self._history.append(raw_count)
        stabilized = int(round(statistics.median(self._history)))
        return stabilized

    def process(self, raw_count: int) -> Tuple[int, int]:
        """
        Returns (raw_count, stabilized_count) tuple.
        """
        stabilized = self.update(raw_count)
        return raw_count, stabilized

    @property
    def current_stabilized(self) -> int:
        if not self._history:
            return 0
        return int(round(statistics.median(self._history)))

    @property
    def history(self) -> List[int]:
        return list(self._history)

    def reset(self):
        """Clears sliding window buffer for a new video stream or vehicle run."""
        self._history.clear()
