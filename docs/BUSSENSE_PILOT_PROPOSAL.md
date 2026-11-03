# BusSense AI — Controlled Pilot Proposal
## Operational Execution Plan for Greater Kochi Transit Pilot

**Target Organizations:** Transport Commissionerate Kerala, KSRTC-SWIFT Management, Kochi Metro Rail Ltd (KMRL)  
**Document Version:** 1.0.0-H21  
**Target Duration:** 10 Weeks  
**Vehicle Scope:** 10 Selected Public Transit Buses (6 on Route 205, 4 on Route 14A)  
**Lifecycle Stage:** `STAGE 1: PROPOSED PILOT` (Advancement to Stage 2 upon bilateral sign-off)

---

## 1. Pilot Scope & Operating Corridors

The pilot focuses on two high-volume transit corridors in Greater Kochi that exhibit high passenger variance and direct metro multimodal connectivity:

```
               ROUTE 205: ALUVA METRO ➔ VYTTILA MOBILITY HUB (24 KM)
[Aluva Metro] ──▶ [Kalamassery] ──▶ [Edappally Toll] ──▶ [Palarivattom] ──▶ [Kaloor] ──▶ [Vyttila Hub]
      │                                     │                              │              │
   (KMRL L1)                             (KMRL L1)                      (KMRL L1)      (KMRL / Water)

             ROUTE 14A: FORT KOCHI ➔ INFOPARK PHASE 1 (28 KM)
[Fort Kochi] ──▶ [Menaka / Jetty] ──▶ [MG Road] ──▶ [Kaloor] ──▶ [Kakkanad] ──▶ [Infopark Phase 1]
      │                 │                  │            │            │                 │
 (Heritage)       (Water Metro)        (KMRL L1)    (KMRL L1)   (Civil Station)   (IT Hub)
```

### 1.1 Participating Vehicle Roster
| Bus Identifier | Route | Depot | Fleet Type | Installed Hardware |
| :--- | :---: | :---: | :---: | :--- |
| `KL-15-A-2051` | Route 205 | Aluva Depot | KSRTC-SWIFT Fast Passenger | Standard IP Door Camera + AIS-140 GPS |
| `KL-15-A-2052` | Route 205 | Aluva Depot | KSRTC-SWIFT Fast Passenger | Standard IP Door Camera + AIS-140 GPS |
| `KL-15-A-2053` | Route 205 | Aluva Depot | KSRTC-SWIFT Fast Passenger | Standard IP Door Camera + AIS-140 GPS |
| `KL-15-A-2054` | Route 205 | Aluva Depot | KSRTC-SWIFT Fast Passenger | Standard IP Door Camera + AIS-140 GPS |
| `KL-15-A-2055` | Route 205 | Aluva Depot | KSRTC-SWIFT Fast Passenger | Standard IP Door Camera + AIS-140 GPS |
| `KL-15-A-2056` | Route 205 | Aluva Depot | KSRTC-SWIFT Fast Passenger | Standard IP Door Camera + AIS-140 GPS |
| `KL-15-B-1401` | Route 14A | Ernakulam Depot | City Feeder Bus | Standard IP Door Camera + AIS-140 GPS |
| `KL-15-B-1402` | Route 14A | Ernakulam Depot | City Feeder Bus | Standard IP Door Camera + AIS-140 GPS |
| `KL-15-B-1403` | Route 14A | Ernakulam Depot | City Feeder Bus | Standard IP Door Camera + AIS-140 GPS |
| `KL-15-B-1404` | Route 14A | Ernakulam Depot | City Feeder Bus | Standard IP Door Camera + AIS-140 GPS |

---

## 2. 10-Week Pilot Schedule & Phased Milestones

```
WEEKS 1 - 2: Onboarding & Hardware Calibration
  ├── Phase 1.1: Bilateral Data Sharing MOU & Stage 2 (APPROVED PILOT) Authorization
  ├── Phase 1.2: SHA-256 API Key provisioning for KSRTC AVL feed (X-Provider-API-Key)
  └── Phase 1.3: CCTV doorway field-of-view alignment and video resolution calibration

WEEKS 3 - 4: Conductor Pilot & Passive Baseline Collection
  ├── Phase 2.1: Conductor cockpit rollout on 10 Android handheld POS devices
  ├── Phase 2.2: 1-hour depot training sessions for 20 designated conductors and starters
  └── Phase 2.3: Unannounced passive telemetry collection to establish baseline metrics

WEEKS 5 - 8: Commuter Pilot & Dynamic Optimization
  ├── Phase 3.1: Release of BusSense Passenger mobile app to 1,000 registered beta commuters
  ├── Phase 3.2: Enable live crowd status (LOW, MODERATE, CROWDED) in mobile UI
  ├── Phase 3.3: Activate explainable journey recommendations and headway advisories
  └── Phase 3.4: Weekly telemetry freshness, GPS map-matching, and CV accuracy audits

WEEKS 9 - 10: Statistical Evaluation & Institutional Transition
  ├── Phase 4.1: Compute formal performance metrics across all 7 evaluation dimensions
  ├── Phase 4.2: Conduct qualitative surveys with conductors, drivers, and commuters
  └── Phase 4.3: Present Final Pilot Report to Transport Commissionerate and KSRTC Board
```

