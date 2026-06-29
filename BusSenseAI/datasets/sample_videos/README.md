# Sample CCTV Videos

Large binary videos are intentionally not committed. Generate lightweight synthetic sample videos locally after installing dependencies:

```bash
cd BusSenseAI
python datasets/generate_sample_video.py
```

This creates `datasets/sample_bus_cctv.mp4`, a short bus-interior-style demo clip with animated passenger silhouettes for YOLOv8/OpenCV detector demonstrations.
