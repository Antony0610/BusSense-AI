# BusSense AI — REST & Realtime API Specification

Base URL: `http://localhost:8000` (or configured production host).  
All endpoints return JSON responses adhering to Pydantic v2 data models.

---

## 1. Authentication Endpoints (`/api/auth`)

### 1.1 `POST /api/auth/login`
- **Purpose:** Authenticates user and issues signed JWT bearer token.
- **Authentication:** Public
- **Request Body:**
  ```json
  {
    "username": "rahul@bussense.ai",
    "password": "demo1234"
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "access_token": "eyJhbGciOiJIUzI1Ni...",
    "token_type": "bearer",
    "user": {
      "id": "00000000-0000-0000-0000-000000000001",
      "email": "rahul@bussense.ai",
      "full_name": "Rahul Nair",
      "role": "PASSENGER"
    }
  }
  ```
- **Errors:** `401 Unauthorized` for invalid credentials.
- **Database Interaction:** Queries `users` table by email or phone; validates bcrypt hash.

### 1.2 `GET /api/auth/me`
- **Purpose:** Returns the authenticated user's profile and active role.
- **Authentication:** Bearer JWT
- **Role:** Any (`PASSENGER`, `DRIVER_CONDUCTOR`, `AUTHORITY`)
- **Response (`200 OK`):** User profile object.

---

## 2. Bus Fleet & Telemetry Endpoints (`/api/buses`)

### 2.1 `GET /api/buses`
- **Purpose:** Returns active fleet vehicles with live coordinates, speed, and occupancy.
- **Authentication:** Optional in demo mode / Bearer JWT in production
- **Query Params:** `corridor` (optional string)
- **Response (`200 OK`):**
  ```json
  [
    {
      "bus_id": "00000000-0000-0000-0000-000000000011",
      "bus_code": "Bus 205",
      "route_number": "12",
      "status": "ACTIVE",
      "latitude": 9.9984,
      "longitude": 76.3025,
      "speed_kmh": 34.2,
      "heading": 85.0,
      "passenger_count": 23,
      "total_capacity": 55,
      "occupancy_percentage": 41.8,
      "crowd_level": "LOW",
      "data_origin": "SIMULATED"
    }
  ]
  ```

### 2.2 `GET /api/buses/{bus_id}`
- **Purpose:** Returns detailed vehicle state including stop arrival countdown and driver name.
- **Authentication:** Optional in demo mode

### 2.3 `POST /api/buses/{bus_id}/location`
- **Purpose:** Ingests live telemetry coordinate fix from on-bus tracker.
- **Role:** Driver, System
- **Request Body:**
  ```json
  {
    "latitude": 9.9984,
    "longitude": 76.3025,
    "speed": 34.2,
    "heading": 85.0
  }
  ```

---

## 3. Routes & Transit Network (`/api/routes`)

### 3.1 `GET /api/routes`
- **Purpose:** Lists active transit routes in the Greater Kochi network.
- **Response (`200 OK`):** Array of routes with origin, destination, and distance.

### 3.2 `GET /api/routes/{route_id}`
- **Purpose:** Returns route details and ordered sequence of transit stops with minute offsets.

---

## 4. Transit Stops & Departures (`/api/stops`)

### 4.1 `GET /api/stops`
- **Purpose:** Returns all transit stops and Metro interchange hubs.

### 4.2 `GET /api/stops/{stop_id}/departures`
- **Purpose:** Returns upcoming bus arrivals at a specific shelter with live ETA countdowns.

---

## 5. Occupancy & Crowd Predictions (`/api/occupancy`)

### 5.1 `GET /api/occupancy/{bus_id}`
- **Purpose:** Returns live passenger head count and capacity metrics for a bus.
- **Response (`200 OK`):**
  ```json
  {
    "bus_id": "00000000-0000-0000-0000-000000000011",
    "passenger_count": 23,
    "total_capacity": 55,
    "seated_capacity": 42,
    "occupancy_percentage": 41.8,
    "crowd_level": "LOW",
    "data_origin": "SIMULATED"
  }
  ```

### 5.2 `GET /api/occupancy/predictions`
- **Purpose:** Returns 60-minute crowd forecast for upcoming departure windows.
- **Query Params:** `bus_id` (optional), `route_id` (optional)
- **Response (`200 OK`):**
  ```json
  {
    "now": { "occupancy_pct": 42.0, "crowd_level": "LOW", "confidence": 0.94 },
    "plus_15m": { "occupancy_pct": 58.0, "crowd_level": "MODERATE", "confidence": 0.88 },
    "plus_30m": { "occupancy_pct": 82.0, "crowd_level": "CROWDED", "confidence": 0.82 },
    "plus_60m": { "occupancy_pct": 49.0, "crowd_level": "LOW", "confidence": 0.79 }
  }
  ```

