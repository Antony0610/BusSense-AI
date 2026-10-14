"""
BusSense AI - Computer Vision Video Replay Processor
Phase H8: Offline / Replayable Video Pipeline
Supports MP4 and standard video formats.
Processes frames at configurable sampling rates (e.g. process_every_n_frames=3).
Measures real performance metrics: inference time ms, processing FPS, latency.
Optionally generates anonymized debug annotated video with crowd HUD overlays.
Zero biometrics: Only renders anonymous bounding boxes.
"""
import os
import sys
import time
import argparse
from pathlib import Path
from typing import List, Optional, Callable, Dict, Any, Generator

try:
    from backend.cv.schemas import DetectionBox, FrameDetectionResult, OccupancyEvent, ReplaySummary
    from backend.cv.detector import YOLOPersonDetector
    from backend.cv.smoothing import TemporalStabilizer
    from backend.cv.occupancy import OccupancyCalculator
except ImportError:
    from cv.schemas import DetectionBox, FrameDetectionResult, OccupancyEvent, ReplaySummary
    from cv.detector import YOLOPersonDetector
    from cv.smoothing import TemporalStabilizer
    from cv.occupancy import OccupancyCalculator

class VideoReplayProcessor:
    """
    Offline video processing pipeline for transit occupancy estimation.
    Extracts frames -> YOLO Person Detection -> Rolling Median Smoothing ->
    Occupancy & Crowd Classification -> Benchmark Metrics & Event Dispatch.
    """
    def __init__(
        self,
        video_path: str,
        bus_number: str = "205",
        capacity: int = 55,
        process_every_n_frames: int = 3,
        confidence_threshold: float = 0.40,
        model_path: str = "yolov8n.pt",
        detector: Optional[YOLOPersonDetector] = None,
        stabilizer: Optional[TemporalStabilizer] = None,
        output_annotated_path: Optional[str] = None,
        publish_callback: Optional[Callable[[OccupancyEvent], None]] = None,
    ):
        self.video_path = str(video_path)
        self.bus_number = bus_number
        self.capacity = capacity
        self.process_every_n_frames = max(1, process_every_n_frames)
        self.conf_threshold = confidence_threshold
        self.output_annotated_path = output_annotated_path
        self.publish_callback = publish_callback

        self.detector = detector or YOLOPersonDetector(
            model_path=model_path,
            confidence_threshold=confidence_threshold
        )
        self.stabilizer = stabilizer or TemporalStabilizer(window_size=5)

    def process(self) -> ReplaySummary:
        """
        Executes full offline video processing run.
        Returns ReplaySummary with empirical performance metrics.
        """
        if not os.path.exists(self.video_path):
            raise FileNotFoundError(f"Video file not found at: {self.video_path}")

        try:
            import cv2
        except ImportError:
            raise ImportError(
                "OpenCV (cv2) is required for video processing. "
                "Please verify 'opencv-python' is installed."
            )

        cap = cv2.VideoCapture(self.video_path)
        if not cap.isOpened():
            raise ValueError(f"Unable to open video file: {self.video_path}")

        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        video_fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        duration_sec = total_frames / video_fps if video_fps > 0 else 0.0

        writer = None
        if self.output_annotated_path:
            out_p = Path(self.output_annotated_path)
            out_p.parent.mkdir(parents=True, exist_ok=True)
            fourcc = cv2.VideoWriter_fourcc(*"mp4v")
            effective_fps = video_fps / self.process_every_n_frames
            writer = cv2.VideoWriter(str(out_p), fourcc, effective_fps, (width, height))

        self.stabilizer.reset()
        events: List[OccupancyEvent] = []
        inference_times: List[float] = []
        crowd_dist: Dict[str, int] = {"LOW": 0, "MODERATE": 0, "CROWDED": 0}

        frame_idx = 0
        processed_count = 0
        start_wall_time = time.perf_counter()

        try:
            while True:
                ret, frame = cap.read()
                if not ret:
                    break

                if frame_idx % self.process_every_n_frames == 0:
                    processed_count += 1
                    timestamp_sec = frame_idx / video_fps if video_fps > 0 else 0.0

                    # 1. Detect Persons
                    det_result = self.detector.detect(
                        frame=frame,
                        frame_index=frame_idx,
                        timestamp_sec=timestamp_sec
                    )
                    inference_times.append(det_result.inference_time_ms)

                    # 2. Temporal Smoothing
                    raw_count = det_result.raw_person_count
                    stabilized_count = self.stabilizer.update(raw_count)

                    # 3. Calculate Occupancy & Crowd Level
                    event = OccupancyCalculator.evaluate(
                        raw_count=raw_count,
                        stabilized_count=stabilized_count,
                        capacity=self.capacity,
                        bus_number=self.bus_number,
                        source="CV_REPLAY",
                        model="YOLOv8n",
                        confidence_threshold=self.conf_threshold,
                        inference_time_ms=det_result.inference_time_ms,
                        frame_number=frame_idx,
                    )
                    events.append(event)
                    crowd_dist[event.crowd_level] = crowd_dist.get(event.crowd_level, 0) + 1

                    # 4. Optional Publisher Callback
                    if self.publish_callback:
                        try:
                            self.publish_callback(event)
                        except Exception as pub_err:
                            print(f"[VideoReplayProcessor] Publisher warning: {pub_err}")

                    # 5. Debug Annotation Render
                    if writer is not None:
                        annotated = frame.copy()
                        # Draw bounding boxes
                        for b in det_result.detections:
                            p1 = (int(b.x1), int(b.y1))
                            p2 = (int(b.x2), int(b.y2))
                            color = (78, 222, 163) if event.crowd_level == "LOW" else (217, 119, 6) if event.crowd_level == "MODERATE" else (186, 26, 26)
                            cv2.rectangle(annotated, p1, p2, color, 2)

                        # HUD Overlay Box
                        cv2.rectangle(annotated, (15, 15), (420, 95), (0, 38, 32), -1)
                        cv2.rectangle(annotated, (15, 15), (420, 95), (0, 108, 73), 1)

                        hud_line1 = f"BUS {self.bus_number} | OCCUPANCY: {event.occupancy_percentage}% ({event.crowd_level})"
                        hud_line2 = f"PASSENGERS: {event.stabilized_person_count}/{self.capacity} (Raw: {event.raw_person_count})"
                        hud_line3 = f"FRAME: {frame_idx} | INFERENCE: {det_result.inference_time_ms:.1f}ms | ZERO BIOMETRICS"

                        cv2.putText(annotated, hud_line1, (25, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.52, (255, 255, 255), 1, cv2.LINE_AA)
                        cv2.putText(annotated, hud_line2, (25, 62), cv2.FONT_HERSHEY_SIMPLEX, 0.48, (78, 222, 163), 1, cv2.LINE_AA)
                        cv2.putText(annotated, hud_line3, (25, 84), cv2.FONT_HERSHEY_SIMPLEX, 0.40, (192, 200, 197), 1, cv2.LINE_AA)

                        writer.write(annotated)

                frame_idx += 1

        finally:
            cap.release()
            if writer is not None:
                writer.release()

        total_wall_sec = max(0.001, time.perf_counter() - start_wall_time)
        processing_fps = round(processed_count / total_wall_sec, 1)
        avg_inference_ms = round(sum(inference_times) / len(inference_times), 1) if inference_times else 0.0

        occupancy_pcts = [e.occupancy_percentage for e in events]
        peak_occ = max(occupancy_pcts) if occupancy_pcts else 0.0
        avg_occ = round(sum(occupancy_pcts) / len(occupancy_pcts), 1) if occupancy_pcts else 0.0

        return ReplaySummary(
            video_path=self.video_path,
            bus_number=self.bus_number,
            total_frames=total_frames,
            processed_frames=processed_count,
            video_fps=round(video_fps, 1),
            duration_seconds=round(duration_sec, 1),
            average_inference_ms=avg_inference_ms,
            processing_fps=processing_fps,
            peak_occupancy_pct=peak_occ,
            average_occupancy_pct=avg_occ,
            crowd_distribution=crowd_dist,
            events_published=len(events),
            device=self.detector.device.upper(),
            model="YOLOv8n",
        )

# ==========================================
# Replay CLI Development Command
# ==========================================

def run_cli():
    parser = argparse.ArgumentParser(
        description="BusSense AI - Computer Vision Video Replay Tool (Phase H8)"
    )
    parser.add_argument("--video", required=True, help="Path to input MP4 video file")
    parser.add_argument("--bus", default="205", help="Bus identifier code (default: 205)")
    parser.add_argument("--capacity", type=int, default=55, help="Vehicle capacity (default: 55)")
    parser.add_argument("--step", type=int, default=3, help="Process every Nth frame (default: 3)")
    parser.add_argument("--conf", type=float, default=0.40, help="Confidence threshold (default: 0.40)")
    parser.add_argument("--output", help="Optional output path for debug annotated video")
    parser.add_argument("--publish", action="store_true", help="Publish occupancy events to FastAPI backend")

    args = parser.parse_args()

    publish_cb = None
    if args.publish:
        import urllib.request
        import json
        def _publish_event(evt: OccupancyEvent):
            try:
                url = "http://localhost:8000/api/occupancy/events"
                payload = evt.model_dump() if hasattr(evt, "model_dump") else evt.dict()
                data = json.dumps(payload).encode("utf-8")
                req = urllib.request.Request(
                    url,
                    data=data,
                    headers={"Content-Type": "application/json"}
                )
                with urllib.request.urlopen(req, timeout=2.0) as resp:
                    pass
            except Exception as e:
                pass # Silently proceed if server not online during local CLI run
        publish_cb = _publish_event

    print("\n========================================================")
    print(" BusSense AI — Computer Vision Replay Pipeline (H8)")
    print(f" Target Video: {args.video}")
    print(f" Bus Number:   {args.bus} (Capacity: {args.capacity})")
    print(f" Frame Step:   Every {args.step} frames")
    print(f" Model:        YOLOv8n (Class 0: person only)")
    print(" Privacy:      ZERO BIOMETRICS • BODY COUNTING ONLY")
    print("========================================================\n")

    processor = VideoReplayProcessor(
        video_path=args.video,
        bus_number=args.bus,
        capacity=args.capacity,
        process_every_n_frames=args.step,
        confidence_threshold=args.conf,
        output_annotated_path=args.output,
        publish_callback=publish_cb,
    )

    summary = processor.process()

    print("\n========================================================")
    print(" Replay Execution Summary:")
    print(f" Total Frames:      {summary.total_frames} ({summary.duration_seconds}s @ {summary.video_fps} FPS)")
    print(f" Processed Frames:  {summary.processed_frames}")
    print(f" Device Used:       {summary.device}")
    print(f" Average Latency:   {summary.average_inference_ms} ms/frame")
    print(f" Processing Speed:  {summary.processing_fps} FPS")
    print(f" Average Occupancy: {summary.average_occupancy_pct}%")
    print(f" Peak Occupancy:    {summary.peak_occupancy_pct}%")
    print(f" Crowd Breakdown:   {summary.crowd_distribution}")
    if args.output:
        print(f" Annotated Video:   {args.output}")
    print("========================================================\n")

if __name__ == "__main__":
    run_cli()
