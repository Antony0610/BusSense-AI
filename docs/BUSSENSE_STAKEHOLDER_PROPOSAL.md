# BusSense AI — Stakeholder Proposal
## Climate-Smart Public Bus Intelligence Platform for Greater Kochi

**Target Agencies:** Transport Commissionerate (Govt of Kerala), Kerala State Road Transport Corporation (KSRTC / KSRTC-SWIFT), Kochi Metro Rail Limited (KMRL), Greater Cochin Development Authority (GCDA)  
**Document Version:** 1.0.0-H21  
**Classification:** Strategic Policy & Institutional Proposal  
**Current Lifecycle Stage:** `STAGE 1: PROPOSED PILOT` (Advisory / Controlled Demonstration Mode)  
**Core Operating Principle:** `SEE → SENSE → PREDICT → RECOMMEND → OPTIMIZE`

---

## 1. Executive Summary

Public bus transit is the backbone of Greater Kochi's mobility network, yet it faces chronic operational friction:
1. **Unpredictable Cabin Crowding:** Commuters face unpredictable passenger surges, leading to overcrowding on peak services and stranded passengers at intermediate stops like Kalamassery, Palarivattom, and Edappally.
2. **Sub-optimal Headway Balancing:** Buses frequently experience route bunching along high-density corridors (Aluva–MG Road–Vyttila), causing long passenger wait times followed by platoons of half-empty buses.
3. **Data Silos & Visibility Deficits:** Transit authorities lack real-time visibility into onboard passenger loads, vehicle positions, and short-term corridor demand fluctuations.

**BusSense AI** is an intelligent, privacy-first transit orchestration platform designed specifically for Kerala's public transit ecosystem. By harmonizing existing automated vehicle location (AVL) GPS feeds, privacy-preserving computer vision headcounts from onboard CCTV cameras, and multi-horizon demand forecasting, BusSense AI delivers:
- **Actionable Commuter Guidance:** Real-time crowd forecasts and explainable route alternatives that reduce waiting time and smooth passenger load across services.
- **Conductor & Driver Empowerment:** Rapid digital boarding pass verification and real-time cabin load telemetry.
- **Authority Fleet Orchestration:** Evidence-based headway regulation, congestion mitigation, and climate-smart scheduling without expensive hardware retrofits.

---

## 2. Strategic Objectives & Value Proposition

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│       SEE       │  ──▶  │      SENSE      │  ──▶  │     PREDICT     │
│ CCTV Headcounts │       │ GPS Map-Match   │       │ Multi-Horizon   │
│ Zero Biometrics │       │ Freshness Gate  │       │ Ridge Model     │
└─────────────────┘       └─────────────────┘       └─────────────────┘
                                                             │
                                                             ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│    OPTIMIZE     │  ◀──  │    RECOMMEND    │  ◀───────┘                 │
