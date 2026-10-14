# BusSense AI — Functional Specification

This document details the functional specifications for the 23 core algorithmic, operational, and data-processing routines in BusSense AI.

---

## 1. calculate_occupancy()
- **Purpose:** Computes vehicle cabin load percentage from passenger count and seating capacity.
- **Input:** `passenger_count: int`, `bus_capacity: int`
- **Output:** `occupancy_percentage: float`, `crowd_level: str`
- **Formula:** `occupancy_percentage = round((passenger_count / bus_capacity) * 100, 1)`
- **User Role:** Passenger, Driver, Authority
- **Backend Endpoint:** `GET /api/occupancy/{bus_id}`
- **Database Tables:** `buses`, `occupancy_readings`
- **Business Rules:**
  - `< 50.0%` = `LOW`
  - `50.0% – 80.0%` = `MODERATE`
  - `> 80.0%` = `CROWDED`
- **Error States:** Returns `400 Bad Request` if `bus_capacity <= 0` or `passenger_count < 0`.
- **Demo Behavior:** Evaluates simulated passenger counts (e.g., 23 / 55 = 41.8%).
- **Production Behavior:** Ingests bounding box counts from on-bus edge computer vision inference.
- **Dependencies:** Python `math`
- **Implementation Status:** `IMPLEMENTED` (`backend/app/services/cv_occupancy.py:calculate_occupancy`)

---

## 2. classify_crowd()
- **Purpose:** Classifies occupancy percentage into standardized system crowd density tiers.
- **Input:** `occupancy_percentage: float`
- **Output:** `crowd_tier: str` (`"LOW"` | `"MODERATE"` | `"CROWDED"`)
- **User Role:** Passenger, Driver, Authority
- **Backend Endpoint:** Internal service call
- **Database Tables:** `occupancy_readings`
- **Business Rules:** Thresholds are immutable system invariants: `<50% LOW`, `50-80% MODERATE`, `>80% CROWDED`.
- **Error States:** Defaults to `"MODERATE"` if input is `None` or invalid.
- **Demo Behavior:** Synchronous threshold check.
- **Production Behavior:** Synchronous threshold check.
- **Dependencies:** None
- **Implementation Status:** `IMPLEMENTED` (`backend/app/services/cv_occupancy.py:classify_crowd`)

---

## 3. calculate_eta()
- **Purpose:** Calculates expected time of arrival between current vehicle coordinates and target transit stop.
- **Input:** `current_lat: float`, `current_lng: float`, `target_lat: float`, `target_lng: float`, `speed_kmh: float`
- **Output:** `eta_minutes: int`, `distance_km: float`
- **User Role:** Passenger, Driver, Authority
- **Backend Endpoint:** `GET /api/buses/{bus_id}/eta`
- **Database Tables:** `gps_positions`, `stops`, `route_stops`
- **Business Rules:** Uses Haversine distance formula with a 1.25 urban corridor circuity winding factor. If speed < 5 km/h, falls back to corridor baseline speed (24 km/h).
- **Error States:** Returns `eta_minutes: 1` if calculated distance is `< 0.05 km`.
- **Demo Behavior:** Evaluates current interpolated waypoint position along Kerala corridors.
- **Production Behavior:** Integrates with real-time AVL GPS streams and traffic congestion layers.
- **Dependencies:** Python `math` (radians, sin, cos, atan2)
- **Implementation Status:** `IMPLEMENTED` (`backend/app/services/gps_simulator.py:calculate_eta`)

---

