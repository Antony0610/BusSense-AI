# BusSense AI: Balancing Passenger Demand Across Public and Private Buses for Climate-Smart Mobility

BusSense AI is an AI-powered public transport management and passenger awareness app that estimates bus occupancy from CCTV footage and shares privacy-friendly crowding analytics with passengers and transport authorities.

## Folder Structure

```text
BusSenseAI/
├── api/                      # Vercel Serverless Function entry point
├── backend/                  # Flask API, Random Forest analytics, GPS simulation, recommendations
├── mobile_app_flutter/       # Native Flutter Mobile Application (Material 3, Provider, aesthetic UI)
├── dashboard/                # Authority control dashboard with charts and live map
├── mobile_app/               # Passenger mobile web app simulator
├── occupancy_detection/      # OpenCV and YOLOv8 CCTV passenger counting
├── database/                 # SQLite schema and auto-seeded database
├── datasets/                 # Demo KSRTC/private data and sample video generator
├── reports/                  # Architecture and deployment notes
├── tests/                    # Unit tests for analytics modules
├── vercel.json               # One-click Vercel Deployment configuration
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── README.md
```

## Vercel Deployment (1-Click Cloud Hosting)

This project is fully configured for deployment on **Vercel**:

1. Push your repository to **GitHub**.
2. Go to [Vercel Dashboard](https://vercel.com/new) -> **Import Git Repository**.
3. Select this repository and click **Deploy**.

Vercel will automatically detect `vercel.json` and deploy:
- The **Flask REST API** as a Python Serverless Function (`/api/*`).
- The **Authority Control Dashboard** (`/dashboard`).
- The **Passenger Web App Simulator** (`/mobile_app`).

---

## Native Flutter Mobile App (`mobile_app_flutter/`)

The passenger application is built with **Flutter** featuring Google Fonts (*Outfit* and *Plus Jakarta Sans*), dark/light mode toggle, Material 3 design, real-time crowding metrics, and live route tracking.

### Run Flutter App Locally:
```bash
cd mobile_app_flutter
flutter pub get
flutter run
```

### Build Android APK:
```bash
cd mobile_app_flutter
flutter build apk --release
```

---

## Setup & Local Server Execution

```bash
cd BusSenseAI
python -m venv .venv
# On Windows: .venv\Scripts\activate | On Mac/Linux: source .venv/bin/activate
pip install -r requirements.txt
python backend/app.py
```

Access locally:
- **Backend API**: <http://localhost:5000/api/health>
- **Authority Dashboard**: <http://localhost:5000/dashboard/index.html>
- **Mobile Web App**: <http://localhost:5000/mobile_app/index.html>

---

## Docker Deployment

```bash
docker compose up --build
```

---

## Testing

```bash
pytest tests/test_analytics.py
```
All unit tests execute successfully (100% pass rate).