│ Headway Balance │       │ Explainable UI  │                         │
│ Diesel Savings  │       │ Advisory Mode   │                         │
└─────────────────┘       └─────────────────┘                         
```

### 2.1 For Transit Operators (KSRTC & KMRL)
- **12–18% Projected Ridership Growth:** Predictable travel and crowd visibility attract choice riders who currently avoid buses due to crowding uncertainty.
- **Fuel and Emissions Efficiency:** Dynamic headway balancing reduces bus bunching and unnecessary idle dwell times, reducing fleet diesel consumption and carbon emissions.
- **Intermodal Metro Integration:** Seamlessly feeds KMRL metro stations (Aluva, Edappally, Kaloor, MG Road, Vyttila) with coordinated feeder schedules and unified ticketing interfaces.

### 2.2 For Commuters & Citizens
- **Pre-trip Crowd Awareness:** See exact passenger load tiers (`LOW < 50%`, `MODERATE 50–80%`, `CROWDED > 80%`) before leaving home.
- **Explainable Smart Recommendations:** Transparent journey choices balancing travel time, fare, and cabin comfort.
- **Frictionless Boarding:** Sub-second digital QR boarding pass generation and offline-capable ticket verification.

### 2.3 For Transport Regulators & Urban Planners
- **Live Fleet Command Center:** Real-time spatial tracking of all corridor vehicles with map-matching and off-route deviation alerting.
- **Auditable Data Provenance:** Every metric carries clear truth labels (`LIVE DATA`, `SIMULATED DATA`, `CV REPLAY`, `PREDICTION`, `ESTIMATE`), preventing unverified data from influencing policy decisions.
- **Zero New Expensive Hardware:** Operates on existing standard IP CCTV cameras, low-cost GPS trackers, and standard Android/iOS smartphones.

---

## 3. Strict Non-Negotiable Safeguards

### 3.1 Zero Biometrics Privacy Guarantee
- **Person Counting Only:** Onboard CCTV processing uses bounding-box person detection (`PERSON_COUNTING_ONLY_NO_BIOMETRICS`).
- **No Facial Recognition:** The computer vision pipeline strictly omits facial landmark detection, biometric feature extraction, demographic profiling, or individual passenger tracking.
- **Edge Discard:** Video streams are analyzed in volatile memory or local edge gateways; raw video is never transmitted to cloud storage or long-term databases.

### 3.2 Immutability of Advisory Mode
- All system dispatch, headway, and rerouting suggestions operate strictly in **Advisory Mode** (`advisory_mode_enforced = True`).
- No algorithmic model has the technical permission or network access to alter bus schedules, cancel services, or reassign drivers without explicit human dispatcher authorization.

### 3.3 Data Sovereignty & Security
- Cloud databases operate under strict PostgreSQL Row-Level Security (RLS) policies.
- External transit feeds are secured via SHA-256 hashed API keys with sliding-window rate limiting.
- System complies with India's Digital Personal Data Protection Act (DPDPA 2023) and Kerala state IT governance frameworks.

---

## 4. Controlled Pilot Proposal: Greater Kochi

We propose a **10-Week Controlled Field Pilot** across two vital Greater Kochi corridors:

| Corridor | Identifier | Route Span | Fleet Size | Key Transit Hubs Connected |
| :--- | :---: | :---: | :---: | :--- |
| **Aluva – Vyttila Corridor** | Route 205 | 24 km | 6 Buses | Aluva Metro, Kalamassery, CUSAT, Edappally, Palarivattom, Kaloor, Vyttila Mobility Hub |
| **Fort Kochi – Infopark Corridor** | Route 14A | 28 km | 4 Buses | Fort Kochi, Menaka, MG Road, Kaloor, Kakkanad Civil Station, Infopark Phase 1 |

### Pilot Timeline & Phasing

```
Week 1 - 2: Onboarding & Calibration
  ├── Bilateral Data Agreement & SHA-256 API Key Issuance
  └── GPS map-matching polygon and stop sequence calibration

Week 3 - 4: Conductor Pilot & Baseline Capture
  ├── Conductor cockpit app deployment on standard POS/phones
  └── Passive telemetry gathering (unannounced baseline)

Week 5 - 8: Commuter Pilot & Dynamic Recommendations
  ├── Controlled passenger beta app rollout (1,000 active users)
  └── Live crowd visibility and journey advice activation

Week 9 - 10: Evaluation, Audit & Transition
  ├── Statistical evaluation against pilot KPIs (MAE, Freshness, Adoption)
  └── Joint presentation to Transport Commissionerate & KSRTC Board
```

---

## 5. Success Metrics & Verification Standards

| Dimension | Pilot Benchmark KPI | Target Threshold | Verification Mechanism |
| :--- | :--- | :---: | :--- |
| **Passenger Counting** | Smoothed Mean Absolute Error (MAE) | $\le 2.0$ persons | Ground-truth video replay benchmarking |
| **Counting Stability** | Temporal variance / jitter | $\le 8.0\%$ MAPE | Exponential Moving Average (EMA) verification |
| **GPS Map-Matching** | Accurate corridor stop snapping | $\ge 98.0\%$ | Automated Haversine distance bounds ($<500\text{m}$) |
| **Data Freshness** | Fleet telemetry latency | $\ge 95.0\%$ within 30s | Live Pilot Monitor telemetry audit |
| **Commuter Adoption** | Recommendation compliance rate | $\ge 60.0\%$ | Commuter impression/selection event logging |
| **Conductor Flow** | Ticket validation speed | $< 2.5$ seconds | Atomic QR hash lookup benchmark |
| **System Uptime** | API availability | $\ge 99.5\%$ | Prometheus/Nginx operational monitoring |

---

## 6. Institutional Call to Action

To activate the Controlled Field Pilot, we respectfully request the Transport Commissionerate and KSRTC leadership to:
1. **Authorize Stage 2 (APPROVED PILOT):** Issue formal institutional approval for a 10-bus evaluation on Route 205 and Route 14A.
2. **Designate Technical Liaisons:** Appoint one ITS officer from KSRTC and one systems engineer from KMRL to coordinate feed integration.
3. **Grant Telemetry Read Access:** Authorize read-only AVL GPS API access for the 10 participating test vehicles.

BusSense AI stands ready to provide technical installation, conductor training, and continuous operational oversight at zero financial obligation to the transit agency during the pilot phase.

---
*Submitted by the BusSense AI Engineering & Systems Validation Team.*  
*Repository: https://github.com/Antony0610/BusSense-AI.git*