---

## 3. Governance Lifecycle & Guardrails

The pilot strictly enforces the 5-stage lifecycle state machine defined in `docs/PILOT_EXECUTION_PROCEDURE.md`:

```
┌─────────────────────┐
│  1. PROPOSED PILOT  │ ◀── CURRENT SYSTEM STATUS (Advisory & Simulation Mode)
└──────────┬──────────┘
           │ Formal bilateral MOU & API key authorization
           ▼
┌─────────────────────┐
│  2. APPROVED PILOT  │ ── Technical integration authorized; credentials issued
└──────────┬──────────┘
           │ Hardware checks passed; crew trained; test calendar fixed
           ▼
┌─────────────────────┐
│ 3. SCHEDULED PILOT  │ ── Pilot launch date and corridors finalized
└──────────┬──────────┘
           │ Live revenue service data stream activated
           ▼
┌─────────────────────┐
│   4. ACTIVE PILOT   │ ── Live operations running under continuous monitoring
└──────────┬──────────┘
           │ 10-week evaluation window completed
           ▼
┌─────────────────────┐
│ 5. COMPLETED PILOT  │ ── Statistical audit published; expansion review
└─────────────────────┘
```

### Safety and Operational Guardrails
1. **Advisory Mode Immutability:** The platform does NOT issue automated dispatch cancellations or route reassignments. Recommendations appear exclusively on authority dashboards for human supervisor action.
2. **Conductor Independence:** Conductors retain full discretion to accept paper tickets and cash fares at all times. Digital validation is additive and never blocks passenger boarding.
3. **Emergency Rollback Protocol:** If system latency exceeds 10 seconds or false crowd warnings trigger commuter complaints, the pilot monitor can revert to `FALLBACK_PASSIVE_MODE` within 60 seconds via `POST /api/ingest/providers/revoke`.

---

## 4. Key Performance Indicators (KPIs) & Evaluation Criteria

| Category | Indicator | Target Threshold | Measuring Instrument |
| :--- | :--- | :---: | :--- |
| **CV Accuracy** | Headcount Mean Absolute Error | $\text{MAE} \le 2.0$ passengers | 100-frame annotated manual audit samples |
| **CV Safety** | Biometric tracking compliance | $100\%$ Zero Biometrics | Automated regex and schema payload audit |
| **GPS Tracking** | Map-matching snap precision | $\ge 98.0\%$ on corridor | Haversine distance offset $<500\text{m}$ |
| **Data Quality** | Telemetry freshness ratio | $\ge 95.0\%$ within 30s | Live Pilot Monitor dashboard calculation |
| **Forecasting** | 30-minute demand accuracy | $\text{MAE} \le 6.5\%$ | Historical validation set residual comparison |
| **Commuter UX** | Recommendation adoption | $\ge 60.0\%$ selection rate | In-app impression vs booking analytics |
| **Operations** | Conductor scan time | $< 2.5\text{s}$ per passenger | Handheld POS timestamp delta logging |
| **System** | API availability & uptime | $\ge 99.5\%$ | Prometheus / Nginx access log analysis |

---

## 5. Roles and Responsibilities Matrix

| Stakeholder Entity | Key Responsibilities | Designated Personnel |
| :--- | :--- | :--- |
| **Transport Commissionerate** | Regulatory oversight, pilot sanction, inter-agency coordination | Joint Transport Commissioner (ITS) |
| **KSRTC / SWIFT** | Bus allocation (10 units), conductor scheduling, depot coordination | Aluva & Ernakulam Depot Starters |
| **KMRL** | Metro interchange signage, feeder schedule synchronization | Multimodal Integration Lead |
| **BusSense AI Engineering** | Backend uptime, CV optimization, mobile app maintenance, analytics | Technical Lead & Systems Architect |
| **Bus Conductors (20 crew)** | Handheld POS operation, digital boarding pass validation, feedback | Assigned Duty Conductors |

---
*BusSense AI Controlled Field Pilot Plan — Greater Kochi Corridors*

