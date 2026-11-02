# BusSense AI — External Transit Provider Onboarding Guide
## Standardized Integration Contracts, Onboarding Procedure & Provenance Standards

**Version:** 1.0.0-H19  
**Target Operating Region:** Greater Kochi Transit Network, Kerala, India  
**Scope:** Regional Transit Data Providers (KSRTC, KMRL, On-Bus Edge Cameras, Kerala Police)  
**Status:** **INTEGRATION-READY (STANDARDIZED PROTOCOLS & DEFENSIVE BOUNDARIES VERIFIED)**  
**Notice:** External connections require formal inter-agency authorization. Do not represent unverified connections as live feeds.

---

## 1. Overview & Core Philosophy

BusSense AI enforces strict boundary defense and honest data provenance across all transit data feeds:
- **Zero Fabrication:** If real agency credentials or physical telemetry are unavailable, adapters remain in an explicit `CONFIGURED_READY_FOR_FIELD` or `SIMULATED_BENCHMARK` status with truth stamps (`BENCHMARK`, `SIMULATED DATA`).
- **Cryptographic Access Control:** Ingestion endpoints require SHA-256 hashed API keys (`bs_live_<token>`) passed via the `X-Provider-API-Key` HTTP header.
- **Defensive Ingestion:** Automated rejection of invalid coordinates, non-numeric values (NaN/Inf), clock skew, out-of-order packets, and physically impossible velocities (>120 km/h).
- **Strict Zero-Biometrics Privacy:** CCTV headcount feeds must conform exclusively to `PERSON_COUNTING_ONLY_NO_BIOMETRICS`. Facial features, biometric landmarks, demographic classifications, and cross-stop passenger tracking are rejected at the schema boundary with **HTTP 422**.

---

## 2. Standardized Transit Adapter Specifications

### 2.1 KSRTC-SWIFT GPS Telematics Push Adapter (`KSRTC_SWIFT_AVL_ADAPTER`)

| Specification Dimension | Operational Requirement |
| :--- | :--- |
| **Adapter Identifier** | `KSRTC_SWIFT_AVL_ADAPTER` (Registered ID: `KSRTC-SWIFT-01`) |
| **Expected Source** | KSRTC-SWIFT Central Fleet Telematics System / NOC (Thiruvananthapuram / Kochi) |
| **Required Authorization**| KSRTC Intelligent Transport System (ITS) Data Sharing Agreement & Transport Commissionerate Clearance |
| **Authentication Method** | Cryptographic SHA-256 API Key in HTTP Header (`X-Provider-API-Key: bs_live_...`) |
| **Data Format** | JSON over HTTPS POST (`Content-Type: application/json`) |
| **Ingestion Endpoint** | `POST /api/ingest/gps` |
| **Expected Update Frequency**| 5.0 seconds per active vehicle |
| **Required Fields** | `feed_id`, `records[].bus_number`, `records[].latitude`, `records[].longitude`, `records[].speed_kmh`, `records[].heading_deg`, `records[].timestamp`, `records[].sequence_number` |
| **Validation Rules** | 1. Greater Kochi Bounding Box: Latitude $[9.8000, 10.3500]^\circ\text{N}$, Longitude $[76.1500, 76.5500]^\circ\text{E}$<br>2. Finite float check: Rejects NaN / $\pm\infty$<br>3. Speed sanity bounds: $0.0 \le v \le 120.0\text{ km/h}$<br>4. Monotonic sequence check: `sequence_number > last_sequence_number`<br>5. Clock skew guard: Timestamp not $>300\text{s}$ in future, not $>900\text{s}$ in past<br>6. Impossible velocity jump filter: Rejects $\Delta d / \Delta t > 120\text{ km/h}$ when $\Delta d > 500\text{m}$ |
| **Failure Handling** | HTTP 429 backoff; 3 automatic retries with exponential backoff ($2^n$ seconds); fallback to corridor schedule headway |
| **Rate Limits** | 120 requests / minute per provider (HTTP 429 when exceeded) |
| **Data Retention** | 90 days in partitioned Supabase / PostgreSQL storage; aggregate metrics retained permanently |

#### Sample GPS Telemetry Batch Request:
```json
{
  "feed_id": "KSRTC_SWIFT_AVL",
  "records": [
    {
      "bus_number": "205",
      "latitude": 10.0270,
      "longitude": 76.3080,
      "speed_kmh": 28.5,
      "heading_deg": 182.0,
      "timestamp": "2026-11-02T12:00:00Z",
      "sequence_number": 1042,
      "data_origin": "LIVE DATA"
    }
  ]
}
```

---