## 4. simulate_gps()
- **Purpose:** Generates realistic vehicle transit physics along defined Kerala corridor coordinates.
- **Input:** `route_id: str`, `elapsed_seconds: float`
- **Output:** `latitude: float`, `longitude: float`, `speed: float`, `heading: float`, `current_stop_id: str`
- **User Role:** System Background Worker
- **Backend Endpoint:** Background task / WebSocket `/ws/telemetry`
- **Database Tables:** `gps_positions`, `routes`, `stops`
- **Business Rules:** Interpolates between sequential waypoints; applies micro-jitter and speed damping (0 km/h at stops, 35–45 km/h along bypass).
- **Error States:** Loops back to origin stop when route terminal waypoint is passed.
- **Demo Behavior:** Runs continuous 2.0-second simulation ticker.
- **Production Behavior:** Disabled in production; replaced by physical GPS NMEA/MQTT parser.
- **Dependencies:** `backend/app/services/gps_simulator.py`
- **Implementation Status:** `IMPLEMENTED`

---

## 5. predict_demand()
- **Purpose:** Forecasts passenger boarding volume for a given transit route stop and time.
- **Input:** `stop_id: str`, `hour_of_day: int`, `day_of_week: int`, `weather_condition: str`
- **Output:** `predicted_boarding_volume: int`, `confidence_score: float`
- **User Role:** Authority, Passenger
- **Backend Endpoint:** `GET /api/analytics/demand-forecast`
- **Database Tables:** `crowd_predictions`, `stops`
- **Business Rules:** Predicts influx using cyclical temporal encodings (`sin_hour`, `cos_hour`).
- **Error States:** Returns baseline historical median if feature vector is outside range.
- **Demo Behavior:** Ridge regression model trained on Kerala peak office hour synthetic telemetry.
- **Production Behavior:** Online learning Ridge/LightGBM model retraining on automated passenger counting (APC) logs.
- **Dependencies:** `scikit-learn`, `numpy`
- **Implementation Status:** `IMPLEMENTED` (`backend/app/services/demand_forecaster.py:predict_demand`)

---

## 6. forecast_crowding()
- **Purpose:** Predicts bus crowding tiers for future departure horizons (+0, +15, +30, +60 minutes).
- **Input:** `bus_id: str`, `route_id: str`, `horizons: List[int]`
- **Output:** `Dict[str, HorizonPrediction]` (now, +15m, +30m, +60m)
- **User Role:** Passenger, Authority
- **Backend Endpoint:** `GET /api/occupancy/predictions`
- **Database Tables:** `crowd_predictions`, `buses`
- **Business Rules:** Combines current CV occupancy with downstream stop demand forecasts.
- **Error States:** Fallback to current occupancy tier if model prediction fails.
- **Demo Behavior:** Produces multi-horizon forecasts badged with `PREDICTION`.
- **Production Behavior:** Ingests live weather alerts, holiday calendars, and corridor congestion telemetry.
- **Dependencies:** `backend/app/services/demand_forecaster.py`
- **Implementation Status:** `IMPLEMENTED`

---

## 7. recommend_bus()
- **Purpose:** Selects the optimal bus for a passenger traveling between two stops.
- **Input:** `origin_stop_id: str`, `destination_stop_id: str`, `user_preference: str`
- **Output:** `RecommendedBusPayload` (primary bus, score, reason, alternatives)
- **User Role:** Passenger
- **Backend Endpoint:** `GET /api/recommendations`
- **Database Tables:** `buses`, `routes`, `occupancy_readings`, `bus_recommendations`
- **Business Rules:** Evaluates arriving candidates within 30-minute window; ranks by composite Journey Score.
- **Error States:** Returns empty candidate list if no buses service the selected corridor.
- **Demo Behavior:** Recommends Bus 205 (Fast Passenger) or 14A based on live occupancy.
- **Production Behavior:** Real-time multi-agency routing across KSRTC and private stage carriages.
- **Dependencies:** `backend/app/services/recommendation_engine.py`
- **Implementation Status:** `IMPLEMENTED`

---

