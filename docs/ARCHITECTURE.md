# BusSense AI — System Architecture

This document describes the high-level and detailed architecture of the BusSense AI platform, including data pipelines, hardware-to-cloud interfaces, and machine learning components.

---

## 1. High-Level System Architecture

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│                                CLIENT WORKSPACES                                  │
├─────────────────────────┬─────────────────────────┬───────────────────────────────┤
│     PASSENGER APP       │   DRIVER COCKPIT HUD    │   AUTHORITY COMMAND CENTER    │
│  (Next.js Mobile Shell  │  (Next.js Mobile Shell  │    (Next.js Desktop Web App   │
│    / Target: Flutter)   │   / Target: Flutter)    │      Tailwind + Leaflet)      │
└────────────┬────────────┴────────────┬────────────┴───────────────┬───────────────┘
             │                         │                            │
             │ HTTPS / WSS             │ HTTPS / WSS                │ HTTPS / WSS
             ▼                         ▼                            ▼
┌───────────────────────────────────────────────────────────────────────────────────┐
│                             FASTAPI BACKEND GATEWAY                               │
│                         (Python 3.14 ASGI Core in /backend)                       │
├───────────────────────────────────────────────────────────────────────────────────┤
│  • Security & RBAC: JWT Verification (PASSENGER, DRIVER_CONDUCTOR, AUTHORITY)     │
│  • Telemetry WebSocket Broadcast (/ws/telemetry)                                  │
│  • Background Simulation Ticker (2.0s loop updating corridor positions)           │
├─────────────────┬─────────────────┬──────────────────┬────────────────────────────┤
│  CV OCCUPANCY   │ GPS SIMULATOR   │ DEMAND FORECAST  │   RECOMMENDATION ENGINE    │
│  (YOLOv8/OpenCV)│ (Waypoint Nav)  │  (scikit-learn)  │   (Multi-factor scoring)   │
├─────────────────┴─────────────────┴──────────────────┴────────────────────────────┤
│                 TICKET ENGINE & RAG TRANSIT ASSISTANT SERVICE                     │
└──────────────────────────────────────┬────────────────────────────────────────────┘
                                       │
                                       │ PostgREST / Supabase Client
                                       ▼
┌───────────────────────────────────────────────────────────────────────────────────┐
│                       SUPABASE POSTGRESQL DATABASE & AUTH                         │
│                    (Project: lqegmqgkymstycpzplld, ap-south-1)                    │
├───────────────────────────────────────────────────────────────────────────────────┤
│  • 26 Relational Tables with Row-Level Security (RLS)                             │
│  • Vector Knowledge Chunks for Retrieval-Augmented Generation (RAG)               │
│  • Live Telemetry Persistence: gps_positions, occupancy_readings, tickets         │
└───────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Computer Vision Occupancy Pipeline

The Computer Vision engine computes vehicle density without collecting facial biometrics.

```
┌─────────────────┐     RTSP / H.264     ┌────────────────────────┐
│ Onboard Camera  │ ───────────────────► │ OpenCV VideoCapture    │
│ (Wide-angle 1080p)                     │ (Downsample to 640x360)│
└─────────────────┘                      └───────────┬────────────┘
                                                     │ 5 FPS Frame Skip
                                                     ▼
                                         ┌────────────────────────┐
                                         │ YOLOv8n Head & Body    │
                                         │ Object Detection (COCO)│
                                         └───────────┬────────────┘
                                                     │ Bounding Boxes [x,y,w,h]
                                                     ▼
                                         ┌────────────────────────┐
                                         │ Privacy Filter (Edge)  │
                                         │ (Raw pixels discarded; │
                                         │  only count retained)  │
                                         └───────────┬────────────┘
                                                     │ Head count: n
                                                     ▼
                                         ┌────────────────────────┐
                                         │ Occupancy Calculator   │
                                         │ pct = (n / cap) * 100  │
                                         └───────────┬────────────┘
                                                     │ Tier: LOW / MOD / CROWDED
                                                     ▼
                                         ┌────────────────────────┐
                                         │ Supabase Persistence & │
                                         │ Telemetry WebSocket    │
                                         └────────────────────────┘
```

### Privacy & Edge Guarantees:
- **Zero Face Recognition:** No face models (FaceNet, InsightFace, etc.) are installed or imported.
- **Edge Volatility:** Video frames exist solely in RAM buffers during inference and are immediately garbage collected.
- **Simulation Fallback:** In development mode (`CV_MODE=SIMULATION`), the engine generates Poisson-distributed passenger boarding and alighting deltas at corridor stops.

---

