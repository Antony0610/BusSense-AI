# BusSense AI — Stakeholder Demonstration Guide
## Step-by-Step Script for Live Technical & Executive Demonstrations

**Target Audience:** Transport Commissioners, KSRTC Executives, KMRL Directors, Technical Evaluation Committees  
**Demonstration Length:** 25–35 Minutes  
**Demonstration Mode:** Controlled Simulation & Staging Validation Mode  
**Version:** 1.0.0-H21

---

## 1. Pre-Demonstration Checklist & Environment Setup

Before commencing the demonstration, verify system readiness:

```powershell
# 1. Verify backend services are active
curl -s http://localhost:8000/health

# 2. Verify Next.js Authority Dashboard is active
curl -s http://localhost:3000

# 3. Verify automated demonstration regression suite passes
& "backend/.venv/Scripts/python.exe" -m pytest backend/tests/test_stakeholder_demo_h21.py -v
```

### Demonstration Credentials
- **Passenger User:** `demo@bussense.ai` (Role: `PASSENGER`)
- **Conductor User:** `conductor@bussense.ai` (Role: `DRIVER_CONDUCTOR`)
- **Authority Officer:** `admin@bussense.ai` (Role: `AUTHORITY`)

---

## 2. The 11-Step Live Demonstration Walkthrough

```
  [Commuter Flow]              [Conductor Flow]            [Authority Cockpit]
  1. Browse Corridors          7. Scan QR Code             9.  View Live Fleet Map
  2. Locate Stops              8. Verify Anti-Replay       10. Review 4-Horizon Demand
  3. Inspect Crowd Status                                  11. Pilot Telemetry & Audit
  4. Get Smart Advice
  5. Book Digital Ticket
  6. View Boarding QR Pass
```

---

### Step 1: Commuter Corridor Discovery
*Demonstrates that commuters can instantly discover available transit corridors in Greater Kochi.*
- **UI Action:** Open Mobile App ➔ Corridor Explorer.
- **API Call:**
  ```bash
  curl -s -X GET "http://localhost:8000/api/routes" \
    -H "Authorization: Bearer <PASSENGER_JWT>"
  ```
- **Talking Point:** *"Notice Route 205 connecting Aluva Metro to Vyttila Hub and Route 14A connecting Fort Kochi to Infopark. The system maintains clean spatial definitions and corridor distances."*

---

### Step 2: Live Vehicle Tracking & Map-Matching
*Shows real-time vehicle GPS positions snapped directly to the designated transit corridor.*
- **UI Action:** View live bus icons moving smoothly along the corridor map.
- **API Call:**
  ```bash
  curl -s -X GET "http://localhost:8000/api/locations" \
    -H "Authorization: Bearer <PASSENGER_JWT>"
  ```
- **Talking Point:** *"Raw GPS often jitters into parallel alleys. BusSense AI snaps coordinates to the corridor using monotonic Haversine map-matching. If a bus deviates by more than 500 meters, an automated off-route alert is issued."*

---

### Step 3: Real-Time Crowd & Occupancy Visibility
*Demonstrates transparent passenger load tiers derived from onboard camera headcounts.*
- **UI Action:** Inspect the crowd pill on Route 205 (`LOW < 50%`, `MODERATE 50–80%`, `CROWDED > 80%`).
- **API Call:**
  ```bash
  curl -s -X GET "http://localhost:8000/api/crowd" \
    -H "Authorization: Bearer <PASSENGER_JWT>"
  ```
- **Talking Point:** *"Commuters see current cabin density before deciding to board. Notice the explicit truth badge: 'SIMULATED DATA' or 'CV REPLAY', ensuring absolute operational honesty."*

---

### Step 4: AI-Driven Explainable Journey Recommendation
*Shows how the platform balances travel time, fare, and cabin crowding without opaque black-box decisions.*
- **UI Action:** Plan journey from *Kaloor Metro Station* to *Vyttila Mobility Hub* with `balanced` preference.
- **API Call:**
  ```bash
  curl -s -X POST "http://localhost:8000/api/recommendations/plan" \
    -H "Authorization: Bearer <PASSENGER_JWT>" \
    -H "Content-Type: application/json" \
    -d '{
      "origin": "Kaloor Metro Station, Kochi",
      "destination": "Vyttila Mobility Hub",
      "preference": "balanced"
    }'
  ```
- **Talking Point:** *"The AI recommendation is strictly advisory. It evaluates four factors: travel time, fare, crowd load, and reliability. Notice the natural explanation justifying why Bus 205 is chosen over a crowded alternative."*

---

### Step 5: Digital Ticket Booking
*Demonstrates instant paperless ticket issuance.*
- **UI Action:** Tap 'Book Ticket' on Bus 205.
- **API Call:**
  ```bash
  curl -s -X POST "http://localhost:8000/api/tickets/book" \
    -H "Authorization: Bearer <PASSENGER_JWT>" \
    -H "Content-Type: application/json" \
    -d '{
      "bus_number": "205",
      "route_number": "205",
      "origin_stop": "Kaloor Metro Station",
      "destination_stop": "Vyttila Mobility Hub",
      "passenger_name": "Commissioner Demo",
      "fare_amount": 25.0
    }'
  ```
