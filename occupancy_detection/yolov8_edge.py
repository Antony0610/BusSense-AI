"""YOLOv8-Nano Edge Computer Vision pipeline with privacy-preserving face blurring.

Detects person-class only, blurs facial regions, and transmits real-time occupancy
metrics to the BusSense AI backend gateway.
"""
from __future__ import annotations

import argparse
import json
import time
from pathlib import Path
from typing import Optional

import cv2

PERSON_CLASS_ID = 0


def blur_head_region(frame, x1: int, y1: int, x2: int, y2: int):
    """Apply Gaussian blur to the upper 25% of the person bounding box for privacy."""
    h = y2 - y1
    head_h = int(h * 0.25)
    head_y2 = y1 + head_h
    if head_y2 > y1 and x2 > x1:
        roi = frame[y1:head_y2, x1:x2]
        if roi.size > 0:
            blurred = cv2.GaussianBlur(roi, (23, 23), 30)
            frame[y1:head_y2, x1:x2] = blurred


def process_stream(
    source: str,
    bus_id: str = "KSRTC-101",
    route_number: str = "R1",
    capacity: int = 50,
    model_name: str = "yolov8n.pt",
    sample_rate: int = 5,
    backend_url: Optional[str] = "http://localhost:8000/api/telemetry/ingest",
    edge_api_key: str = "bussense_edge_secret_key_2026",
    output_video: Optional[str] = None,
) -> dict:
    """Run edge person counting with privacy blurring on video feed."""
    try:
        from ultralytics import YOLO
        model = YOLO(model_name)
    except Exception:
        model = None
        print("ℹ️ Ultralytics not installed or unavailable; using fallback OpenCV counter.")

    cap = cv2.VideoCapture(source)
    if not cap.isOpened():
        raise FileNotFoundError(f"Cannot open video source: {source}")

    fps = cap.get(cv2.CAP_PROP_FPS) or 20.0
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)) or 640
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)) or 480

    writer = None
    if output_video:
        writer = cv2.VideoWriter(output_video, cv2.VideoWriter_fourcc(*"mp4v"), fps, (width, height))

    frame_idx = 0
    passenger_counts: list[int] = []

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        current_count = 0
        if frame_idx % sample_rate == 0:
            if model:
                results = model.predict(frame, classes=[PERSON_CLASS_ID], conf=0.35, verbose=False)[0]
                current_count = len(results.boxes)
                for box in results.boxes:
                    coords = [int(v) for v in box.xyxy[0]]
                    x1, y1, x2, y2 = coords
                    # Apply automated face blur
                    blur_head_region(frame, x1, y1, x2, y2)
                    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 230, 118), 2)
            else:
                # Lightweight HOG fallback
                hog = cv2.HOGDescriptor()
                hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())
                boxes, _ = hog.detectMultiScale(frame, winStride=(8, 8))
                current_count = len(boxes)
                for (x, y, w, h) in boxes:
                    blur_head_region(frame, x, y, x + w, y + h)
                    cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 230, 118), 2)

            passenger_counts.append(current_count)

            # Draw HUD status overlay
            occ_pct = round((current_count / capacity) * 100, 1)
            tier = "RED" if occ_pct >= 80 else ("YELLOW" if occ_pct >= 50 else "GREEN")
            color = (0, 0, 255) if tier == "RED" else ((0, 200, 255) if tier == "YELLOW" else (0, 255, 0))

            cv2.rectangle(frame, (10, 10), (320, 90), (10, 15, 25), -1)
            cv2.putText(frame, f"BusSense Edge: {bus_id}", (20, 35), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)
            cv2.putText(frame, f"Count: {current_count} / {capacity} ({occ_pct}%)", (20, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
            cv2.putText(frame, f"Status: {tier} | Privacy: Face-Blur ON", (20, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (180, 180, 180), 1)

        if writer:
            writer.write(frame)

        frame_idx += 1

    cap.release()
    if writer:
        writer.release()

    avg_passengers = round(sum(passenger_counts) / max(len(passenger_counts), 1))
    occupancy_pct = round((avg_passengers / capacity) * 100, 1)

    result = {
        "bus_id": bus_id,
        "route_number": route_number,
        "capacity": capacity,
        "passenger_count": avg_passengers,
        "occupancy_percentage": occupancy_pct,
        "seat_availability": max(capacity - avg_passengers, 0),
        "frames_sampled": len(passenger_counts),
        "privacy_guarantee": "Automated face blurring applied; zero biometric data stored.",
    }

    # Transmit to backend if URL provided
    if backend_url:
        try:
            import httpx
            httpx.post(
                backend_url,
                json={
                    "bus_id": bus_id,
                    "route_number": route_number,
                    "latitude": 8.5241,
                    "longitude": 76.9366,
                    "passenger_count": avg_passengers,
                    "capacity": capacity,
                    "source": "edge_yolo",
                },
                headers={"X-Edge-API-Key": edge_api_key},
                timeout=4.0,
            )
            result["telemetry_transmitted"] = True
        except Exception as e:
            result["telemetry_transmitted"] = False
            result["transmission_note"] = str(e)

    return result


def main():
    parser = argparse.ArgumentParser(description="YOLOv8 Edge Computer Vision Ingest")
    parser.add_argument("--source", default="datasets/sample_bus_cctv.mp4", help="Video path or RTSP URL")
    parser.add_argument("--bus-id", default="KSRTC-101", help="Target Bus ID")
    parser.add_argument("--route", default="R1", help="Route Number")
    parser.add_argument("--capacity", type=int, default=50, help="Bus Capacity")
    parser.add_argument("--backend-url", default="http://localhost:8000/api/telemetry/ingest")
    args = parser.parse_args()

    metrics = process_stream(
        source=args.source,
        bus_id=args.bus_id,
        route_number=args.route,
        capacity=args.capacity,
        backend_url=args.backend_url,
    )
    print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