## 3. GPS & Real-Time Tracking Pipeline

The GPS engine tracks vehicle movement along high-density Kerala transit corridors (Aluva ➔ Edappally ➔ Palarivattom ➔ Kaloor ➔ Infopark ➔ Vyttila Hub).

```
┌──────────────────┐                     ┌────────────────────────┐
│ Physical GPS     │ NMEA 0183 / GPRMC   │ Waypoint Interpolator  │
│ Hardware / Sim   │ ──────────────────► │ (Aluva to Vyttila Hub) │
└──────────────────┘                     └───────────┬────────────┘
                                                     │ (lat, lng, speed, bearing)
                                                     ▼
                                         ┌────────────────────────┐
                                         │ Haversine Geofencer    │
                                         │ (Detect Stop Arrivals) │
                                         └───────────┬────────────┘
                                                     │ Stop Entry Event
                                                     ▼
                                         ┌────────────────────────┐
                                         │ Dynamic ETA Estimator  │
                                         │ ETA = dist / avg_speed │
                                         └───────────┬────────────┘
                                                     │
                                                     ▼
                                         ┌────────────────────────┐
                                         │ WebSocket Broadcast    │
                                         │ (/ws/telemetry)        │
                                         └───────────┬────────────┘
                                                     │
                                                     ▼
                                         ┌────────────────────────┐
                                         │ Client Viewports:      │
                                         │ • Passenger Live HUD   │
                                         │ • Driver Cockpit HUD   │
                                         │ • Authority GIS Map    │
                                         └────────────────────────┘
```

---

## 4. Artificial Intelligence (RAG) Pipeline

The AI Transit Assistant provides strictly grounded answers to commuter inquiries regarding routes, fares, vehicle amenities, and live corridor conditions.

```
┌─────────────────┐
│ Commuter Query  │ (e.g., "Is Bus 205 crowded right now? Can I get a seat?")
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│ Context Retrieval & Router      │
├─────────────────────────────────┤
│ 1. Vector Search:               │
│    Queries `knowledge_chunks`   │
│    table for transit policies.  │
│ 2. Live Tool-Calling:           │
│    Queries `buses` & `routes`   │
│    for Bus 205 live telemetry.  │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ Prompt Assembly & Guardrails    │
├─────────────────────────────────┤
│ System: BusSense Kerala AI.     │
│ Context:                        │
│ • Bus 205 Occupancy: 41.8% LOW  │
│ • Seats Available: 32 / 55      │
│ • Next Stop: Kaloor Stand (4m)  │
│ Rule: Ground strictly in facts. │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ LLM Inference Engine            │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ Grounded Response & Sources     │
├─────────────────────────────────┤
│ "Bus 205 has 32 seats available │
│  (41.8% occupancy, LOW crowd)   │
│  arriving at Kaloor in 4 mins." │
│ Sources: [Live CCTV Telemetry]  │
└─────────────────────────────────┘
```

---

## 5. Software Component Inventory

| Layer | Path | Description |
|---|---|---|
| **Entry Point** | `backend/app/main.py` | FastAPI application, middleware, lifecycle events, and WebSocket handlers. |
| **Config** | `backend/app/core/config.py` | Typed settings parsed from `.env` using Pydantic `BaseSettings`. |
| **Database** | `backend/app/core/supabase.py` | Thread-safe Supabase PostgREST and Auth client bindings. |
| **Auth** | `backend/app/core/security.py` | Cryptographic password hashing (Passlib/bcrypt) and JWT encode/decode. |
| **CV Service** | `backend/app/services/cv_occupancy.py` | YOLOv8 person counting, density calculation, and mock frame generator. |
| **GPS Service** | `backend/app/services/gps_simulator.py` | Kochi transit corridors, haversine geofences, and headway tracking. |
| **Forecasting** | `backend/app/services/demand_forecaster.py` | Ridge regression predicting crowd levels at +0, +15, +30, and +60 min. |
| **Scoring** | `backend/app/services/recommendation_engine.py` | Multi-criteria bus decision model with explainable factor breakdown. |
| **Ticketing** | `backend/app/services/ticket_service.py` | Fare logic, SHA-256 digital signature, and Base64 QR code generation. |
| **RAG AI** | `backend/app/services/rag_service.py` | Telemetry-injected transit QA bot with citation engine. |
| **Web API** | `backend/app/api/` | 10 modular FastAPI APIRouters. |
| **Frontend** | `frontend/app/` | Next.js 14 App Router views for Passenger, Driver, and Authority. |
| **API Client** | `frontend/lib/api.ts` | Typed isomorphic fetch client interfacing with FastAPI endpoints. |
