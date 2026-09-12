# 🧠 BusSense AI 2.0: Master Execution Memory & Runbook

> **Authoritative System Runbook & Historical Log**  
> *Last Updated: 2026-09-12*  
> *Target Architecture: Supabase PostgreSQL 16 + PostGIS, FastAPI, Modern React HUD, Flutter 3.x Native & Mobile PWA*

---

## 📌 1. Project Overview & Guiding Principles

BusSense AI 2.0 is an intelligent, climate-smart transit ecosystem designed to balance passenger demand across public (KSRTC) and private bus fleets in Kerala, India.

### Core Non-Negotiables:
1. **Strict Zero-Dummy / 100% Real Execution**:
   - Zero mock data arrays or fake UI buttons.
   - Real database records for tickets, seats, SOS alerts, and telemetry.
   - Real PostGIS spatial coordinates and real YOLOv8 computer vision detection.
2. **100% Free & Open-Source Stack**:
   - Zero paid API key requirements (e.g. CartoDB Dark Matter free vector map tiles, Supabase generous free tier or local Docker, FastAPI, Scikit-Learn).
3. **Anti-AI-Slop & Craft-Centered UI/UX**:
   - Deep Obsidian palette (`#050811`, `#0B132B`) with functional neon safety accents (🟢 Emerald, 🟡 Amber, 🔴 Crimson).
   - Custom animated KSRTC (rotating wheels, scrolling Malayalam LED marquee ticker) and Private bus sprites (crowd-responsive underglow).
   - 60fps cubic spline vehicle interpolation on live maps.
4. **Dual-Role Enterprise Authentication**:
   - Role-gated portals for **Passengers** (`role = 'passenger'`) and **Authority Dispatchers** (`role = 'authority_admin'`).

---

## 🚀 2. Quickstart & Service Startup Sequence

### Step 1: Supabase Database Migration (1-Click)
1. Log in to your [Supabase Dashboard](https://supabase.com/dashboard) and open your project.
2. Navigate to the **SQL Editor** in the left sidebar.
3. Open [`migrations/001_initial_schema.sql`](file:///d:/BusSense%20AI/migrations/001_initial_schema.sql).
4. Paste the entire content into the SQL Editor and click **Run**.
5. *Verification*: Check the **Table Editor** to confirm that all 10 tables (`profiles`, `buses`, `routes`, `bus_stops`, `occupancy_telemetry`, `tickets`, `eco_rewards`, `rebalance_recommendations`, `sos_alerts`, `dispatch_logs`) are created and seeded with Kerala routes (R1–R4) and fleet data.

### Step 2: Environment Configuration
1. In the repository root, copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Edit `.env` and fill in:
   - `SUPABASE_URL`: Your Project URL (`https://<project-ref>.supabase.co`).
   - `SUPABASE_ANON_KEY`: Your project's anon/public key.
   - `SUPABASE_SERVICE_ROLE_KEY`: Your project's service_role key.

### Step 3: Python Backend & AI Engine Startup
```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Launch FastAPI service with auto-reload
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```
- Interactive Swagger API Documentation: `http://localhost:8000/docs`
- Health Check: `http://localhost:8000/api/health`

### Step 4: Unified Web/PWA Application Startup
```bash
# Serves the Unified App (Passenger Portal + In-App Authority Command Dashboard)
python -m http.server 3000 --bind 127.0.0.1 --directory app
```
- Open in browser: `http://localhost:3000`
- **Passenger Mode**: Live Kerala bus radar, 2x2 seat reservation, smart QR ticketing (-20% green discount), destination wake-up alarm, 1-tap SOS distress button, Malayalam/English toggle.
- **Authority Login**: Click "Authority Login" in the top bar and enter `dispatcher@kerala.transit.gov` (or click 1-Click Quick Demo Login) to unlock the **Authority Command HUD inside the app** (fleet telemetry, autonomous AI fleet rebalancing, emergency SOS incident triage, edge camera feed).

### Step 5: Flutter Native Mobile App
```bash
cd mobile_app_flutter
flutter pub get
flutter run
```

---

## 📜 3. Execution History & Milestones

| Phase | Milestone Description | Date / Status | Notes |
| :--- | :--- | :--- | :--- |
| **Phase 1** | **Repository Reorganization & Supabase Migration** | 2026-09-12 (COMPLETED) | Unnested `BusSenseAI/` directory, cleaned duplicate requirements, created PostGIS migration `001_initial_schema.sql`, `.env.example`, `MEMORY.md`, `DEPENDENCIES.md`, `ARCHITECTURE.md`, `API_REFERENCE.md`. |
| **Phase 2** | **Zero-Dummy AI Backend & Telemetry Gateway** | Next (PENDING) | FastAPI app, ML demand prediction, autonomous rebalancer, GPS simulator, YOLOv8 edge pipeline, pytest suite. |
| **Phase 3** | **Authority Command Center with Bus Animations** | Upcoming (PENDING) | Obsidian HUD, KSRTC/Private SVG animated sprites, 60fps spline map, SOS audio siren, dispatch modal. |
| **Phase 4** | **Passenger Experience, QR Ticketing & Seat Map** | Upcoming (PENDING) | Flutter 3 Native setup, mobile PWA, holographic QR pass, 2x2 seat selector, Malayalam bilingual i18n. |
| **Phase 5** | **End-to-End System Integration & Runbook** | Upcoming (PENDING) | Full live Realtime synchronization test, Docker compose, production verification. |

---

## 🛠️ 4. Port & Service Directory Reference

| Service | Port | Directory | Description |
| :--- | :--- | :--- | :--- |
| **FastAPI Backend & ML** | `8000` | `backend/` | REST API, OpenAPI docs, ML inference, telemetry receiver |
| **Authority Command Center** | `3000` | `dashboard/` | Obsidian Glassmorphism HUD for fleet dispatchers |
| **Passenger Mobile PWA** | `3001` | `mobile_app/` | Mobile-first zero-install commuter application |
| **Native Flutter App** | N/A | `mobile_app_flutter/` | Native Android, iOS, and Web passenger client |
| **Edge YOLOv8 Pipeline** | N/A | `occupancy_detection/` | Computer vision person counter with face/plate blur |
| **Database & Realtime** | Cloud / 5432 | `migrations/` | Supabase PostgreSQL 16 + PostGIS + Realtime WebSockets |

---

## 🔍 5. Troubleshooting & FAQ

### 1. `PostGIS extension not found`
- In Supabase, PostGIS is installed by default. If running self-hosted PostgreSQL, ensure you install `postgresql-16-postgis-3` or use the official `postgis/postgis:16-3.4` Docker image.

### 2. `Supabase Realtime not firing WebSocket updates`
- Ensure that the target tables have been added to the `supabase_realtime` publication (included at the end of `migrations/001_initial_schema.sql`).
- In Supabase Dashboard, go to **Database -> Replication** and confirm that `buses`, `occupancy_telemetry`, `tickets`, and `sos_alerts` are toggled ON.

### 3. `CORS Errors on API Calls`
- Verify that `CORS_ORIGINS` in `.env` includes the client origin (e.g. `http://localhost:3000`, `http://localhost:3001`).