- **Talking Point:** *"Booking generates a cryptographically signed ticket with a dynamic QR code hash and base64 PNG data URI, ready for immediate boarding."*

---

### Step 6: Boarding Pass QR Generation
*Displays the active boarding pass on the commuter's phone.*
- **UI Action:** Commuter opens 'My Tickets' drawer.
- **API Call:**
  ```bash
  curl -s -X GET "http://localhost:8000/api/tickets/my" \
    -H "Authorization: Bearer <PASSENGER_JWT>"
  ```
- **Talking Point:** *"The QR token contains a SHA-256 validation digest. It operates offline on the passenger device once downloaded."*

---

### Step 7: Conductor Cockpit & Atomic QR Validation
*Simulates the conductor scanning the commuter's digital pass.*
- **UI Action:** Conductor app scans the passenger QR pass.
- **API Call:**
  ```bash
  curl -s -X POST "http://localhost:8000/api/tickets/validate" \
    -H "Authorization: Bearer <CONDUCTOR_JWT>" \
    -H "Content-Type: application/json" \
    -d '{
      "qr_code_hash": "<SCANNED_QR_HASH>",
      "bus_number": "205"
    }'
  ```
- **Result:** First scan returns `{"result": "VALID"}` in $< 100\text{ms}$.
- **Talking Point:** *"The validation is atomic. The conductor hears an audible chime confirming a valid ticket."*

---

### Step 8: Double-Spend Prevention Test
*Proves that a used ticket cannot be re-scanned or shared.*
- **Action:** Re-send the exact same validation payload.
- **Result:** Returns `{"result": "ALREADY_USED"}`.
- **Talking Point:** *"Double-spend is physically impossible. Even if a passenger screenshots the QR code to a friend, the second scan is instantly rejected."*

---

### Step 9: Live CCTV Headcount Ingestion & Zero-Biometrics Proof
*Demonstrates real-time occupancy updates from bus CCTV streams.*
- **Action:** Ingest a fresh aggregate headcount packet:
  ```bash
  curl -s -X POST "http://localhost:8000/api/ingest/cctv-occupancy" \
    -H "Authorization: Bearer <AUTHORITY_JWT>" \
    -H "Content-Type: application/json" \
    -d '{
      "bus_number": "205",
      "timestamp": "2026-11-02T13:00:00Z",
      "raw_person_count": 32,
      "stabilized_person_count": 30,
      "capacity": 45,
      "confidence_score": 0.89,
      "model_version": "yolov8n-headcount-v2.1",
      "camera_id": "CAM-KOCHI-205-01",
      "privacy_standard": "PERSON_COUNTING_ONLY_NO_BIOMETRICS",
      "data_origin": "CV REPLAY"
    }'
  ```
- **Talking Point:** *"The camera counts bodies only. The payload validator strictly rejects any packet that does not state 'PERSON_COUNTING_ONLY_NO_BIOMETRICS'. No faces, no tracking IDs."*

---

### Step 10: Multi-Horizon Demand Forecasting Dashboard
*Shows the predictive capability of the platform for dispatchers.*
- **UI Action:** Open Authority Dashboard ➔ Demand Forecasting Tab.
- **API Call:**
  ```bash
  curl -s -X GET "http://localhost:8000/api/predictions" \
    -H "Authorization: Bearer <AUTHORITY_JWT>"
  ```
- **Talking Point:** *"The system forecasts passenger load across four forward horizons: Now, +15 mins, +30 mins, and +60 mins using regularized Ridge Regression. Dispatchers can anticipate surges at Edappally Toll before the bus arrives."*

---

### Step 11: Real-Time Pilot Monitoring & Provider Governance
*Shows the executive pilot telemetry and data origin auditing.*
- **UI Action:** Open Authority Dashboard ➔ Pilot Monitor.
- **API Call:**
  ```bash
  curl -s -X GET "http://localhost:8000/api/ingest/pilot-monitor" \
    -H "Authorization: Bearer <AUTHORITY_JWT>"
  ```
- **Talking Point:** *"The Pilot Monitor shows total active vehicles, data freshness percentage, live versus simulated breakdowns, and active provider feeds. Notice the governance status: 'STAGE 1: PROPOSED PILOT' with zero unapproved mutations."*

---

## 3. Frequently Asked Stakeholder Questions (FAQ)

**Q1: How does BusSense AI protect citizen privacy on CCTV cameras?**  
*A:* BusSense AI uses object detection models strictly fine-tuned for class 'person'. It computes an aggregate head/body count in volatile memory. No video is permanently recorded on cloud servers, and no facial recognition software exists anywhere in the codebase.

**Q2: What happens if a bus enters a cellular dead zone?**  
*A:* The mobile conductor app stores local ticket validation rules and cryptographic public hashes. The system operates in offline validation mode and synchronizes when network connectivity returns.

**Q3: Can the AI change bus schedules automatically without human permission?**  
*A:* No. The platform is architected with strict, immutable Advisory Mode guardrails. All optimizations are recommendations presented on the Authority Command Center for human dispatcher review and approval.

---
*BusSense AI Stakeholder Demonstration Guide — Version 1.0.0-H21*

