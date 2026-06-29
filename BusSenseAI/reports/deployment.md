# Deployment Notes

## Local Docker

```bash
cd BusSenseAI
docker compose up --build
```

Open the dashboard at <http://localhost:5000/dashboard/index.html>.

## Classroom Demo Flow

1. Generate a sample video with `python datasets/generate_sample_video.py`.
2. Run YOLOv8 detection with `python occupancy_detection/yolov8_detector.py datasets/sample_bus_cctv.mp4 --capacity 50`.
3. Start the Flask API with Docker Compose or `python backend/app.py`.
4. Open the authority dashboard and passenger app.

## Production Hardening Ideas

- Replace SQLite with PostgreSQL/PostGIS for multi-depot deployments.
- Move YOLO inference to bus edge devices and send only aggregate occupancy events.
- Add authentication for authority users.
- Store model and detector versions with every occupancy event for auditability.
