# BusSense AI — Feature Inventory

This document tracks all features across the Passenger, Driver/Conductor, and Transport Authority workspaces, recording their implementation status, architectural touchpoints, and production requirements.

### Status Definitions:
- `IMPLEMENTED`: Fully functional in the active codebase with passing automated tests.
- `IN PROGRESS`: Active implementation currently underway.
- `TESTING`: Developed and undergoing validation or integration verification.
- `PLANNED`: Architected and scheduled for upcoming development milestones.
- `BLOCKED`: Dependent on external physical hardware or unconfigured API credentials.
- `DEPRECATED`: Superseded by newer architectural paradigms.

---

## 1. Passenger Experience Features

| Feature | Role | Description | Status | Frontend | Backend | Database | External Dep | Demo? | Production Requirement |
|---|---|---|---|---|---|---|---|---|---|
| **Live Corridor Departures** | Passenger | Glanceable countdown cards for upcoming buses along active route. | `IMPLEMENTED` | `/passenger/home` | `GET /api/buses` | `buses`, `trips` | None | YES | Realtime GPS vehicle tracking |
| **Crowd Transparency Meter** | Passenger | Live passenger load badge (LOW <50%, MODERATE 50-80%, CROWDED >80%). | `IMPLEMENTED` | `/passenger/home` | `GET /api/occupancy` | `occupancy_readings` | None | YES | Onboard YOLOv8 camera inference |
| **Smart Bus Recommendation** | Passenger | Multi-factor score evaluating seat probability, duration, and priority lane advantage. | `IMPLEMENTED` | `/passenger/home` | `GET /api/recommendations` | `bus_recommendations` | None | YES | Ridge crowd forecasting models |
| **"Why This Bus?" Drawer** | Passenger | Explainable breakdown of journey score factors and alternative comparison. | `IMPLEMENTED` | `/passenger/home` | `GET /api/recommendations` | `bus_recommendations` | None | YES | None |
| **Corridor Route Planner** | Passenger | Search transit routes between origin and destination with schedule filters. | `IMPLEMENTED` | `/passenger/explore` | `GET /api/routes` | `routes`, `stops`, `route_stops` | None | YES | GTFS transit schedule feed |
| **60-Minute Crowd Forecast** | Passenger | Temporal demand curve predicting vehicle occupancy at +15, +30, +60 mins. | `IMPLEMENTED` | `/passenger/explore` | `GET /api/occupancy/predictions` | `crowd_predictions` | scikit-learn | YES | Historical corridor sensor logs |
| **Digital QR Boarding Pass** | Passenger | Base64 PNG QR code pass with remaining validity timer and route badge. | `IMPLEMENTED` | `/passenger/tickets` | `POST /api/tickets/book` | `tickets`, `payments` | qrcode | YES | Razorpay Payment Gateway |
| **Active Journey HUD** | Passenger | Real-time onboard trip monitor showing approaching stops and onboard speed. | `IMPLEMENTED` | `/passenger/journey` | `GET /api/buses/{id}` | `trips`, `gps_positions` | None | YES | Realtime in-vehicle GPS stream |
| **Grounded Transit Assistant** | Passenger | RAG conversational QA bot for Kerala transit guidelines and bus status. | `IMPLEMENTED` | `/passenger/assistant` | `POST /api/ai/query` | `knowledge_chunks` | LLM API / Local | YES | Supabase pgvector embeddings |
| **Privacy & Data Hub** | Passenger | Commuter privacy dashboard detailing zero biometric data retention. | `IMPLEMENTED` | `/passenger/profile` | None (Static Policy) | None | None | YES | GDPR/DPDP compliance audits |
| **Native Flutter App** | Passenger | iOS/Android native mobile client packaging. | `PLANNED` | Flutter repo | `backend/` | Supabase | App Store / Play Store | NO | Mobile developer signing keys |

---

## 2. Driver & Conductor Features