---

## 6. Smart Recommendations (`/api/recommendations`)

### 6.1 `GET /api/recommendations`
- **Purpose:** Compares candidate buses along a corridor and returns optimal recommendation with explainable breakdown.
- **Query Params:** `origin_stop_id`, `destination_stop_id`
- **Response (`200 OK`):**
  ```json
  {
    "recommended_bus": {
      "bus_id": "00000000-0000-0000-0000-000000000011",
      "bus_code": "Bus 205",
      "journey_score": 92,
      "seat_probability_pct": 85,
      "eta_minutes": 4,
      "has_priority_lane": true,
      "reason_summary": "85% seat chance + bypass priority lane saves 12 mins."
    },
    "alternative_bus": {
      "bus_id": "00000000-0000-0000-0000-000000000012",
      "bus_code": "Bus 14A",
      "journey_score": 71,
      "seat_probability_pct": 32,
      "eta_minutes": 2,
      "reason_summary": "Arrives earlier but 84% crowded with no seating."
    }
  }
  ```

---

## 7. Ticketing & Validation (`/api/tickets`)

### 7.1 `POST /api/tickets/book`
- **Purpose:** Creates digital transit pass with embedded signed QR code, persisted to Supabase `tickets` and `payments` tables.
- **Role:** Authenticated Commuter (`PASSENGER`, `DRIVER_CONDUCTOR`, `AUTHORITY`)
- **Request Body:**
  ```json
  {
    "bus_number": "205",
    "route_number": "205",
    "origin_stop": "Kaloor Metro Station",
    "destination_stop": "Vyttila Mobility Hub",
    "passenger_name": "Rahul Nair",
    "fare_amount": 25.0
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "data": {
      "id": "2ba5c38b-eaac-427d-b788-c2c774efbc05",
      "ticket_number": "BS-KL-2026-A498C7",
      "status": "VALID",
      "fare_amount": 25.0,
      "final_fare": 25.0,
      "qr_code_hash": "bussense://ticket/BS-KL-2026-A498C7?auth=...",
      "qr_code_data_uri": "data:image/png;base64,iVBORw0KGgo...",
      "valid_from": "2026-09-26T15:07:46Z",
      "valid_until": "2026-09-26T19:07:46Z",
      "created_at": "2026-09-26T15:07:48Z"
    },
    "data_origin": "LIVE DATA",
    "message": "Ticket booked successfully"
  }
  ```

### 7.2 `GET /api/tickets/my`
- **Purpose:** Retrieves digital boarding passes belonging strictly to the authenticated user from Supabase.
- **Role:** Authenticated Commuter (`PASSENGER`)
- **Isolation Guarantee:** Filtered by `user_id = current_user.sub`. Commuter A cannot access Commuter B's tickets.
- **Response (`200 OK`):** Array of `TicketResponse` objects with reconstructed QR data URIs.

### 7.3 `POST /api/tickets/validate`
- **Purpose:** Conductor QR scanner verification endpoint. Atomic and race-condition protected via Supabase stored procedure `validate_ticket_atomic`.
- **Role:** `DRIVER_CONDUCTOR` or `AUTHORITY` (403 for Passengers)
- **Request Body:**
  ```json
  {
    "qr_code_hash": "bussense://ticket/BS-KL-2026-A498C7?auth=...",
    "bus_number": "205"
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "data": {
      "result": "VALID",
      "is_valid": true,
      "ticket_number": "BS-KL-2026-A498C7",
      "passenger_name": "Rahul Nair",
      "origin_stop": "Kaloor Metro Station",
      "destination_stop": "Vyttila Mobility Hub",
      "message": "Boarding approved for passenger Rahul Nair.",
      "validated_at": "2026-09-26T15:08:07Z"
    },
    "data_origin": "LIVE DATA"
  }
  ```
- **Validation Results:** `VALID`, `ALREADY_USED`, `EXPIRED`, `INVALID`.

---

## 8. Incidents & Service Alerts (`/api/incidents`)

### 8.1 `POST /api/incidents/report`
- **Purpose:** Rapid driver incident logging. Persists to Supabase `incidents` table.
- **Role:** `DRIVER_CONDUCTOR` or `AUTHORITY`
- **Request Body:**
  ```json
  {
    "bus_number": "205",
    "route_number": "205",
    "category": "ROUTE_OBSTRUCTION",
    "severity": "WARNING",
    "title": "Waterlogging near Palarivattom Junction",
    "description": "Left lane flooded after rain; vehicles moving slowly."
  }
  ```
- **Response (`200 OK`):** Returns persistent `IncidentResponse` with database-generated UUID.

