# BusSense AI: Balancing Passenger Demand Across Public and Private Buses for Climate-Smart Mobility

BusSense AI is a final-year engineering prototype that estimates bus occupancy from CCTV footage and shares privacy-friendly crowding analytics with passengers and transport authorities.

## Folder Structure

```text
BusSenseAI/
├── backend/                  # Flask API and analytics helpers
├── occupancy_detection/      # Python/OpenCV CCTV passenger counting
├── dashboard/                # Authority dashboard web UI
├── mobile_app/               # Passenger mobile web app prototype
├── database/                 # SQLite schema and generated database
├── datasets/                 # Demo KSRTC/private bus occupancy data
├── reports/                  # Architecture and project notes
├── requirements.txt          # Python dependencies
└── README.md
```

## Features

- AI occupancy detection with Python and OpenCV full-body detection.
- No facial recognition; frames are processed locally and not stored by default.
- Flask cloud-backend prototype with SQLite storage.
- Authority dashboard for live occupancy, bus list, route statistics, alerts, history charts, fuel savings, and CO₂ reduction.
- Passenger app prototype for crowd level, ETA, less-crowded alternatives, and seat availability prediction.
- Analytics for overcrowded buses, underutilized buses, peak demand, and route optimization recommendations.
- Demo dataset covering KSRTC and private buses across multiple routes and occupancy levels.

## Setup

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

## Occupancy Detection Demo

```bash
python occupancy_detection/detect_occupancy.py path/to/bus_cctv.mp4 --capacity 50 --output reports/latest_occupancy.json
```

The detector returns `passenger_count`, `occupancy_percentage`, and `seat_availability`. For production use, replace the default OpenCV HOG detector with a bus-interior person detector validated on local CCTV angles.

## API Endpoints

| Method | Endpoint | Purpose |
| --- | --- | --- |
| GET | `/api/health` | Check API and database status |
| GET | `/api/buses` | Latest bus occupancy and crowd level |
| GET | `/api/occupancy` | Recent historical occupancy records |
| GET | `/api/occupancy?bus_id=KSRTC-101` | History for one bus |
| POST | `/api/occupancy` | Store a new passenger count event |
| GET | `/api/stats` | Route stats, alerts, utilization, fuel and CO₂ savings |
| GET | `/api/recommendations` | Route optimization recommendations |

Example POST:

```bash
curl -X POST http://localhost:5000/api/occupancy \
  -H 'Content-Type: application/json' \
  -d '{"bus_id":"KSRTC-101","passenger_count":44,"latitude":8.5241,"longitude":76.9366,"source":"opencv"}'
```

## Database Schema

SQLite database tables are defined in `database/schema.sql`:

- `buses`: bus metadata including bus ID, operator type, route number, capacity, and registration number.
- `occupancy_records`: timestamped GPS location, passenger count, occupancy percentage, seat availability, and data source.

## Dashboard Metrics

- Occupancy percentage.
- Number of passengers.
- Bus utilization score.
- Estimated fuel savings.
- Estimated CO₂ reduction.

## Climate-Smart Assumptions

The prototype estimates fuel and CO₂ savings from better balancing of underutilized and overcrowded buses. The dashboard uses a demonstration factor of 2.68 kg CO₂ per litre of diesel saved; transport authorities should calibrate this with fleet-specific fuel economy and route data.
