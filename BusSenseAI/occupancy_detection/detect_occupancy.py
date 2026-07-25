"""Privacy-friendly bus passenger counter using OpenCV person detection.

The script processes frames locally, counts full-body person detections, and never
stores faces or biometric identifiers. For a stronger production model, replace
HOG with a bus-specific YOLO/SSD person detector trained on privacy-reviewed data.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import cv2


def estimate_occupancy(video_path: str, capacity: int, sample_every: int = 15, display: bool = False) -> dict:
    HOG = getattr(cv2, 'HOGDescriptor', None) or getattr(getattr(cv2, 'objdetect', None), 'HOGDescriptor', None)
    if HOG:
        detector = HOG()
        detector.setSVMDetector(HOG.getDefaultPeopleDetector() if hasattr(HOG, 'getDefaultPeopleDetector') else HOG_getDefaultPeopleDetector())
    else:
        detector = None

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise FileNotFoundError(f"Unable to open video: {video_path}")

    frame_index = 0
    counts: list[int] = []
    bg_subtractor = cv2.createBackgroundSubtractorMOG2(history=500, varThreshold=50, detectShadows=False)

    while True:
        ok, frame = cap.read()
        if not ok:
            break
        if frame_index % sample_every == 0:
            resized = cv2.resize(frame, (640, 360))
            if detector is not None:
                try:
                    boxes, _ = detector.detectMultiScale(resized, winStride=(8, 8), padding=(8, 8), scale=1.05)
                    passenger_count = len(boxes)
                except Exception:
                    fg = bg_subtractor.apply(resized)
                    contours, _ = cv2.findContours(fg, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
                    passenger_count = len([c for c in contours if cv2.contourArea(c) > 300])
            else:
                fg = bg_subtractor.apply(resized)
                contours, _ = cv2.findContours(fg, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
                passenger_count = len([c for c in contours if cv2.contourArea(c) > 300])

            counts.append(passenger_count)
            if display:
                cv2.putText(resized, f"Passengers: {passenger_count}", (20, 35), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 180, 0), 2)
                cv2.imshow("BusSense AI Occupancy", resized)
                if cv2.waitKey(1) & 0xFF == ord("q"):
                    break
        frame_index += 1


    cap.release()
    if display:
        cv2.destroyAllWindows()

    passenger_count = round(sum(counts) / len(counts)) if counts else 0
    occupancy_percentage = round((passenger_count / capacity) * 100, 2) if capacity else 0
    return {
        "passenger_count": passenger_count,
        "occupancy_percentage": occupancy_percentage,
        "seat_availability": max(capacity - passenger_count, 0),
        "privacy_note": "Local full-body detection only; no facial recognition or identity storage.",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Estimate bus occupancy from CCTV video.")
    parser.add_argument("video", help="Path to CCTV video file")
    parser.add_argument("--capacity", type=int, default=50, help="Bus seat/passenger capacity")
    parser.add_argument("--sample-every", type=int, default=15, help="Process every Nth frame")
    parser.add_argument("--display", action="store_true", help="Show annotated preview window")
    parser.add_argument("--output", type=Path, help="Optional JSON output file")
    args = parser.parse_args()
    result = estimate_occupancy(args.video, args.capacity, args.sample_every, args.display)
    print(json.dumps(result, indent=2))
    if args.output:
        args.output.write_text(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
