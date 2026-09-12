# 📦 BusSense AI 2.0: Dependency Catalog & Installation Guide

> **100% Free & Open-Source Software (FOSS) Matrix**  
> *Zero Paid API Keys | Zero Proprietary Licenses | Zero Cloud Inference Costs*

---

## 🐍 1. Python Backend & AI Engine Dependencies

All Python dependencies are free, open-source, and compatible with Python 3.10 – 3.14.

| Package | Version | License | Purpose in BusSense AI | Installation Command |
| :--- | :--- | :--- | :--- | :--- |
| **`fastapi`** | `^0.115.0` | MIT | High-performance asynchronous REST API framework | `pip install fastapi` |
| **`uvicorn[standard]`** | `^0.32.0` | BSD-3-Clause | ASGI web server with WebSocket support | `pip install "uvicorn[standard]"` |
| **`pydantic`** | `^2.9.0` | MIT | Strict data validation and schema serialization | `pip install pydantic` |
| **`pydantic-settings`**| `^2.6.0` | MIT | Environment variable loading from `.env` | `pip install pydantic-settings` |
| **`supabase`** | `^2.10.0` | MIT | Official Supabase Python client (PostgREST, Auth, Realtime) | `pip install supabase` |
| **`scikit-learn`** | `^1.5.2` | BSD-3-Clause | Pre-trained Random Forest for transit demand prediction | `pip install scikit-learn` |
| **`numpy`** | `^2.1.0` | BSD-3-Clause | High-speed vector and coordinate matrix operations | `pip install numpy` |
| **`pandas`** | `^2.2.3` | BSD-3-Clause | Historical occupancy series aggregation and formatting | `pip install pandas` |
| **`ultralytics`** | `^8.3.0` | AGPL-3.0 | YOLOv8-Nano object detection (person-class counting) | `pip install ultralytics` |
| **`opencv-python`** | `^4.10.0` | Apache 2.0 | Video stream reading, face & license plate blurring | `pip install opencv-python` |
| **`pytest`** | `^8.3.0` | MIT | Automated test suite execution | `pip install pytest` |
| **`httpx`** | `^0.27.2` | BSD-3-Clause | Async HTTP client for test requests and telemetry ingest | `pip install httpx` |

### Consolidated Installation:
```bash
pip install -r requirements.txt
```

---

## 🌐 2. Authority Command Center (Web Frontend)

Zero paid mapping libraries or analytics platforms.

| Technology / Library | Version / Source | License | Purpose in Dashboard |
| :--- | :--- | :--- | :--- |
| **Leaflet.js** | `v1.9.4` (CDN / npm) | BSD-2-Clause | Lightweight interactive map engine |
| **CartoDB Dark Matter** | Carto CDN (Free) | Creative Commons (CC BY 3.0) | High-contrast dark vector map tiles (Zero API key needed) |
| **Chart.js** | `v4.4.4` (CDN / npm) | MIT | Real-time demand forecasting and occupancy distribution charts |
| **@supabase/supabase-js**| `^2.45.0` (CDN / npm)| MIT | Client-side Supabase Auth, PostgREST queries, and Realtime WebSocket CDC |
| **Google Fonts (Outfit & Plus Jakarta Sans)** | Google Fonts CDN | Open Font License (OFL) | High-aesthetic executive typography system |
| **Web Audio API** | Native Browser API | W3C Standard | Procedural audio chimes for dispatches and SOS emergency sirens |

---

## 📱 3. Passenger Mobile Applications

### A. Mobile Web PWA (`mobile_app/`)
| Component | Source / Standard | License | Purpose |
| :--- | :--- | :--- | :--- |
| **Progressive Web App (PWA)** | W3C Web App Manifest & Service Workers | Free Open Web | Zero-install offline-capable smartphone experience |
| **HTML5 Geolocation API** | Native Browser API | W3C Standard | Live GPS proximity calculation to nearest Kerala transit stops |
| **QRCode.js** | CDN / MIT | MIT | Dynamic client-side holographic QR ticket rendering |

### B. Native Flutter Application (`mobile_app_flutter/`)
Configured in `mobile_app_flutter/pubspec.yaml`:
| Flutter Package | Version | License | Purpose |
| :--- | :--- | :--- | :--- |
| **`flutter`** | `sdk: flutter` (v3.x) | BSD-3-Clause | Native cross-platform rendering engine |
| **`supabase_flutter`** | `^2.8.0` | MIT | Supabase Auth, Realtime, and Database client for Dart |
| **`provider`** | `^6.1.2` | MIT | Reactive state management for live bus streams and theme toggle |
| **`google_fonts`** | `^6.2.1` | OFL | Typography rendering for Material 3 design system |
| **`qr_flutter`** | `^4.1.0` | BSD-3-Clause | Native cryptographic QR ticket pass rendering |
| **`flutter_map`** | `^7.0.0` | BSD-3-Clause | OpenStreetMap / CartoDB map rendering in Flutter |
| **`latlong2`** | `^0.9.1` | Apache 2.0 | Geodetic calculations and coordinate distance utilities |
| **`intl`** | `^0.19.0` | BSD-3-Clause | Number formatting and Malayalam/English localization |

---

## 🗄️ 4. Database & Infrastructure

| Technology | Distribution | License | Purpose |
| :--- | :--- | :--- | :--- |
| **PostgreSQL** | `16.x` | PostgreSQL License (FOSS) | Core relational ACID database engine |
| **PostGIS** | `3.4+` | GNU GPL v2 | Spatial geometry indexing, line string paths, and distance queries |
| **Supabase Core** | Cloud (Free Tier) / Docker (Self-Hosted) | Apache 2.0 / MIT | Auth, Auto-generated REST API, Realtime WebSockets |
| **Docker & Docker Compose** | `24+` / Compose v2 | Apache 2.0 | Multi-container local execution |