| Feature | Role | Description | Status | Frontend | Backend | Database | External Dep | Demo? | Production Requirement |
|---|---|---|---|---|---|---|---|---|---|
| **Shift Check-In & Pairing** | Driver | Authenticated driver credential sign-in and vehicle pairing (e.g., Bus 205). | `IMPLEMENTED` | `/roles` & `/driver/cockpit` | `POST /api/auth/login` | `users`, `drivers`, `buses` | None | YES | Smartcard/Biometric duty login |
| **High-Contrast Cockpit HUD** | Driver | Night/day high-visibility cockpit display for stop ETA and schedule delta. | `IMPLEMENTED` | `/driver/cockpit` | `GET /api/buses/{id}` | `trips`, `routes` | None | YES | Ruggedized vehicle dashboard |
| **Live Cabin Occupancy HUD**| Driver | Real-time seat tally (e.g. 23/55 seats) fed by camera head count. | `IMPLEMENTED` | `/driver/cockpit` | `GET /api/occupancy` | `occupancy_readings` | OpenCV/YOLOv8 | YES | Wide-angle vehicle CCTV |
| **Rapid Incident Logger** | Driver | 1-tap hazard reporting (Breakdown, Traffic, Route Detour, Emergency). | `IMPLEMENTED` | `/driver/incident` | `POST /api/incidents` | `incidents`, `alerts` | None | YES | Driver emergency radio link |
| **QR Boarding Pass Validator**| Conductor | Rapid QR scanner with 3-state instant validation feedback. | `IMPLEMENTED` | `/driver/validator` | `POST /api/tickets/validate` | `tickets`, `ticket_validations` | None | YES | Handheld QR laser/camera scanner |
| **Trip Layover & Staging** | Driver | Terminal arrival staging, rest window timer, and inspection checklist. | `IMPLEMENTED` | `/driver/layover` | `GET /api/buses/{id}` | `trips` | None | YES | Depot dispatch geofence |

---

## 3. Transport Authority & Operations Features

| Feature | Role | Description | Status | Frontend | Backend | Database | External Dep | Demo? | Production Requirement |
|---|---|---|---|---|---|---|---|---|---|
| **Unified Command Center** | Authority | Dual-pane GIS map with active bus telemetry pins and operational drawer. | `IN PROGRESS` | `/authority/command` | `GET /api/buses` | `buses`, `gps_positions` | Leaflet / MapLibre | YES | Full fleet AVL GPS stream |
| **Live Fleet Directory** | Authority | Tabular inventory of active fleet vehicles, assigned drivers, and status. | `IN PROGRESS` | `/authority/fleet` | `GET /api/buses` | `buses`, `trips` | None | YES | Fleet telematics gateway |
| **Corridor Network Monitor**| Authority | Route configuration, intermediate stop geofences, and headway tracking. | `IN PROGRESS` | `/authority/routes` | `GET /api/routes` | `routes`, `stops` | None | YES | Spatial GIS shapefiles |
| **Predictive Crowd Horizon** | Authority | 60-minute regional demand curves anticipating commuter surges at key hubs. | `IN PROGRESS` | `/authority/forecast` | `GET /api/occupancy/predictions` | `crowd_predictions` | scikit-learn | YES | Municipal event & weather feeds |
| **AI Operational Queue** | Authority | Human-in-the-loop dispatch queue recommending tripper buses & express routes. | `IN PROGRESS` | `/authority/ai-ops` | `GET /api/analytics` | `reports`, `alerts` | None | YES | Central transit controller approval |
| **Incident Triage Queue** | Authority | Real-time queue for reviewing driver incident reports and dispatching tow/relief. | `IN PROGRESS` | `/authority/alerts` | `GET /api/incidents` | `incidents`, `alerts` | None | YES | Regional dispatch radio integration |
| **Sustainability Reporting**| Authority | Fuel economy, carbon offset calculation, and operational audit reports. | `IN PROGRESS` | `/authority/reports` | `GET /api/analytics` | `reports` | None | YES | Telematics fuel/energy sensor data |
| **Universal Role Switcher** | All Roles | Seamless demo switcher to toggle between Passenger, Driver, and Authority. | `IMPLEMENTED` | `/roles` | `POST /api/auth/login` | `users`, `roles` | None | YES | Permissive demo security mode |
