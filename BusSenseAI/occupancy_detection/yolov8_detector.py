"""YOLOv8 passenger detection for bus CCTV footage.

Requires `ultralytics` from requirements.txt. The detector uses the COCO `person`
class only and stores aggregate counts, not faces or identities.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import cv2

try:
    from ultralytics import YOLO
except ImportError as exc:  # clear classroom-friendly error
    raise SystemExit("Install dependencies first: pip install -r requirements.txt") from exc

PERSON_CLASS_ID = 0


def detect_video(video_path: str, capacity: int, model_name: str = "yolov8n.pt", sample_every: int = 10, output_video: str | None = None) -> dict:
    model = YOLO(model_name)
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise FileNotFoundError(f"Unable to open video: {video_path}")

    writer = None
    if output_video:
        fps = cap.get(cv2.CAP_PROP_FPS) or 20
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        writer = cv2.VideoWriter(output_video, cv2.VideoWriter_fourcc(*"mp4v"), fps, (width, height))

    frame_index = 0
    counts: list[int] = []
    while True:
        ok, frame = cap.read()
        if not ok:
            break
        if frame_index % sample_every == 0:
            result = model.predict(frame, classes=[PERSON_CLASS_ID], conf=0.35, verbose=False)[0]
            count = len(result.boxes)
            counts.append(count)
            annotated = result.plot()
            cv2.putText(annotated, f"Passengers: {count}", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            if writer:
                writer.write(annotated)
        elif writer:
            writer.write(frame)
        frame_index += 1

    cap.release()
    if writer:
        writer.release()

    passenger_count = round(sum(counts) / len(counts)) if counts else 0
    occupancy_percentage = round((passenger_count / capacity) * 100, 2) if capacity else 0
    return {
        "model": model_name,
        "passenger_count": passenger_count,
        "occupancy_percentage": occupancy_percentage,
        "seat_availability": max(capacity - passenger_count, 0),
        "frames_sampled": len(counts),
        "privacy_note": "YOLO person-class counting only; no facial recognition or biometric storage.",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="YOLOv8 bus passenger occupancy detector")
    parser.add_argument("video")
    parser.add_argument("--capacity", type=int, default=50)
    parser.add_argument("--model", default="yolov8n.pt")
    parser.add_argument("--sample-every", type=int, default=10)
    parser.add_argument("--output-video")
    parser.add_argument("--json-output", type=Path)
    args = parser.parse_args()
    result = detect_video(args.video, args.capacity, args.model, args.sample_every, args.output_video)
    print(json.dumps(result, indent=2))
    if args.json_output:
        args.json_output.write_text(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