## 8. calculate_journey_score()
- **Purpose:** Calculates a normalized (0–100) utility score for a candidate bus.
- **Input:** `seat_probability: float`, `travel_time_min: int`, `comfort_rating: float`, `has_priority_lane: bool`
- **Formula:** `score = (seat_prob * 0.40) + ((60 - travel_time)/60 * 0.30) + (comfort * 0.20) + (priority * 0.10)`
- **Output:** `journey_score: int` (0 to 100)
- **User Role:** Passenger, Recommendation Engine
- **Backend Endpoint:** Internal engine routine
- **Database Tables:** None (Transient calculation)
- **Business Rules:** Penalizes crowded buses (>80% occupancy) by 25 points.
- **Error States:** Clamped between 10 and 99.
- **Demo Behavior:** Deterministic scoring with factor breakdown.
- **Production Behavior:** User-weighted scoring based on commuter historical profile.
- **Dependencies:** None
- **Implementation Status:** `IMPLEMENTED` (`backend/app/services/recommendation_engine.py`)

---

## 9. create_ticket()
- **Purpose:** Generates a new digital transit ticket booking and issues an authorized pass, persisted directly to Supabase.
- **Input:** `user_id: str`, `passenger_name: str`, `bus_number: str`, `route_number: str`, `origin_stop: str`, `destination_stop: str`, `fare_amount: float`
- **Output:** `TicketResponse` (id, ticket_number, qr_code_hash, qr_code_data_uri, status, valid_until)
- **User Role:** Passenger
- **Backend Endpoint:** `POST /api/tickets/book`
- **Database Tables:** `tickets`, `payments`, `buses`, `routes`
- **Business Rules:**
  - Foreign keys for `bus_id` and `route_id` are resolved dynamically from Supabase.
  - Generates unique ticket number (`BS-KL-2026-XXXX`).
  - Writes persistent ticket row into `tickets` table and simulated payment row into `payments` table.
- **Error States:** `401 Unauthorized` if not authenticated.
- **Demo Behavior:** Instant simulated payment; writes to Supabase PostgreSQL.
- **Production Behavior:** Connects to payment gateway webhook before issuing ticket.
- **Dependencies:** `backend/app/services/ticket_service.py:book_ticket`
- **Implementation Status:** `IMPLEMENTED (Database-backed)`

---

## 10. validate_ticket()
- **Purpose:** Atomically verifies authenticity and single-use validity of a passenger QR pass in Supabase.
- **Input:** `qr_hash: str`, `bus_number: str`, `conductor_id: str`
- **Output:** `TicketValidationResponse` (result: `"VALID"` | `"ALREADY_USED"` | `"EXPIRED"` | `"INVALID"`, passenger_name, route)
- **User Role:** Driver / Conductor, Authority
- **Backend Endpoint:** `POST /api/tickets/validate`
- **Database Tables:** `tickets`, `ticket_validations`
- **Database Procedure:** `validate_ticket_atomic(p_qr_hash, p_conductor_id, p_bus_id)`
- **Business Rules:**
  - Employs row-level locking (`FOR UPDATE`) to prevent concurrent double-validation race conditions.
  - If ticket is already `USED`, returns `ALREADY_USED` and logs audit entry.
  - If `now > valid_until` or `status = 'EXPIRED'`, returns `EXPIRED`.
  - On valid scan, transitions ticket status to `USED` and records row in `ticket_validations`.
- **Error States:** Returns `INVALID` if ticket QR hash does not exist in database.
- **Demo Behavior:** Sub-second atomic database validation testable via `/driver/validator`.
- **Dependencies:** `backend/app/services/ticket_service.py:validate_ticket_qr`
- **Implementation Status:** `IMPLEMENTED (Database-backed atomic RPC)`

---

## 11. generate_qr()
- **Purpose:** Encodes ticket verification payload into high-density Base64 PNG QR code data URI.
- **Input:** `ticket_id: str`, `verification_hash: str`
- **Output:** `qr_data_uri: str` (`data:image/png;base64,...`)
- **User Role:** System / Passenger
- **Backend Endpoint:** Internal service call
- **Database Tables:** None
- **Business Rules:** Uses Error Correction Level M, box size 8, border 2.
- **Error States:** Throws `QREncodingError` if payload exceeds byte capacity.
- **Demo Behavior:** In-memory generation using Python `qrcode` and `io.BytesIO`.
- **Production Behavior:** Identical; verified zero disk write overhead.
- **Dependencies:** `qrcode`, `Pillow`
- **Implementation Status:** `IMPLEMENTED` (`backend/app/services/ticket_service.py`)