### 8.2 `POST /api/incidents/{incident_id}/resolve`
- **Purpose:** Authority incident triage resolution. Updates Supabase record status to `RESOLVED` and sets `resolved_at`.
- **Role:** `AUTHORITY` only (403 for Passengers and Drivers)
- **Response (`200 OK`):** Returns updated incident record with `status: "RESOLVED"`.

### 8.3 `GET /api/incidents/`
- **Purpose:** Returns recent crew incident logs from Supabase `incidents` table.
- **Role:** Authenticated users

### 8.4 `GET /api/incidents/alerts`
- **Purpose:** Returns active public service alerts and corridor advisories from Supabase `alerts` table.
- **Authentication:** Public


---

## 8. Incidents & Operations (`/api/incidents`)

### 8.1 `GET /api/incidents`
- **Purpose:** Returns active incident logs for authority triage.
- **Role:** Driver, Authority

### 8.2 `POST /api/incidents`
- **Purpose:** 1-tap rapid incident submission from vehicle cockpit.
- **Role:** Driver / Conductor
- **Request Body:**
  ```json
  {
    "category": "ROUTE_OBSTRUCTION",
    "severity": "WARNING",
    "title": "Palarivattom Jn Flyover Detour",
    "description": "Construction detour adds 8m delay to Infopark corridor."
  }
  ```

### 8.3 `PATCH /api/incidents/{incident_id}/resolve`
- **Purpose:** Marks incident resolved with officer post-mortem notes.
- **Role:** Authority

---

## 9. Analytics & Operational Reports (`/api/analytics`)

### 9.1 `GET /api/analytics/overview`
- **Purpose:** Network KPI summary (active fleet count, on-time percentage, daily throughput).
- **Role:** Authority

### 9.2 `POST /api/analytics/reports`
- **Purpose:** Generates structured sustainability and corridor intelligence report.
- **Role:** Authority

---

## 10. AI Transit Assistant (`/api/ai`)

### 10.1 `POST /api/ai/query`
- **Purpose:** Natural language transit assistant query with RAG retrieval and telemetry injection.
- **Request Body:**
  ```json
  {
    "query": "Is Bus 205 crowded right now? Can I get a seat from Kaloor?"
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "answer": "Bus 205 currently has 23 passengers onboard out of 55 capacity (41.8% occupancy, LOW crowd tier). 32 seats are available. It is arriving at Kaloor Stand in approximately 4 minutes.",
    "sources": ["Live CCTV Telemetry", "Kaloor-Infopark Schedule"],
    "live_bus_context": {
      "bus_code": "Bus 205",
      "crowd_level": "LOW",
      "eta_minutes": 4
    }
  }
  ```

---

## 11. Realtime Telemetry WebSocket (`/ws/telemetry`)
- **Protocol:** WebSocket (`ws://` / `wss://`)
- **Payload Event:**
  ```json
  {
    "type": "FLEET_TELEMETRY_UPDATE",
    "timestamp": "2026-09-26T18:00:00Z",
    "buses": [...]
  }
  ```

---

## 12. Active Trips API (`/api/trips`)

### 12.1 `GET /api/trips`
- **Purpose:** Returns active scheduled and in-transit corridor trips.
- **Authentication:** Bearer JWT required (`PASSENGER`, `DRIVER_CONDUCTOR`, `AUTHORITY`). Unauthenticated returns `401 Unauthorized`.
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "data": [
      {
        "trip_id": "00000000-0000-0000-0000-000000000201",
        "trip_code": "TRIP-205-0830",
        "bus_id": "a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
        "bus_number": "205",
        "route_id": "00000000-0000-0000-0000-000000000101",
        "route_number": "12",
        "current_status": "IN_TRANSIT",
        "current_stop": "Palarivattom Bypass Junction",
        "next_stop": "Kaloor Metro Station & Bus Stand",
        "started_at": "2026-09-26T11:42:38Z",
        "estimated_arrival": "2026-09-26T12:30:38Z",
        "occupancy_pct": 41.8,
        "crowd_level": "LOW",
        "data_origin": "SIMULATED DATA"
      }
    ]
  }
  ```

### 12.2 `GET /api/trips/{trip_id}`
- **Purpose:** Returns details for a specific trip.
- **Authentication:** Bearer JWT required.
- **Errors:** `404 Not Found` if trip ID does not exist.

---

## 13. Vehicle Locations & GPS API (`/api/locations`)

### 13.1 `GET /api/locations`
- **Purpose:** Returns current simulated GPS coordinates, heading, speed, and stop proximity for the active fleet.
- **Authentication:** Public
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "data": [
      {
        "bus_id": "a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
        "bus_number": "205",
        "registration_number": "KL-15-A-2051",
        "latitude": 9.9984,
        "longitude": 76.3025,
        "speed_kmh": 34.0,
        "heading_deg": 195.0,
        "current_stop": "Palarivattom Bypass Junction",
        "next_stop": "Kaloor Metro Station & Bus Stand",
        "eta_next_stop_mins": 4,
        "timestamp": "2026-09-26T18:00:00Z",
        "data_origin": "SIMULATED DATA"
      }
    ]
  }
  ```

