# BusSense AI — Demo Mode & Hardware Simulation

This document explains how BusSense AI delivers a fully functional, end-to-end evaluation environment without requiring physical CCTV cameras, onboard GPS dongles, or production banking licenses.

---

## 1. Simulation Philosophy

In prototyping and academic evaluation, physical transit hardware is rarely accessible. Rather than mocking static responses with hardcoded JSON files, BusSense AI implements **dynamic physics simulation engines**:

```
┌─────────────────────────────────┐
│     BACKGROUND SIMULATION LOOP  │ (Executes in `backend/app/main.py`)
│     Interval: 2.0 Seconds       │
└────────────────┬────────────────┘
                 │
         ┌───────┴───────┬───────────────┬────────────────┐
         ▼               ▼               ▼                ▼
┌────────────────┐┌─────────────┐┌───────────────┐┌──────────────┐
│ GPS MOVEMENT   ││ CV OCCUPANCY││ RIDGE FORECAST││ TICKET ENGINE│
│ Waypoint Drift ││ Poisson     ││ Cyclical Hour ││ Base64 Signed│
│ Along Kochi NH ││ Stop Flux   ││ Influx Curves ││ QR Generation│
└────────────────┘└─────────────┘└───────────────┘└──────────────┘
```

---

## 2. Simulated Subsystems & Truth Badges

Every synthetic data point displayed in client applications carries a permanent truth badge:

### 1. Simulated Buses & Corridors
- **Implementation:** `backend/app/services/gps_simulator.py`
- **Behavior:** 5 active transit vehicles (Bus 205, Bus 14A, Bus FP-102, Bus AC-501, Bus 12) traverse Kochi corridors (Aluva ⇄ Kaloor ⇄ Infopark ⇄ Vyttila Hub).
- **Truth Badge:** `SIMULATED CORRIDOR`

### 2. Simulated GPS Telemetry
- **Implementation:** Haversine coordinate interpolator with speed variation (0–48 km/h) and heading rotation.
- **Behavior:** Broadcasts real-time coordinate updates every 2 seconds via WebSocket `/ws/telemetry`.
- **Truth Badge:** `SIMULATED DATA`

### 3. Simulated Computer Vision Occupancy
- **Implementation:** `backend/app/services/cv_occupancy.py`
- **Behavior:** Dynamically simulates passenger boarding and alighting deltas at each bus stop using Poisson distributions, transitioning between `LOW`, `MODERATE`, and `CROWDED` tiers.
- **Truth Badge:** `SIMULATED OCCUPANCY (YOLOv8 LOG)`

### 4. Machine Learning Demand Forecasting
- **Implementation:** `backend/app/services/demand_forecaster.py`
- **Behavior:** Trained Ridge regression model computing arrival crowd projections for +0, +15, +30, and +60 minutes.
- **Truth Badge:** `PREDICTION`

### 5. Multi-Factor Smart Recommendations
- **Implementation:** `backend/app/services/recommendation_engine.py`
- **Behavior:** Computes composite journey utility scores, explaining trade-offs between speed and seat comfort.
- **Truth Badge:** `RECOMMENDATION`

### 6. Sandbox Payment & Digital Tickets
- **Implementation:** `backend/app/services/ticket_service.py`
- **Behavior:** Instantly issues cryptographically verifiable QR transit boarding passes.
- **Truth Badge:** `DEMO TICKET`

---

## 3. Demo Credentials & Quick Access

The system includes pre-configured, safe credentials for evaluator sign-in:

- **Passenger:** `rahul@bussense.ai` / `demo1234`
- **Driver:** `suresh@bussense.ai` / `demo1234`
- **Authority:** `anjali@bussense.ai` / `demo1234`

Evaluators can also navigate to `/roles` at any time to switch personas with a single tap.