### 2.2 KMRL Feeder Bus Telematics Ingestion Adapter (`KMRL_FEEDER_AVL_ADAPTER`)

| Specification Dimension | Operational Requirement |
| :--- | :--- |
| **Adapter Identifier** | `KMRL_FEEDER_AVL_ADAPTER` (Registered ID: `KMRL-FEEDER-01`) |
| **Expected Source** | Kochi Metro Rail Limited (KMRL) Feeder Operations Center (JLN Stadium Metro Station) |
| **Required Authorization**| KMRL Multimodal Transit Integration Protocol Authorization |
| **Authentication Method** | Cryptographic SHA-256 API Key in HTTP Header (`X-Provider-API-Key`) |
| **Data Format** | JSON over HTTPS POST |
| **Ingestion Endpoint** | `POST /api/ingest/gps` |
| **Expected Update Frequency**| 3.0 seconds per active e-bus feeder |
| **Required Fields** | `feed_id`, `records[].bus_number`, `records[].latitude`, `records[].longitude`, `records[].speed_kmh`, `records[].heading_deg`, `records[].timestamp`, `records[].sequence_number` |
| **Validation Rules** | 1. Greater Kochi Bounding Box check<br>2. Feeder corridor waypoint match (Route 14A / Kakkanad Feeder)<br>3. Monotonic sequence & timestamp progression<br>4. Rejection of NaN/Inf and impossible acceleration/velocity |
| **Failure Handling** | HTTP 429 sliding-window backoff; cached last-known coordinates marked `STALE DATA` after 30s; marked `UNAVAILABLE` after 120s |
| **Rate Limits** | 120 requests / minute |
| **Data Retention** | 60 days in operational storage |

---

### 2.3 BusSense Edge Camera Headcount Gateway (`CCTV_HEADCOUNT_GATEWAY_ADAPTER`)

| Specification Dimension | Operational Requirement |
| :--- | :--- |
| **Adapter Identifier** | `CCTV_HEADCOUNT_GATEWAY_ADAPTER` (Registered ID: `CCTV-GATEWAY-01`) |
| **Expected Source** | On-bus edge AI computing units running YOLOv8 person detection |
| **Required Authorization**| Kerala Transport Department Computer Vision Privacy Compliance Certification |
| **Authentication Method** | Cryptographic SHA-256 API Key in HTTP Header (`X-Provider-API-Key`) |
| **Data Format** | JSON over HTTPS POST |
| **Ingestion Endpoint** | `POST /api/ingest/cctv-occupancy` |
| **Expected Update Frequency**| 10.0 seconds per doorway camera |
| **Required Fields** | `bus_number`, `timestamp`, `raw_person_count`, `stabilized_person_count`, `capacity`, `confidence_score`, `model_version`, `camera_id`, `privacy_standard` |
| **Validation Rules** | 1. Mandatory `privacy_standard == "PERSON_COUNTING_ONLY_NO_BIOMETRICS"`<br>2. Rejection of all facial embeddings, landmarks, demographics, and person tracking IDs<br>3. Licensed bus passenger capacity bounds: $1 \le C \le 120$<br>4. Confidence score threshold $\ge 0.40$ |
| **Failure Handling** | On camera edge failure or packet drop, system gracefully falls back to corridor historical demand forecasts (`PREDICTION` badge), preventing false zero-occupancy displays |
| **Rate Limits** | 60 requests / minute per edge camera gateway |
| **Data Retention** | 30 days of aggregate counts in PostgreSQL; zero video frames or facial images are ever retained |

#### Sample CCTV Headcount Ingestion Request:
```json
{
  "bus_number": "205",
  "timestamp": "2026-11-02T12:00:00Z",
  "raw_person_count": 28,
  "stabilized_person_count": 27,
  "capacity": 55,
  "confidence_score": 0.91,
  "model_version": "yolov8n_coco",
  "camera_id": "BUS_DOOR_CAM_01",
  "privacy_standard": "PERSON_COUNTING_ONLY_NO_BIOMETRICS",
  "data_origin": "CV REPLAY"
}
```

---

### 2.4 Kerala Police / Traffic Police Incident Feed Adapter (`KERALA_POLICE_DISRUPTION_ADAPTER`)