---

## 12. create_incident()
- **Purpose:** Logs a road hazard, vehicle defect, or medical emergency from the vehicle cockpit into Supabase.
- **Input:** `bus_number: str`, `route_number: str`, `category: str`, `severity: str`, `title: str`, `description: str`
- **Output:** `IncidentResponse` (id, status: `"REPORTED"`, created_at, reporter_id)
- **User Role:** Driver / Conductor, Authority
- **Backend Endpoint:** `POST /api/incidents/report`
- **Database Tables:** `incidents`, `buses`, `routes`
- **Business Rules:** Persists directly into Supabase PostgreSQL table `incidents`.
- **Error States:** `401 Unauthorized` if unauthenticated, `403 Forbidden` if passenger role.
- **Demo Behavior:** Stored in Supabase `incidents` table and retrievable via `GET /api/incidents/`.
- **Dependencies:** `backend/app/api/incidents.py:report_incident`
- **Implementation Status:** `IMPLEMENTED (Database-backed)`

---

## 13. resolve_incident()
- **Purpose:** Closes an open incident and records officer resolution actions in Supabase.
- **Input:** `incident_id: str`, `resolution_notes: str`
- **Output:** `IncidentResponse` (status: `"RESOLVED"`, resolved_at)
- **User Role:** Transport Authority
- **Backend Endpoint:** `POST /api/incidents/{incident_id}/resolve`
- **Database Tables:** `incidents`
- **Business Rules:** Only users with `AUTHORITY` or `ADMIN` role can resolve incidents. Updates Supabase record using parameterized PATCH.
- **Error States:** `404 Not Found` if incident does not exist in Supabase; `403 Forbidden` for drivers/passengers.
- **Demo Behavior:** Updates incident status to `RESOLVED` in Supabase PostgreSQL; survives server restarts.
- **Dependencies:** `backend/app/api/incidents.py:resolve_incident`
- **Implementation Status:** `IMPLEMENTED (Database-backed)`

---

## 14. send_notification()
- **Purpose:** Dispatches push notifications to mobile clients for bus arrivals, alerts, or ticket confirmations.
- **Input:** `user_id: str`, `title: str`, `body: str`, `notification_type: str`
- **Output:** `NotificationSchema` (notification_id, sent_at)
- **User Role:** System Background Service
- **Backend Endpoint:** Internal event trigger
- **Database Tables:** `notifications`
- **Business Rules:** Commuter must have enabled the respective notification topic in preferences.
- **Error States:** Silently logs delivery failure if user token is invalid.
- **Demo Behavior:** Inserts row into Supabase `notifications` table for display in app notification center.
- **Production Behavior:** Integrates with Firebase Cloud Messaging (FCM) APNs/GCM gateways.
- **Dependencies:** FCM SDK (when configured)
- **Implementation Status:** `PLANNED` / `TODO`

---

## 15. retrieve_ai_context()
- **Purpose:** Fetches relevant knowledge chunks and real-time transit telemetry for an AI prompt.
- **Input:** `query_text: str`
- **Output:** `List[Dict]` (grounded policy chunks, matching bus IDs, active corridor state)
- **User Role:** System / Passenger Assistant
- **Backend Endpoint:** Internal RAG service call
- **Database Tables:** `knowledge_chunks`, `buses`, `routes`, `stops`
- **Business Rules:** Performs hybrid keyword/metadata filtering over verified Kerala transit documents.
- **Error States:** Returns empty context list if no matching tokens exist.
- **Demo Behavior:** Matches bus IDs and corridor names to live database state.
- **Production Behavior:** Uses pgvector cosine similarity search on OpenAI/Vertex embeddings.
- **Dependencies:** `backend/app/services/rag_service.py`
- **Implementation Status:** `IMPLEMENTED`

