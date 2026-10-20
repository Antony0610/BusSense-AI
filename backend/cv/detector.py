"""
BusSense AI - YOLO Person Detection Engine
Phase H8: Offline / Replayable Video Pipeline
Model: YOLOv8n (Nano)
Target Class: COCO Class 0 ("person") exclusively.
Zero biometrics: Bounding boxes around bodies/heads only. No face recognition, no identity tracking.
Device: Auto-detected (CUDA if available, otherwise CPU).
"""
import time
from typing import List, Optional, Any
from pathlib import Path
try:
    from backend.cv.schemas import DetectionBox, FrameDetectionResult
except ImportError:
    from cv.schemas import DetectionBox, FrameDetectionResult

class YOLOPersonDetector:
    """
    Anonymized YOLOv8 Person Detector.
    Strictly filters detections to class 'person' (COCO class 0).
    Supports CPU and CUDA hardware acceleration.
    """
    def __init__(
        self,
        model_path: str = "yolov8n.pt",
        confidence_threshold: float = 0.40,
        device: Optional[str] = None,
        mock_mode: bool = False,
    ):
        self.model_path = model_path
        self.conf_threshold = confidence_threshold
        self.mock_mode = mock_mode
        self._model = None
        self._device = device or self._detect_device()

    def _detect_device(self) -> str:
        """Auto-detects available compute device (CUDA GPU vs CPU)."""
        try:
            import torch
            if torch.cuda.is_available():
                return "cuda"
        except ImportError:
            pass
        return "cpu"

    @property
    def device(self) -> str:
        return self._device

    def _resolve_model_path(self) -> str:
        """Resolves model weights path across various execution directories."""
        candidates = [
            Path(self.model_path),
            Path.cwd() / self.model_path,
            Path(__file__).parent / self.model_path,
            Path(__file__).parent.parent.parent / self.model_path,
        ]
        if self.model_path == "yolov8n.pt":
            candidates.append(Path("d:/Bus_Sense_Ai/yolov8n.pt"))
        for c in candidates:
            if c.exists() and c.is_file():
                return str(c)
        return self.model_path

    def load_model(self):
        """Loads Ultralytics YOLO model onto target device."""
        if self.mock_mode:
            return
        if self._model is None:
            try:
                from ultralytics import YOLO
                resolved_path = self._resolve_model_path()
                self._model = YOLO(resolved_path)
            except Exception as e:
                # If weights file or torch loading fails, fallback gracefully to mock mode
                print(f"[YOLOPersonDetector] Notice: loading model failed ({e}), switching to fallback mock mode.")
                self.mock_mode = True

    def detect(self, frame: Any, frame_index: int = 0, timestamp_sec: float = 0.0) -> FrameDetectionResult:
        """
        Runs person detection on a single frame (numpy BGR array).
        Returns FrameDetectionResult containing anonymous bounding boxes and count.
        """
        start_time = time.perf_counter()

        if self.mock_mode or frame is None:
            inference_ms = round((time.perf_counter() - start_time) * 1000.0, 2)
            return FrameDetectionResult(
                frame_index=frame_index,
                timestamp_sec=timestamp_sec,
                raw_person_count=0,
                detections=[],
                inference_time_ms=inference_ms,
            )

        self.load_model()

        detections: List[DetectionBox] = []
        try:
            # Ultralytics inference with classes=[0] strictly filters to class 0 (person)
            results = self._model(
                frame,
                classes=[0],
                conf=self.conf_threshold,
                device=self._device,
                verbose=False,
            )

            for r in results:
                boxes = r.boxes
                if boxes is not None:
                    for b in boxes:
                        cls_id = int(b.cls[0].item())
                        conf = float(b.conf[0].item())
                        # Strictly verify class 0 and confidence
                        if cls_id == 0 and conf >= self.conf_threshold:
                            xyxy = b.xyxy[0].tolist()
                            detections.append(
                                DetectionBox(
                                    x1=round(xyxy[0], 1),
                                    y1=round(xyxy[1], 1),
                                    x2=round(xyxy[2], 1),
                                    y2=round(xyxy[3], 1),
                                    confidence=round(conf, 3),
                                    class_id=0,
                                    class_name="person",
                                )
                            )
        except Exception as e:
            print(f"[YOLOPersonDetector] Inference warning on frame {frame_index}: {e}")

        inference_ms = round((time.perf_counter() - start_time) * 1000.0, 2)

        return FrameDetectionResult(
            frame_index=frame_index,
            timestamp_sec=timestamp_sec,
            raw_person_count=len(detections),
            detections=detections,
            inference_time_ms=inference_ms,
        )
