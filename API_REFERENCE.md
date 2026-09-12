# 📡 BusSense AI 2.0: API & WebSocket Specifications

> **REST API Endpoints, Pydantic Schemas, and Supabase Realtime Channels**

---

## 🌐 1. FastAPI REST API Reference (`http://localhost:8000`)

### Base URL: `/api`

### A. System & Health
#### `GET /api/health`
- **Description**: Verifies API availability, database connection, and ML model status.
- **Response `200 OK`**:
  ```json
  {
    "status": "healthy",
    "version": "2.0.0",
    "database": "connected",
    "ml_engine": "online",
    "timestamp": "2026-09-12T05:45:00Z"
  }
  ```

---

### B. Fleet & Live Telemetry
#### `GET /api/buses`
- **Description**: Fetches all active buses with their latest live PostGIS coordinates, occupancy metrics, and speed.
- **Query Params**:
  - `operator`: Optional filter (`KSRTC` | `PRIVATE`).
  - `route`: Optional filter (e.g. `R1`).
- **Response `200 OK`**:
  ```json
  [
    {
      "bus_id": "KSRTC-101",
      "operator_type": "KSRTC",
      "route_number": "R1",
      "registration_number": "KL-15-A-1001",
      "capacity": 50,
      "passenger_count": 22,
      "occupancy_percentage": 44.0,
      "seat_availability": 28,
      "crowd_tier": "GREEN",
      "latitude": 8.5241,
      "longitude": 76.9366,
      "speed_kmh": 38.0,
      "heading_deg": 45.0,
      "sprite_type": "ksrtc_standard",
      "safety_score": 9.6,
      "last_updated": "2026-09-12T05:44:50Z"
    }
  ]
  ```

#### `POST /api/telemetry/ingest`
- **Description**: Secure ingestion endpoint for Edge YOLOv8 person counters and vehicle telematics units.
- **Headers**: `X-Edge-API-Key: bussense_edge_secret_key_2026`
- **Request Body**:
  ```json
  {
    "bus_id": "KSRTC-101",
    "route_number": "R1",
    "latitude": 8.5255,
    "longitude": 76.9380,
    "passenger_count": 24,
    "capacity": 50,
    "speed_kmh": 40.0,
    "heading_deg": 48.0,
    "source": "edge_yolo"
  }
  ```
- **Response `201 Created`**:
  ```json
  {
    "status": "ingested",
    "occupancy_percentage": 48.0,
    "seat_availability": 26,
    "crowd_tier": "GREEN"
  }
  ```

---

### C. Predictive Demand & Autonomous Rebalancing
#### `GET /api/demand/forecast`
- **Description**: Returns 24-hour ahead passenger demand predictions per route using pre-trained Random Forest model (&lt;15ms latency).
- **Query Params**:
  - `route_number`: Target transit route (e.g. `R1`).
- **Response `200 OK`**:
  ```json
  {
    "route_number": "R1",
    "predicted_hourly_occupancy": [
      { "hour": 7, "occupancy_pct": 52.0, "risk": "NORMAL" },
      { "hour": 8, "occupancy_pct": 88.5, "risk": "HIGH_SURGE" },
      { "hour": 9, "occupancy_pct": 94.0, "risk": "HIGH_SURGE" },
      { "hour": 10, "occupancy_pct": 64.0, "risk": "NORMAL" }
    ],
    "peak_risk_hours": [8, 9, 17, 18],
    "recommended_action": "Deploy 2 additional relief buses during morning peak (08:00 - 10:00)."
  }
  ```

#### `GET /api/rebalance/recommendations`
- **Description**: Returns active autonomous fleet rebalancing recommendations calculated by AI.
- **Response `200 OK`**:
  ```json
  [
    {
      "id": "7b8f9e01-1234-4567-890a-bcdef0123456",
      "source_route": "R4",
      "target_route": "R1",
      "recommended_bus_ids": ["PVT-204"],
      "reason": "Route R1 predicted peak demand surge of 92% at 17:30. Route R4 operating at 25% occupancy.",
      "predicted_congestion_reduction_pct": 18.5,
      "status": "pending",
      "created_at": "2026-09-12T05:30:00Z"
    }
  ]
  ```

---

### D. Dynamic Smart QR Ticketing & Seat Map
#### `POST /api/tickets/book`
- **Description**: Books a digital ticket with dynamic green discount and reserves a specific visual seat.
- **Request Body**:
  ```json
  {
    "user_id": "4a3b2c1d-0000-1111-2222-333344445555",
    "bus_id": "KSRTC-101",
    "route_number": "R1",
    "origin_stop": "Thampanoor Central Stop",
    "destination_stop": "Technopark Main Gate",
    "seat_number": "14A",
    "base_fare": 40.00
  }
  ```
- **Response `201 Created`**:
  ```json
  {
    "ticket_id": "99aabbcc-8877-6655-4433-221100fedcba",
    "seat_number": "14A",
    "base_fare": 40.00,
    "discount_pct": 20.0,
    "final_fare": 32.00,
    "qr_code_hash": "sha256_bussense_ticket_secure_token_99aabbcc",
    "valid_until": "2026-09-12T07:45:00Z",
    "status": "active"
  }
  ```

#### `POST /api/tickets/validate`
- **Description**: Conductor QR code validation endpoint.
- **Request Body**:
  ```json
  {
    "qr_code_hash": "sha256_bussense_ticket_secure_token_99aabbcc",
    "bus_id": "KSRTC-101"
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "valid": true,
    "ticket_id": "99aabbcc-8877-6655-4433-221100fedcba",
    "seat_number": "14A",
    "status": "used",
    "validated_at": "2026-09-12T05:50:12Z"
  }
  ```

---

### E. Emergency SOS & Incident Reports
#### `POST /api/sos/broadcast`
- **Description**: Triggers an instant high-priority SOS emergency alert broadcasted to the Authority Command Center HUD.
- **Request Body**:
  ```json
  {
    "user_id": "4a3b2c1d-0000-1111-2222-333344445555",
    "bus_id": "KSRTC-102",
    "route_number": "R1",
    "latitude": 8.5350,
    "longitude": 76.9450,
    "message": "Immediate Medical Assistance Required"
  }
  ```
- **Response `201 Created`**:
  ```json
  {
    "status": "broadcasted",
    "sos_id": "aa11bb22-3344-5566-7788-9900aabbccdd",
    "created_at": "2026-09-12T05:52:00Z"
  }
  ```

---

## ⚡ 2. Supabase Realtime Channels (WebSockets)

| Channel Name | Target Table | Event | Payload Data |
| :--- | :--- | :--- | :--- |
| **`fleet-telemetry`** | `public.occupancy_telemetry` | `INSERT` | Real-time vehicle coordinates, speed, heading, and crowd tier |
| **`emergency-sos`** | `public.sos_alerts` | `INSERT` | Instant emergency beacon location and message |
| **`dispatch-updates`** | `public.buses` | `INSERT`, `UPDATE` | New relief bus deployment and status changes |
| **`ticket-manifest`** | `public.tickets` | `INSERT`, `UPDATE` | Reserved seat status changes and live boarding manifests |