---

## 16. generate_ai_response()
- **Purpose:** Produces a strictly grounded answer to a user query with cited evidence.
- **Input:** `query: str`, `conversation_history: List[Dict]`
- **Output:** `AIQueryResponse` (answer: str, sources: List[str], live_bus_context: Optional[Dict])
- **User Role:** Passenger, Authority
- **Backend Endpoint:** `POST /api/ai/query`
- **Database Tables:** `ai_conversations`, `knowledge_chunks`
- **Business Rules:** Must follow the fallback protocol: *"I don't have enough reliable information to answer that."* if context is insufficient. Never invents bus schedules or fares.
- **Error States:** Returns graceful fallback on timeout.
- **Demo Behavior:** Evaluates RAG query pipeline in `rag_service.py` with mock/local LLM fallback.
- **Production Behavior:** Connects to Gemini / Claude / OpenAI API with temperature 0.0.
- **Dependencies:** `backend/app/services/rag_service.py`
- **Implementation Status:** `IMPLEMENTED`

---

## 17. search_routes()
- **Purpose:** Searches transit routes connecting origin and destination stops.
- **Input:** `origin_id: Optional[str]`, `destination_id: Optional[str]`, `query: Optional[str]`
- **Output:** `List[RouteSchema]`
- **User Role:** Passenger, Authority
- **Backend Endpoint:** `GET /api/routes`
- **Database Tables:** `routes`, `stops`, `route_stops`
- **Business Rules:** Returns routes where origin stop sequence index is strictly less than destination stop sequence index.
- **Error States:** Returns empty array if no continuous route exists.
- **Demo Behavior:** Filters Kerala corridors (Route 12, Route 14A, Route 205).
- **Production Behavior:** Integrates with OpenTripPlanner / GTFS routing graph.
- **Dependencies:** `backend/app/api/routes.py`
- **Implementation Status:** `IMPLEMENTED`

---

## 18. find_nearby_buses()
- **Purpose:** Returns active buses within a spatial bounding box or corridor distance.
- **Input:** `latitude: float`, `longitude: float`, `radius_km: float`
- **Output:** `List[BusWithTelemetry]`
- **User Role:** Passenger
- **Backend Endpoint:** `GET /api/buses/nearby`
- **Database Tables:** `buses`, `gps_positions`
- **Business Rules:** Computes Haversine distance from commuter coordinate; filters vehicles where `distance <= radius_km`.
- **Error States:** Defaults to `radius_km = 3.0` if unspecified.
- **Demo Behavior:** Filters active Kerala corridor fleet positions.
- **Production Behavior:** PostGIS spatial query (`ST_DWithin`).
- **Dependencies:** `backend/app/api/buses.py`
- **Implementation Status:** `IMPLEMENTED`

---

## 19. calculate_fare()
- **Purpose:** Computes distance-based passenger travel fare across route stops.
- **Input:** `origin_stop_id: str`, `destination_stop_id: str`, `service_type: str`
- **Formula:** `fare = max(10.0, 10.0 + (distance_km * 1.50))` (with 1.3x multiplier for AC services)
- **Output:** `fare_amount: float` (in INR ₹)
- **User Role:** Passenger, Conductor
- **Backend Endpoint:** `GET /api/tickets/fare`
- **Database Tables:** `route_stops`, `routes`
- **Business Rules:** Minimum Kerala ordinary stage carriage fare is ₹10. Fast Passenger / AC Premium is ₹20.
- **Error States:** Throws `400 Bad Request` if stop IDs are invalid.
- **Demo Behavior:** Evaluates corridor distance table.
- **Production Behavior:** Synchronizes with official Kerala Motor Vehicles Department gazette tariff tables.
- **Dependencies:** `backend/app/services/ticket_service.py`
- **Implementation Status:** `IMPLEMENTED`

