"""
BusSense AI - Sample Bus Video Generator
Creates a deterministic MP4 video for local offline replay and testing.
Saves to: datasets/videos/sample_bus.mp4
Uses real photographic imagery from Ultralytics assets with smooth perspective panning.
"""
import os
import cv2
import numpy as np
from pathlib import Path

def generate_sample_bus_video(
    output_path: str = "datasets/videos/sample_bus.mp4",
    num_frames: int = 60,
    fps: int = 20,
    target_width: int = 640,
    target_height: int = 480
):
    out_file = Path(output_path)
    out_file.parent.mkdir(parents=True, exist_ok=True)

    # Locate real bus.jpg from Ultralytics package
    asset_path = None
    try:
        import ultralytics
        candidate = Path(ultralytics.__file__).parent / "assets" / "bus.jpg"
        if candidate.exists():
            asset_path = candidate
    except Exception:
        pass

    if asset_path and asset_path.exists():
        src_img = cv2.imread(str(asset_path))
    else:
        # Fallback to gradient synthetic frame if asset missing
        src_img = np.full((720, 960, 3), (40, 50, 45), dtype=np.uint8)

    src_h, src_w = src_img.shape[:2]
    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(str(out_file), fourcc, float(fps), (target_width, target_height))

    if not writer.isOpened():
        raise RuntimeError(f"Could not open VideoWriter for {output_path}")

    # Generate subtle camera vibration & panning across the scene
    for i in range(num_frames):
        t = i / float(num_frames)
        # Smooth pan across scene
        shift_x = int(np.sin(t * np.pi) * 30.0)
        shift_y = int(np.cos(t * np.pi * 2.0) * 10.0)

        crop_w = int(src_w * 0.90)
        crop_h = int(src_h * 0.90)
        start_x = max(0, min(src_w - crop_w, int((src_w - crop_w) / 2) + shift_x))
        start_y = max(0, min(src_h - crop_h, int((src_h - crop_h) / 2) + shift_y))

        cropped = src_img[start_y:start_y + crop_h, start_x:start_x + crop_w]
        resized = cv2.resize(cropped, (target_width, target_height), interpolation=cv2.INTER_LINEAR)

        # Add subtle Kerala transit timestamp / watermark
        cv2.putText(
            resized,
            f"BUSSENSE CV CAM 01 - SEC {i/fps:.1f}",
            (16, target_height - 18),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.45,
            (230, 240, 235),
            1,
            cv2.LINE_AA
        )

        writer.write(resized)

    writer.release()
    print(f"Sample bus video successfully created at: {out_file} ({num_frames} frames, {fps} fps)")

if __name__ == "__main__":
    generate_sample_bus_video()
