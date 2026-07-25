# 🚍 BusSense AI

> **Balancing Passenger Demand Across Public & Private Buses for Climate-Smart Mobility**

[![Vercel Deployment](https://img.shields.io/badge/Vercel-Deployed-black?logo=vercel&logoColor=white)](https://vercel.com)
[![Flutter Mobile App](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Python Backend](https://img.shields.io/badge/Python-3.10%2B-3776AB?logo=python&logoColor=white)](https://www.python.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing%20(100%25)-brightgreen)](tests/test_analytics.py)

BusSense AI is an end-to-end intelligent transit optimization system. It uses **YOLOv8 & OpenCV computer vision** on bus CCTV feeds to estimate passenger density in real time, serving privacy-friendly crowding analytics to **passengers** via a **Native Flutter Mobile App** and to **transport authorities** via an **Executive Analytics Dashboard**.

---

## 🌟 Key Features

### 📱 1. Native Passenger Mobile App (`mobile_app_flutter/`)
- **Real-Time Bus Tracking & Seat Availability**: Live occupancy levels (Green / Yellow / Red), seat probability formulas, and 15-min overcrowding risk forecasts.
- **Passenger Comfort Index**: Calculates trip comfort scores based on vehicle density and capacity.
- **Aesthetic Material 3 Interface**: Styled with Google Fonts (*Outfit* & *Plus Jakarta Sans*), supporting dark mode and multilingual toggles (English / Malayalam).
- **Less-Crowded Bus Recommendations**: Recommends alternative private or KSRTC public buses running on the same route to prevent overcrowding.
- **Emergency Reporting & Community Feedback**: Passenger reporting tool for overcrowding issues and emergency assistance.

### 📊 2. Transport Authority Control Dashboard (`dashboard/`)
- **Interactive Live Map**: Leaflet & OpenStreetMap fleet tracking with custom KSRTC / Private operator badges.
- **ML Demand Forecasting**: Random Forest model predicting route-wise passenger spikes during peak hours.
- **One-Click Dispatch Center**: Allows authority dispatchers to deploy extra relief buses to high-demand routes dynamically.
- **CSV & Analytics Reports**: Exports operational summaries, fuel savings, and CO₂ reduction metrics.

### 👁️ 3. Privacy-Preserving CCTV Occupancy Engine (`occupancy_detection/`)
- **YOLOv8 & OpenCV Pipeline**: Person-class object detection from video feeds.
- **100% Privacy Preserved**: Operates strictly on bounding-box counts without facial recognition, biometric tracking, or PII storage.

### ☁️ 4. Serverless & Cloud Ready
- **Vercel Cloud Deployment**: Configured via `vercel.json` and `api/index.py` for 1-click serverless backend deployment.
- **Docker Support**: Containerized setup via `Dockerfile` and `docker-compose.yml`.

---

## 📁 Repository Structure

```text
BusSenseAI/
├── api/                      # Vercel Serverless Function entry point & requirements
│   ├── index.py              # Serverless WSGI adapter for Flask
│   └── requirements.txt      # Optimized lightweight dependencies for cloud
├── backend/                  # Core Flask REST API & ML logic
│   ├── app.py                # Main REST API server & database routing
│   ├── analytics.py          # Random Forest passenger demand forecasting
│   ├── gps_simulator.py      # Deterministic vehicle GPS tracker simulation
│   ├── recommendation.py     # Passenger seat probability & alternative route algorithms
│   └── sustainability.py   # Fuel efficiency & CO₂ reduction calculations
├── mobile_app_flutter/       # Native Flutter Mobile Application
│   ├── lib/
│   │   ├── models/           # JSON parsers & bus metrics model
│   │   ├── providers/        # State management (BusProvider with ChangeNotifier)
│   │   ├── screens/          # MainNavigation, Home, LiveTracking, ProfileSettings
│   │   ├── services/         # HTTP REST API client
│   │   ├── theme/            # AppTheme Material 3 design system & Google Fonts
│   │   └── widgets/          # Aesthetic BusCardWidget & custom UI components
│   └── pubspec.yaml          # Flutter dependencies configuration
├── dashboard/                # Authority Control Panel (HTML5 / CSS3 / JavaScript)
│   ├── index.html            # Dashboard UI structure
│   ├── styles.css            # Dark glassmorphism styling
│   └── app.js                # Leaflet maps, Chart.js graphs, & dispatch triggers
├── mobile_app/               # Passenger Web App Simulator (HTML/CSS/JS)
├── database/                 # Database scripts
│   ├── schema.sql            # SQLite relational table schemas
│   └── bussense.db           # Auto-seeded SQLite database
├── occupancy_detection/      # Computer vision detection pipeline
│   ├── detect_occupancy.py   # OpenCV HOG + MOG2 fallback detector
│   └── yolov8_detector.py   # YOLOv8 neural network person detector
├── datasets/                 # Demo datasets & CCTV synthetic video generator
├── tests/                    # Pytest unit testing suite
├── vercel.json               # Vercel deployment configuration
├── Dockerfile                # Docker container build script
└── README.md                 # Project documentation
```

---

## ⚡ Quick Start Guide

### Option A: 1-Click Vercel Cloud Deployment

1. Fork or push this repo to **GitHub**.
2. Visit [Vercel New Project](https://vercel.com/new).
3. Import `Antony0610/BusSense-AI` and click **Deploy**.

> Vercel automatically deploys the **Flask REST API** (`/api/*`), the **Authority Dashboard** (`/dashboard`), and the **Mobile Web Simulator** (`/mobile_app`).

---

### Option B: Native Flutter Mobile App Setup

#### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0 or higher)
- Android Studio / Xcode or VS Code with Flutter extension

```bash
# Navigate to the Flutter project
cd mobile_app_flutter

# Install packages
flutter pub get

# Run on emulator or connected device
flutter run

# Build Production Release APK
flutter build apk --release
```

---

### Option C: Local Backend Execution (Python)

```bash
# Clone the repository
git clone https://github.com/Antony0610/BusSense-AI.git
cd BusSense-AI

# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.\.venv\Scripts\activate
# Linux/macOS:
# source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run Flask server
python backend/app.py
```

Local access endpoints:
- **REST API Health**: `http://localhost:5000/api/health`
- **Authority Dashboard**: `http://localhost:5000/dashboard/index.html`
- **Mobile Web Simulator**: `http://localhost:5000/mobile_app/index.html`

---

### Option D: Docker Deployment

```bash
docker compose up --build
```
Access the application at `http://localhost:5000`.

---

## 📡 REST API Reference

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/health` | API system status and database check |
| `GET` | `/api/buses` | Real-time list of all active buses, passenger count, seat availability, and simulated GPS |
| `GET` | `/api/stats` | Route occupancy stats, alerts, fuel saved (L), and CO₂ reduced (kg) |
| `GET` | `/api/demand` | ML-predicted passenger demand by route |
| `GET` | `/api/recommend-buses` | Recommends less-crowded alternative buses for a given route |
| `POST` | `/api/dispatch` | Authority trigger to dispatch extra relief buses to crowded routes |
| `POST` | `/api/report` | Submit passenger feedback or emergency overcrowding reports |

---

## 🧪 Testing & Verification

Run the automated test suite to verify analytics, predictions, and recommendations:

```bash
pytest tests/test_analytics.py
```

**Test Status**: `5 / 5 tests passed (100%)`.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.

Developed with ❤️ for **Climate-Smart Public Mobility**.