---

## 20. update_trip()
- **Purpose:** Progresses the active trip state machine as the vehicle navigates its corridor.
- **Input:** `trip_id: str`, `status: str` (`NOT_STARTED` | `ACTIVE` | `COMPLETED`), `current_stop_id: str`
- **Output:** `TripSchema`
- **User Role:** Driver, System Simulator
- **Backend Endpoint:** `PATCH /api/buses/{bus_id}/trip`
- **Database Tables:** `trips`, `buses`
- **Business Rules:** Transitioning to `COMPLETED` triggers turnaround layover staging.
- **Error States:** Rejects invalid lifecycle transitions (e.g. `COMPLETED` -> `NOT_STARTED`).
- **Demo Behavior:** Automatically updated by `gps_simulator.py`.
- **Production Behavior:** Triggered by vehicle onboard Android/Linux computer.
- **Dependencies:** `backend/app/services/gps_simulator.py`
- **Implementation Status:** `IMPLEMENTED`

---

## 21. update_bus_location()
- **Purpose:** Ingests a new GPS coordinate fix for a bus and updates real-time tracking tables.
- **Input:** `bus_id: str`, `latitude: float`, `longitude: float`, `speed: float`, `heading: float`
- **Output:** `GPSPositionSchema`
- **User Role:** System, Vehicle IoT Gateway
- **Backend Endpoint:** `POST /api/buses/{bus_id}/location`
- **Database Tables:** `gps_positions`, `buses`
- **Business Rules:** Inserts historical record and updates `buses.updated_at`.
- **Error States:** Discards coordinate fixes where latitude or longitude is out of range.
- **Demo Behavior:** Populated every 2 seconds by simulation worker.
- **Production Behavior:** Ingests MQTT telematics stream from Teltonika/Quectel vehicle tracker.
- **Dependencies:** `backend/app/api/buses.py`
- **Implementation Status:** `IMPLEMENTED`

---

## 22. update_occupancy()
- **Purpose:** Records an updated passenger occupancy tally and crowd tier.
- **Input:** `bus_id: str`, `passenger_count: int`, `detection_source: str`
- **Output:** `OccupancyReadingSchema`
- **User Role:** System, Computer Vision Edge Agent
- **Backend Endpoint:** `POST /api/occupancy`
- **Database Tables:** `occupancy_readings`, `buses`
- **Business Rules:** Clamps passenger count between 0 and `bus_capacity * 1.5` (crush load limit).
- **Error States:** Returns `400 Bad Request` if bus does not exist.
- **Demo Behavior:** Broadcasts updated occupancy over WebSocket.
- **Production Behavior:** Triggered by edge YOLOv8 process on arrival at each stop.
- **Dependencies:** `backend/app/api/occupancy.py`
- **Implementation Status:** `IMPLEMENTED`

---

## 23. generate_report()
- **Purpose:** Compiles weekly and monthly network operational reports, carbon offset calculations, and on-time statistics.
- **Input:** `corridor_id: Optional[str]`, `date_from: str`, `date_to: str`
- **Output:** `ReportSchema` (total_passengers, on_time_rate, co2_offset_tonnes, recommendations)
- **User Role:** Transport Authority
- **Backend Endpoint:** `POST /api/analytics/reports`
- **Database Tables:** `reports`, `trips`, `occupancy_readings`
- **Business Rules:** Computes CO2 savings assuming 0.12 kg CO2 saved per passenger-km compared to private cars.
- **Error States:** Returns `400 Bad Request` if `date_from > date_to`.
- **Demo Behavior:** Generates formatted Kerala transit corridor intelligence reports.
- **Production Behavior:** Scheduled cron job exporting PDF/Excel archives for transport ministry.
- **Dependencies:** `backend/app/api/analytics.py`
- **Implementation Status:** `IMPLEMENTED`
