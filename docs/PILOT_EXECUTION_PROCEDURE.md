# BusSense AI — Controlled Pilot Execution Procedure
## Operational Framework, Corridor Geography & Human-in-the-Loop Protocol

**Document Version:** 1.0.0-H19  
**Target Operating Region:** Greater Kochi Transit Network, Kerala, India  
**Primary Test Corridor:** Aluva Metro Station ➔ Kalamassery ➔ Edappally Toll ➔ Palarivattom ➔ Kaloor ➔ Kadavanthra ➔ Vyttila Mobility Hub (Route 205 Corridor)  
**Secondary Feeder Corridor:** Fort Kochi Boat Jetty ➔ MG Road North ➔ Kaloor ➔ Palarivattom ➔ Kakkanad Civil Station ➔ Infopark Phase 1 Express Bay (Route 14A Corridor)  
**Operational Status:** **CONTROLLED PILOT READY (PROCEDURE DOCUMENTED & PREPARED; FIELD EXECUTION PENDING TRANSPORT COMMISSIONERATE AUTHORIZATION)**  
**Advisory Guardrail:** Strict Human-in-the-Loop Authority decision hierarchy; **Zero Automatic Dispatch Modifications**.

---

## 1. Pilot Objectives

The controlled field pilot evaluates whether BusSense AI can reliably operate within a real transit environment to:
1. **Estimate bus cabin occupancy** with stabilized MAE $\le 3.0$ passengers using privacy-preserving computer vision headcounts.
2. **Ingest and map-match vehicle GPS telemetry** with latency $< 2.0\text{ seconds}$ and route deviation accuracy $< 100\text{ meters}$.
3. **Forecast short-term passenger demand** (+15, +30, and +60 minutes) outperforming persistence ($y_{t+h} = y_t$) and SMA-3 baselines by $\ge 25\%$.
4. **Recommend less-crowded alternative journeys** to commuters, improving seat availability and passenger comfort.
5. **Support driver and conductor workflows** with high-contrast, one-handed cockpit glanceability and offline-resilient QR ticket validation.
6. **Maintain operational visibility** for transport controllers without fabricating data or replacing missing telemetry with fake live pins.
7. **Preserve strict citizen privacy** with zero facial recognition, zero demographic classification, and zero individual tracking.

---

## 2. Participating Operators & Required Authorizations

| Operator / Entity | Role in Controlled Pilot | Required Authorization / Agreement |
| :--- | :--- | :--- |
| **KSRTC (Kerala State Road Transport Corporation)** | 6 instrumented city buses operating on Route 205 (Aluva–Vyttila) | KSRTC Managing Director / ITS Department MOU |
| **KMRL (Kochi Metro Rail Limited)** | 4 feeder electric buses operating on Route 14A (Fort Kochi–Infopark) | KMRL Multimodal Transport Division Operating Clearance |
| **Motor Vehicles Department (MVD) Kerala** | Regulatory oversight & safety audit | Transport Commissionerate Controlled Pilot Sanction |
| **Kochi City Police / Traffic West & East** | Disruption & road obstruction feed validation | Traffic Police Incident Desk Information Sharing Clearance |
| **Independent Observers (CUSAT / Transport Experts)** | Ground-truth doorway passenger counting | Academic/Observer Ground-Truth Agreement |

---

## 3. Test Corridor Geography & Waypoints

### Primary Corridor: Route 205 (Aluva Metro ➔ Vyttila Mobility Hub)
- **Total Corridor Distance:** 18.2 km  
- **Average Base Journey Duration:** 48 minutes  
- **Key Corridor Waypoints:**
  1. *Aluva Metro Station* (`10.1076°N, 76.3533°E`) — Northern Terminal & Rail Interchange
  2. *En route Kalamassery Premier Junction* (`10.0544°N, 76.3197°E`) — Industrial & Educational Node
  3. *Edappally Toll & Lulu Terminal* (`10.0261°N, 76.3086°E`) — High-Flux Transit Interchange
  4. *Palarivattom Bypass Junction* (`10.0075°N, 76.3115°E`) — Arterial Junction
  5. *Kaloor Metro Station & Bus Stand* (`9.9922°N, 76.2974°E`) — Central Commercial Hub
  6. *En route Kadavanthra Junction* (`9.9780°N, 76.3050°E`) — South-Central Connector
  7. *Vyttila Mobility Hub* (`9.9678°N, 76.3182°E`) — Southern Regional Multimodal Terminal

---

## 4. Test Duration, Phasing & Timeline

The controlled pilot is structured into a rigorous **10-Week Phased Schedule**:

| Pilot Phase | Duration | Core Focus & Operational Gates |
| :--- | :---: | :--- |
| **Phase P1: Pre-Flight & Network Calibration** | Weeks 1–2 | Hardware mounting on 10 buses (6 KSRTC + 4 KMRL); GPS cellular ping verification; edge camera focus calibration; Supabase RLS security verification. |
| **Phase P2: Shadow Telemetry Ingestion** | Weeks 3–4 | Telemetry streaming without commuter app publication; verifying Haversine map-matching, out-of-order packet drops, and speed filter limits ($v \le 120\text{ km/h}$). |
| **Phase P3: Ground-Truth CV Occupancy Audit** | Weeks 5–6 | Independent dual-observer manual doorway tallies synchronized with edge camera timestamps; validating MAE $\le 3.0$ across daylight, evening low light, glare, and rush-hour occlusion. |
| **Phase P4: Controlled Commuter Trial** | Weeks 7–9 | Pilot app distribution to 150 registered daily commuters; tracking recommendation compliance, waiting-time deltas, and seat comfort. |
| **Phase P5: Pilot Evaluation & Governance Review** | Week 10 | Independent pilot evaluation report generation against the 7 measurable metrics; Authority Commission decision on network expansion. |

