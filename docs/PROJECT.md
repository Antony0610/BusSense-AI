# BusSense AI — Project Overview

## 1. Executive Summary

**BusSense AI** is a climate-smart public bus intelligence platform developed for metropolitan corridors in Kerala (focusing on Greater Kochi: Aluva, Edappally, Kaloor, Kakkanad Infopark, Vyttila Mobility Hub, and MG Road).

Public transit systems often suffer from the "black-box commuter dilemma": passengers do not know if the next arriving bus has available seats, drivers lack situational visibility over corridor surges, and transit authorities lack automated tools to balance supply with surging demand.

BusSense AI bridges this gap through an end-to-end intelligence loop:
```
SEE ────────► SENSE ────────► PREDICT ────────► RECOMMEND ────────► OPTIMIZE
Onboard CCTV   YOLOv8 Head    Ridge Regression   Multi-Factor       AI Tripper
Camera Feed    & Body Count   Demand Horizon     Comfort & ETA      Dispatch Queue
```

---

## 2. Problem Statement

1. **Unpredictable Crowding & Commuter Anxiety:** Commuters frequently let empty buses pass or crowd onto overloaded buses because real-time interior density is invisible prior to vehicle arrival.
2. **First-Mile/Last-Mile Coordination Failures:** Feeder connections to the Kochi Metro and Kochi Water Metro suffer from schedule desynchronization.
3. **Driver Workload & Safety Risks:** Transit operators rely on manual paper ticketing and phone calls to report breakdowns or bottlenecks while driving.
4. **Reactive Fleet Management:** Transport authorities only discover extreme corridor congestion or passenger stranding after severe delays have already occurred.

---

## 3. The BusSense AI Solution

BusSense AI introduces three purpose-built experiences linked to a unified real-time intelligence backend:

1. **For Passengers:**
   - Real-time seat availability (seats free vs standing count).
   - 60-minute explainable crowd forecasts.
   - Smart recommendation engine comparing alternatives by comfort, speed, and priority-lane usage.
   - Sub-second digital QR boarding passes.
   - Grounded RAG transit assistant.

2. **For Drivers & Conductors:**
   - Safety-first, high-contrast vehicle cockpit HUD.
   - Automated stop countdowns and schedule adherence deltas.
   - High-speed offline-ready QR ticket validation.
   - One-tap rapid incident and hazard dispatch.

3. **For Transport Authorities:**
   - Dual-pane GIS command center with live vehicle tracking and corridor speed vectors.
   - Machine learning demand horizon forecasting spatial crowding 15 to 60 minutes ahead.
   - Human-in-the-loop AI dispatch recommendations (e.g., injecting an express tripper during an Infopark shift change).

---

## 4. System Applications & Target Users

| User Persona | Application Type | Key Goals |
|---|---|---|
| **Rahul Nair (Commuter / Tech Worker)** | Mobile Web / Flutter | Needs comfortable bus from Kaloor to Infopark with guaranteed seat. |
| **Suresh Kumar (KSRTC Driver)** | Ruggedized Tablet / Cockpit | Needs glanceable next-stop countdown and 1-tap route diversion logging. |
| **Anjali Menon (Transit Operations Officer)**| Desktop Command Web App | Needs corridor telemetry, incident triage, and automated fleet optimization. |

---

## 5. Technology Stack

- **Frontend:** Next.js 14 (React 18), TypeScript, Tailwind CSS with Google Stitch design tokens (`#002620`, `#123c35`, `#006c49`, `#f3fbf7`).
- **Backend API:** FastAPI (Python 3.14), Uvicorn, Pydantic v2 schemas.
- **Database & Identity:** Supabase PostgreSQL 15 (Project `lqegmqgkymstycpzplld`), Row-Level Security (RLS), JWT authentication.
- **Computer Vision:** YOLOv8 (ultralytics) + OpenCV (cv2) for edge-based head and body counting without biometrics.
- **Predictive Analytics:** scikit-learn Ridge Regression with temporal feature engineering (`sin_time`, `cos_time`, weather, day-of-week).
- **QR Code Cryptography:** Python `qrcode` + SHA-256 validation digests.

---

## 6. Core Innovation Pillars

1. **Privacy-by-Design Computer Vision:** BusSense AI never captures, processes, or stores facial biometrics. The vision pipeline operates purely on generic bounding boxes, computing head/shoulder counts at the vehicle edge and discarding raw video immediately.
2. **Transparent Data Labeling:** Every synthetic number in the system is explicitly badged (`SIMULATED DATA`, `PREDICTION`, `ESTIMATE`, or `RECOMMENDATION`).
3. **Multi-Factor Journey Scoring:** Recommendations do not simply pick the earliest bus; they evaluate seated probability (comfort weight 40%), journey duration (speed weight 30%), reliability (20%), and vehicle amenities (10%).

---

## 7. Current Implementation Status

| Component | Status | Details |
|---|---|---|
| **Supabase Database** | **Implemented** | 26 relational tables, enums, RLS policies, and seed data live on project `lqegmqgkymstycpzplld`. |
| **FastAPI Backend** | **Implemented** | 10 API routers, 7/7 automated pytest tests passing, WebSocket telemetry stream. |
| **CV Occupancy Service** | **Implemented** | YOLOv8 pipeline + OpenCV fallback with 3-tier crowd classifier (<50%, 50–80%, >80%). |
| **Demand Forecaster** | **Implemented** | scikit-learn Ridge model generating multi-horizon predictions (+0, +15, +30, +60 min). |
| **Smart Recommendation Engine** | **Implemented** | Multi-factor scoring with explanatory "Why this bus?" drawer. |
| **Ticketing & QR Engine** | **Implemented** | Fare calculator, Base64 PNG QR code generator, and 3-state conductor validator. |
| **RAG Transit Assistant** | **Implemented** | Semantic retrieval over Kerala transit knowledge base with live telemetry injection. |
| **Frontend Mobile Shells** | **Implemented** | Passenger Home, Explore, Tickets, Journey HUD, Profile, Driver Cockpit, Validator, Incident, Layover. |
| **Authority Command Center** | **In Progress** | Desktop Command Center map, fleet table, AI Ops queue, and reports. |

---

## 8. Future Scope & Roadmap

- Native mobile packaging using Flutter for passenger and conductor devices.
- Hardware bench testing with Raspberry Pi 5 + Hailo-8 AI acceleration module for on-bus YOLOv8 inference.
- Integration with Kerala Open Transit Data feeds and Kochi Metro automated fare collection APIs.
- Real-world field pilots on Kaloor–Infopark and Aluva–Vyttila corridors.