### 13.2 `GET /api/locations/{bus_identifier}`
- **Purpose:** Returns location for a specific bus identified by bus number (e.g. `205`) or bus UUID.
- **Errors:** `404 Not Found` if bus is not found.

---

## 14. Cabin Occupancy & Crowd API (`/api/crowd`)

### 14.1 `GET /api/crowd`
- **Purpose:** Standardized fleet crowd density summary. Enforces standardized thresholds:
  - `LOW`: < 50%
  - `MODERATE`: 50% - 80%
  - `CROWDED`: > 80%
- **Authentication:** Public
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "data": [
      {
        "bus_id": "a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
        "bus_number": "205",
        "occupancy_pct": 41.8,
        "passenger_count": 23,
        "capacity": 55,
        "crowd_level": "LOW",
        "detection_source": "Simulated_Camera_YOLOv8",
        "privacy_standard": "PERSON_COUNTING_ONLY_NO_FACIAL_RECOGNITION",
        "timestamp": "2026-09-26T18:00:00Z",
        "data_origin": "SIMULATED DATA"
      }
    ]
  }
  ```

### 14.2 `GET /api/crowd/{bus_identifier}`
- **Purpose:** Returns crowd density metrics for a specific vehicle.
- **Errors:** `404 Not Found` if bus is not found.

---

## 15. Demand Predictions & Forecasting API (`/api/predictions`)

### 15.1 `GET /api/predictions`
- **Purpose:** Returns fleet/corridor crowd prediction trajectories across monitored corridors.
- **Authentication:** Public
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "data": [
      {
        "bus_number": "205",
        "route_number": "12",
        "corridor_name": "Aluva Metro ➔ Vyttila Mobility Hub via Kaloor",
        "horizon": {
          "now": { "occupancy_pct": 41.8, "crowd_level": "LOW", "confidence": 0.88 },
          "plus_15m": { "occupancy_pct": 45.2, "crowd_level": "LOW", "confidence": 0.88 },
          "plus_30m": { "occupancy_pct": 52.0, "crowd_level": "MODERATE", "confidence": 0.88 },
          "plus_60m": { "occupancy_pct": 64.5, "crowd_level": "MODERATE", "confidence": 0.81 }
        },
        "data_origin": "PREDICTION"
      }
    ]
  }
  ```

### 15.2 `GET /api/predictions/{bus_number}`
- **Purpose:** Returns 4-point forecast trajectory for a specific bus (`NOW`, `+15 MIN`, `+30 MIN`, `+60 MIN`).
- **Data Origin:** `PREDICTION`

### 15.3 `GET /api/occupancy/predictions`
- **Purpose:** Frontend compatibility endpoint returning 4-horizon prediction map dictionary.
- **Reuses:** Central `demand_forecaster` engine.

---

## 16. Service Alerts & Advisories API (`/api/alerts`)

### 16.1 `GET /api/alerts`
- **Purpose:** Returns public transit service alerts and detours from Supabase `alerts`.
- **Query Params:** `active_only` (boolean, default: `true`).

### 16.2 `GET /api/alerts/active`
- **Purpose:** Canonical alias for active corridor advisories.

### 16.3 `GET /api/alerts/{alert_id}`
- **Purpose:** Returns details for a specific alert.
- **Errors:** `404 Not Found` if alert is not found.

---

## 17. Payment Settlement & Audit API (`/api/payments`)

### 17.1 `GET /api/payments/my`
- **Purpose:** Returns payment transaction records for the authenticated passenger's bookings.
- **Authentication:** Bearer JWT required (`PASSENGER`, `AUTHORITY`). Unauthenticated returns `401 Unauthorized`.
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "pay-uuid",
        "ticket_id": "ticket-uuid",
        "amount": 20.0,
        "currency": "INR",
        "provider": "SANDBOX",
        "status": "SUCCESS",
        "created_at": "2026-09-26T18:00:00Z",
        "data_origin": "SIMULATED DATA"
      }
    ]
  }
  ```

### 17.2 `GET /api/payments`
- **Purpose:** Authority payment ledger audit endpoint.
- **Authentication:** Bearer JWT required (`AUTHORITY`).
- **Role Boundary:** `PASSENGER` and `DRIVER_CONDUCTOR` are rejected with `403 Forbidden`.