---

## 5. Responsible Personnel & Duty Hierarchy

```
┌────────────────────────────────────────────────────────┐
│           PILOT STEERING COMMITTEE (CHAIR)             │
│        Transport Commissionerate / KSRTC Director      │
└──────────────────────────┬─────────────────────────────┘
                           │
             ┌─────────────┴─────────────┐
             ▼                           ▼
┌─────────────────────────┐ ┌─────────────────────────┐
│  OPERATIONAL CONTROLLER │ │   LEAD ML / CV AUDITOR  │
│  (Duty Authority Desk)  │ │ (Model & Data Governance)│
└────────────┬────────────┘ └────────────┬────────────┘
             │                           │
             ▼                           ▼
┌─────────────────────────┐ ┌─────────────────────────┐
│ ON-VEHICLE CREW         │ │ INDEPENDENT OBSERVERS   │
│ (Driver / Conductor)    │ │ (Manual Doorway Tallies)│
└─────────────────────────┘ └─────────────────────────┘
```

1. **Pilot Operational Controller:** Authority duty officer with override powers. Responsible for reviewing dispatch recommendations, verifying disruption alerts, and managing provider keys.
2. **Lead ML / Data Governance Auditor:** Verifies zero-biometrics compliance, evaluates model residual distributions, and verifies that no synthetic data is labeled as live telemetry.
3. **Onboard Conductor:** Validates commuter QR passes using the Conductor Cockpit, inputs manual stop progress if GPS stalls, and reports road hazards.
4. **Independent Observers:** Pair of tally-clicker observers stationed at front and rear doorways recording ground-truth boarding and alighting counts.

---

## 6. Measurable Pilot Success & Failure Criteria

### 6.1 Pilot Success Criteria (Go-Decision for Phase 2 Rollout)
1. **CV Occupancy Accuracy:** Overall smoothed MAE $\le 2.5$ passengers; RMSE $\le 3.5$ passengers across the 6 field scenarios.
2. **Zero Biometrics Verification:** 100% compliance rate; zero facial images, biometric points, or commuter tracking IDs in database or logs.
3. **GPS Freshness & Map-Matching:** $\ge 95\%$ of vehicle GPS fixes successfully map-matched to corridor waypoints with telemetry age $< 15\text{ seconds}$.
4. **Forecaster Value Over Baseline:** $\ge 30\%$ error reduction (MAE) over persistence baseline ($y_{t+h} = y_t$) across +15m and +30m horizons.
5. **Commuter Usefulness:** $\ge 65\%$ commuter compliance rate choosing the recommended bus; documented average waiting-time reduction of $\ge 3.0\text{ minutes}$.
6. **Platform Reliability:** API uptime $\ge 99.5\%$ with P95 response latency $< 50\text{ ms}$ for recommendation and live map queries.

### 6.2 Pilot Failure Criteria (Mandatory Pause & Triage)
1. **Any Biometric Data Transmission:** If any edge camera transmits face cropped images or biometric features, the pilot is **immediately suspended**.
2. **Severe GPS Inaccuracy:** Off-route false alarm rate $> 20\%$ due to poor map-matching algorithms.
3. **Ghost Bus Occurrences:** More than 2 incidents where commuter applications display vehicles that are out-of-service or over 5 minutes delayed without a `STALE DATA` or `UNAVAILABLE` badge.
4. **Conductor Workflow Impedance:** QR boarding pass validation taking $> 3.0\text{ seconds}$ per passenger, causing doorway boarding congestion.

---

## 7. Incident Handling & Emergency Fallback Procedures

1. **Edge Camera Unit Failure:**
   - Ingestion service detects camera packet dropout ($> 60\text{ seconds}$).
   - Fleet state occupancy automatically switches to historical demand prediction (`PREDICTION` badge).
   - Conductor cockpit is prompted to provide optional 1-tap crowd tier input (`LOW`, `MODERATE`, `CROWDED`).
2. **Cellular AVL Signal Dropout (Underpasses / Heavy Rain):**
   - Telemetry age $> 30\text{s}$: Stamped `STALE DATA`.
   - Telemetry age $> 120\text{s}$: Stamped `UNAVAILABLE`; vehicle pin suppressed from live commuter map.
   - When connection resumes, `SIGNAL_RECOVERY` event is audited; previous monotonic sequence is resumed.
3. **Road Disruption / Waterlogging Event:**
   - Incident is posted via `/api/ingest/disruptions`.
   - Authority controller validates severity; system broadcasts warning to commuters traveling on affected corridor.
   - Travel times on corridor segment are updated with estimated delay minutes.

---

## 8. Strict Human-in-the-Loop Operational Guardrail

- **Advisory Mode Is Mandatory (`advisory_mode_enforced = True`):**
  - AI transit intelligence generates recommendations, demand predictions, and fleet balancing suggestions.
  - **No automated schedule mutation:** The platform never modifies official bus departure times, re-routes active vehicles, or reassigns drivers autonomously.
  - All operational actions require explicit, authenticated human approval by a certified Authority Controller in the Command Center.
