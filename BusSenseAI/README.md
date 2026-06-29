# BusSense AI: Balancing Passenger Demand Across Public and Private Buses for Climate-Smart Mobility

BusSense AI is a final-year engineering prototype that estimates bus occupancy from CCTV footage and shares privacy-friendly crowding analytics with passengers and transport authorities.

## Folder Structure

```text
BusSenseAI/
├── backend/                  # Flask API, Random Forest analytics, GPS simulation, recommendations, sustainability metrics
├── occupancy_detection/      # OpenCV and YOLOv8 CCTV passenger counting
├── dashboard/                # Authority dashboard with charts and live map
├── mobile_app/               # Passenger mobile web app prototype
├── database/                 # SQLite schema and generated database
├── datasets/                 # Demo KSRTC/private data and sample video generator
├── reports/                  # Architecture and deployment notes
├── tests/                    # Unit tests for analytics modules
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── README.md
```

## Features

- YOLOv8 passenger detection from CCTV video, plus a lightweight OpenCV fallback detector.
- Privacy-friendly processing: person-class counting only; no facial recognition, biometric templates, or identity storage.
- Flask backend with SQLite for bus metadata, GPS-tagged occupancy records, route stats, demand prediction, recommendations, and sustainability metrics.
- Real-time authority dashboard with live bus table, route occupancy charts, demand prediction chart, overcrowding alerts, less-crowded bus suggestions, and an interactive Leaflet/OpenStreetMap live bus map.
- Passenger mobile web app with Green/Yellow/Red crowd level, ETA, live location, seat availability prediction, and less-crowded alternatives.
- Random Forest demand prediction when `scikit-learn` is installed, with a moving-average fallback for easy classroom execution.
- Deterministic GPS simulator for live bus movement demos.
- Fuel savings, CO₂ reduction, and Bus Utilization Score modules.
- Unit tests and a synthetic sample video generator for demonstration.

## Setup Without Docker

```bash
cd BusSenseAI
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python backend/app.py
```

Open:

- Backend health: <http://localhost:5000/api/health>
- Authority dashboard: <http://localhost:5000/dashboard/index.html>
- Passenger app: open `mobile_app/index.html` in a browser while the Flask API is running.

## Docker Deployment

```bash
cd BusSenseAI
docker compose up --build
```

The API and dashboard will be available at <http://localhost:5000>. More notes are in `reports/deployment.md`.

## YOLOv8 Occupancy Detection Demo

Generate a synthetic demo video:

```bash
python datasets/generate_sample_video.py
```

Run YOLOv8 person detection:

```bash
python occupancy_detection/yolov8_detector.py datasets/sample_bus_cctv.mp4 --capacity 50 --json-output reports/latest_occupancy.json
```

Optional OpenCV fallback:

```bash
python occupancy_detection/detect_occupancy.py datasets/sample_bus_cctv.mp4 --capacity 50 --output reports/latest_occupancy.json
```

Both detectors return `passenger_count`, `occupancy_percentage`, and `seat_availability`. For production use, validate YOLO on local bus CCTV angles and run inference on an edge device that sends only aggregate counts to the backend.

## API Endpoints

| Method | Endpoint | Purpose |
| --- | --- | --- |
| GET | `/api/health` | Check API and database status |
| GET | `/api/buses` | Latest bus occupancy, simulated GPS, ETA, crowd level, and utilization score |
| GET | `/api/occupancy` | Recent historical occupancy records |
| GET | `/api/occupancy?bus_id=KSRTC-101` | History for one bus |
| POST | `/api/occupancy` | Store a new passenger count event |
| GET | `/api/stats` | Route stats, alerts, utilization, fuel and CO₂ savings |
| GET | `/api/demand` | Random Forest or moving-average demand prediction by route |
| GET | `/api/locations` | Simulated live GPS locations |
| GET | `/api/recommend-buses?route_number=R1` | Less-crowded passenger bus recommendations |
| GET | `/api/recommendations` | Authority route optimization recommendations |

Example POST from detector output:

```bash
curl -X POST http://localhost:5000/api/occupancy \
  -H 'Content-Type: application/json' \
  -d '{"bus_id":"KSRTC-101","passenger_count":44,"latitude":8.5241,"longitude":76.9366,"source":"yolov8"}'
```

## Database Schema

SQLite database tables are defined in `database/schema.sql`:

- `buses`: bus metadata including bus ID, operator type, route number, capacity, and registration number.
- `occupancy_records`: timestamped GPS location, passenger count, occupancy percentage, seat availability, and data source.

## Dashboard Metrics

- Occupancy percentage and passenger count.
- Bus Utilization Score: occupancy normalized to an 85% target, capped at 100.
- Estimated fuel savings in litres.
- Estimated CO₂ reduction using 2.68 kg CO₂ per litre of diesel.
- Route-wise historical occupancy and predicted demand.
- Live GPS positions on an interactive map.

## Testing

```bash
python -m compileall backend occupancy_detection datasets tests
pytest
```

The pure analytics tests do not require Flask or YOLO. Full video inference requires installing `ultralytics` and OpenCV from `requirements.txt`.