| Specification Dimension | Operational Requirement |
| :--- | :--- |
| **Adapter Identifier** | `KERALA_POLICE_DISRUPTION_ADAPTER` (Registered ID: `KERALA-POLICE-01`) |
| **Expected Source** | Kerala Police / Kochi City Traffic Police Incident Management Desk |
| **Required Authorization**| Kerala Police Traffic Incident Broadcasting Clearance |
| **Authentication Method** | Cryptographic SHA-256 API Key in HTTP Header (`X-Provider-API-Key`) |
| **Data Format** | JSON over HTTPS POST |
| **Ingestion Endpoint** | `POST /api/ingest/disruptions` |
| **Expected Update Frequency**| Event-driven (upon road accident, waterlogging, or VIP movement) |
| **Required Fields** | `route_number`, `cause`, `severity`, `description`, `affected_stops`, `estimated_duration_mins`, `is_active` |
| **Validation Rules** | 1. Valid corridor route ID (`R12_205`, `R12_14A`, etc.)<br>2. Valid severity enum (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`)<br>3. Valid cause enum (`TRAFFIC_CONGESTION`, `WATERLOGGING`, `ROAD_CONSTRUCTION`, `VEHICLE_BREAKDOWN`, `ACCIDENT`, `VIP_MOVEMENT`)<br>4. Duration bounds: $5 \le t \le 720\text{ minutes}$ |
| **Failure Handling** | Automatic poll retries; auto-cleared upon expiration time elapsed |
| **Rate Limits** | 30 requests / minute |
| **Data Retention** | 180 days for audit and safety analytics |

---

## 3. Provider Onboarding Procedure

When an authorized regional transit operator or municipal body agrees to integrate with BusSense AI, the following step-by-step onboarding procedure is executed:

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ Step 1: Legal   │       │ Step 2: Key     │       │ Step 3: Staging │
│ Authorization   ├──────►│ Registration    ├──────►│ Sandbox Feed    │
│ & MOU Signing   │       │ (SHA-256 Hash)  │       │ Verification    │
└─────────────────┘       └─────────────────┘       └────────┬────────┘
                                                             │
┌─────────────────┐       ┌─────────────────┐                │
│ Step 5: Live    │       │ Step 4: Pilot   │                ▼
│ Operational     │◄──────┤ Corridor Map-   │◄───────────────┘
│ Monitoring      │       │ Matching Audit  │
└─────────────────┘       └─────────────────┘
```

### Step 1: Legal Authorization & Agreement
- Transport authority or operator executes a formal Data Sharing Agreement specifying feed scopes (`AVL_GPS`, `CCTV_OCCUPANCY`, `ROUTE_SCHEDULE`, `DISRUPTION`).
- A technical point of contact (email and telephone) is registered.

### Step 2: Credential Generation & Role-Based Registration
- An authorized `AUTHORITY` or `ADMIN` user registers the provider in the Authority Command Console or via API:
  ```http
  POST /api/ingest/providers HTTP/1.1
  Host: bussense.kerala.gov.in
  Authorization: Bearer <authority_jwt>
  Content-Type: application/json

  {
    "provider_id": "KSRTC_SWIFT_KOCHI_01",
    "provider_name": "KSRTC-SWIFT Kochi Artery Fleet",
    "allowed_feed_types": ["AVL_GPS"],
    "contact_email": "swift-its@keralartc.com",
    "rate_limit_per_minute": 120,
    "expires_at": "2027-11-02T00:00:00Z"
  }
  ```
- **Response:** Returns the plaintext API key once:
  ```json
  {
    "provider_id": "KSRTC_SWIFT_KOCHI_01",
    "provider_name": "KSRTC-SWIFT Kochi Artery Fleet",
    "api_key": "bs_live_4a11f20e4b2d3989c74591a27e0293d0fbc761a2",
    "api_key_masked": "bs_live_...c761a2",
    "allowed_feed_types": ["AVL_GPS"],
    "is_active": true,
    "rate_limit_per_minute": 120,
    "expires_at": "2027-11-02T00:00:00Z"
  }
  ```
- The plaintext key is never displayed again. Only the SHA-256 digest is stored in the database.

### Step 3: Staging Sandbox Feed Verification
- The provider configures their push gateway to send test telemetry to the staging environment endpoint.
- Feeds are validated for:
  - Header authentication (`X-Provider-API-Key`).
  - Strict Bounding Box validation.
  - Coordinate format and sanity bounds.
  - Rate limiting behavior under burst conditions.

### Step 4: Corridor Map-Matching Audit
- Ingested test coordinates are matched against Kerala corridor waypoints (`CORRIDORS["R12_205"]` / `CORRIDORS["R12_14A"]`).
- Off-route alerts are evaluated to verify that buses operating on the designated route achieve deviation $< 500\text{ meters}$.

### Step 5: Promotion to Live Field Feed & Telemetry Provenance
- Upon successful staging verification, the provider is promoted to active operational status.
- Every accepted telemetry record is tagged with its source provider, received timestamp, and truth label (`LIVE DATA`), ensuring full provenance auditing in the Authority Command Console.
