"""Generate a lightweight synthetic bus CCTV-style sample video for demos/tests."""
from __future__ import annotations

from pathlib import Path
import cv2
import numpy as np


def generate(path: str = "datasets/sample_bus_cctv.mp4", seconds: int = 4, fps: int = 10) -> Path:
    output = Path(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    width, height = 640, 360
    writer = cv2.VideoWriter(str(output), cv2.VideoWriter_fourcc(*"mp4v"), fps, (width, height))
    for frame_no in range(seconds * fps):
        frame = np.full((height, width, 3), (235, 241, 238), dtype=np.uint8)
        cv2.rectangle(frame, (30, 40), (610, 320), (210, 220, 218), 3)
        for seat_x in range(80, 560, 80):
            cv2.rectangle(frame, (seat_x, 230), (seat_x + 42, 285), (160, 180, 190), -1)
        people = 5 + (frame_no // 10) % 4
        for idx in range(people):
            x = 90 + idx * 70 + (frame_no % 8)
            y = 95 + (idx % 2) * 32
            cv2.circle(frame, (x, y), 14, (80, 90, 130), -1)
            cv2.rectangle(frame, (x - 12, y + 14), (x + 12, y + 70), (40, 130, 190), -1)
        cv2.putText(frame, "Synthetic Bus CCTV Demo", (30, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 95, 85), 2)
        writer.write(frame)
    writer.release()
    return output


if __name__ == "__main__":
    print(generate())
