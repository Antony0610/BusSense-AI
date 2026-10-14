# BusSense AI — Phase H10 Report
## Smart Bus Recommendation Engine

**Phase Status:** COMPLETED  
**Classification:** IMPLEMENTED / RECOMMENDATION  
**Regression Status:** ZERO REGRESSION (Flutter: 96/96 passed, 0 analyze issues; Backend: 121/121 passed, 1 skipped; Authority: 22/22 routes compiled, 19/19 frontend tests passed)  
**Date:** October 2026  

---

## 1. Executive Summary

Phase H10 completes the journey intelligence loop of BusSense AI by elevating transit data from **"What is the crowd now and next?"** to **"Which bus is the most suitable option for this journey?"**:

$$\text{ORIGIN} + \text{DESTINATION} \longrightarrow \text{CORRIDOR CANDIDATES} \longrightarrow \begin{pmatrix} \text{ETA} \\ \text{LIVE OCCUPANCY} \\ \text{H9 PREDICTED OCCUPANCY} \\ \text{JOURNEY DURATION} \\ \text{TRANSIT FARE} \\ \text{BUS LANE ADVANTAGE} \end{pmatrix} \longrightarrow \text{MULTI-FACTOR SCORING} \longrightarrow \text{RANKED OPTIONS} \longrightarrow \begin{pmatrix} \text{RECOMMENDED BUS} \\ \text{ALTERNATIVES} \\ \text{DETERMINISTIC EXPLANATION} \end{pmatrix}$$

**Core Operating Principles:**
1. **Multi-Factor Balance:** No single factor automatically wins. A bus arriving 2 minutes earlier will not win if it is packed to capacity; a near-empty bus will not win if it requires a protracted delay.
2. **H9 Prediction as a First-Class Input:** The recommendation engine incorporates dynamic $+15\text{m}$, $+30\text{m}$, or $+60\text{m}$ Ridge demand forecasts evaluated around the anticipated journey duration.
3. **Strict Elimination of Hardcoded Winners:** Zero static preferences or hardcoded rules favor Bus 205. The recommendation dynamically shifts when live occupancy, ETA, predictions, or destinations change.
4. **Honest Truth Labeling:** Recommendations are explicitly stamped with `RECOMMENDATION`, live inputs with `LIVE DATA` or `CV REPLAY`, and forecasts with `PREDICTION`.

---

## 2. Classification Matrix

| Component | Status | Classification | Details |
|:---|:---:|:---:|:---|
| **Candidate Retrieval Engine** | Verified | **IMPLEMENTED** | Direction-aware sequence matching across Greater Kochi transit corridors (Routes 205, 14A, 12). |
| **Multi-Factor Scoring Engine** | Verified | **IMPLEMENTED** | Configurable scoring balancing ETA, current crowd, H9 predicted crowd, duration, fare, and reliability. |
| **H9 Prediction Integration** | Verified | **IMPLEMENTED** | Horizon-selection logic ($+15\text{m}$ for $\le 20\text{m}$, $+30\text{m}$ for $\le 45\text{m}$, $+60\text{m}$ for $> 45\text{m}$) with confidence blending. |
| **Confidence Weighting** | Verified | **IMPLEMENTED** | Low prediction confidence dynamically discounts the forecast component: $s_{\text{pred}} = c \cdot s_{\text{pred, raw}} + (1 - c) \cdot s_{\text{crowd}}$. |
| **Preference Modes** | Verified | **IMPLEMENTED** | Server-validated modes: `balanced` (default), `fastest`, `least_crowded`, `lowest_fare`. |
| **Data Quality Rating** | Verified | **IMPLEMENTED** | Transparent three-tier rating: `HIGH` (CV replay + high confidence), `MEDIUM` (simulated telemetry), `LOW` (unmonitored). |
| **Deterministic Explanation Engine** | Verified | **IMPLEMENTED** | Template-driven, data-grounded rationale generation without external LLM dependencies or false certainty claims. |
| **Alternative Options & Deltas** | Verified | **IMPLEMENTED** | Generates alternative buses with comparative deltas (`crowd_saving_vs_alternative_pct`, `time_saving_mins`). |
| **FastAPI Recommendations API** | Verified | **IMPLEMENTED** | `GET /api/recommendations/plan`, `POST /api/recommendations/plan`, `GET /api/recommendations/preferences`. |
| **Passenger Mobile Integration** | Verified | **INTEGRATED** | Compatible with Flutter Explore, Route Planning, Smart Recommendation, and Bus Details models. |
| **Authority Portal Integration** | Verified | **INTEGRATED** | Compatible with Next.js AI Operations, Diagnostic breakdowns, and 4-tier decision hierarchy. |
| **Autonomous Dispatch** | Prohibited | **DEFERRED** | Preserves human-in-the-loop: `LIVE DATA` ➔ `PREDICTION` ➔ `RECOMMENDATION` ➔ `HUMAN DECISION`. |

---

## 3. Architecture & Data Flow

The recommendation engine is located in `backend/app/services/recommendation_engine.py` and exposed via `backend/app/api/recommendations.py`:

```
backend/
├── app/
│   ├── services/
│   │   ├── recommendation_engine.py   # Candidate selection, multi-factor scoring, explanations
│   │   ├── demand_forecaster.py       # H9 Ridge regression forecasts (+15m, +30m, +60m)
│   │   ├── cv_occupancy.py            # H8 Computer Vision YOLOv8 replay occupancy
│   │   └── gps_simulator.py           # Real-time fleet telemetry, waypoint interpolation, ETAs
│   ├── schemas/
│   │   └── prediction.py              # JourneyPlanRequest, JourneyPlanResponse, BusRecommendationItem
│   └── api/
│       └── recommendations.py         # GET/POST /api/recommendations/plan, GET /api/recommendations/preferences
└── tests/
    └── test_recommendation_h10.py     # 27 comprehensive tests (24 specification tests + edge cases + latency)
```

### Recommendation Data Flow Diagram

```mermaid
flowchart TD
    A[Passenger Origin & Destination] --> B[Candidate Stop Sequence Matching<br/>CORRIDOR_METADATA & Direction Validity]
    B --> C[Active Candidate Buses]
    
    D[Live Telemetry<br/>gps_simulator.get_bus_telemetry] --> E[Live Features: ETA, Occupancy %, Crowd Level]
    F[H9 Demand Forecaster<br/>demand_forecaster.get_detailed_forecast] --> G[Prediction Features: +15m, +30m, +60m, Confidence]
    
    C --> H[Candidate Evaluation Pipeline]
    E --> H
    G --> H
    
    H --> I[Horizon Selection Logic<br/>Short <= 20m: +15m | Medium <= 45m: +30m | Long > 45m: +60m]
    I --> J[Factor Normalization 0.0 to 1.0<br/>s_eta, s_crowd, s_pred, s_time, s_fare]
    J --> K[Confidence Blending<br/>Discount prediction when confidence is low]
    K --> L[Preference-Weighted Scoring<br/>balanced, fastest, least_crowded, lowest_fare]
    L --> M[Deterministic Tie-Breaking & Ranking<br/>Score -> -ETA -> -Occupancy]
    
    M --> N[Deterministic Explanation Generator<br/>Data-grounded templates, zero LLM hallucinations]
    M --> O[Alternative Delta Calculation<br/>crowd_saving_pct, time_saving_mins]
    
    N --> P[FastAPI Response: JourneyPlanResponse]
    O --> P
    
    P --> Q[Flutter Mobile App<br/>Explore, Route Planning, Smart Recommendation]
    P --> R[Authority Command Center<br/>AI Operations Decision Queue & Diagnostics]
```

---

## 4. Multi-Factor Scoring & Mathematical Formulation

### 4.1 Normalized Factor Components

Every factor is bounded strictly between $[0.0, 1.0]$ where $1.0$ represents the optimal operational state:

1. **ETA Component ($s_{\text{eta}}$):**
   $$s_{\text{eta}} = \max\left(0.10, \min\left(1.0, 1.0 - \frac{\text{ETA}_{\text{mins}}}{30.0}\right)\right)$$
   A bus arriving in $\le 1$ minute scores $\approx 0.97$; arrival in 15 minutes scores $0.50$; arrival $\ge 30$ minutes scores $0.10$.

2. **Current Crowd Component ($s_{\text{crowd}}$):**
   $$s_{\text{crowd}} = \max\left(0.0, \min\left(1.0, \frac{100.0 - \text{Occ}_{\text{current}}}{100.0}\right)\right)$$
   An empty cabin scores $1.0$; an 80% crowded cabin scores $0.20$; a 100% full cabin scores $0.0$.

3. **Predicted Crowd Component ($s_{\text{pred}}$):**
   $$s_{\text{pred, raw}} = \max\left(0.0, \min\left(1.0, \frac{100.0 - \text{Occ}_{\text{predicted}}}{100.0}\right)\right)$$
   $$s_{\text{pred}} = \left(c \cdot s_{\text{pred, raw}}\right) + \left((1.0 - c) \cdot s_{\text{crowd}}\right)$$
   where $c \in [0.10, 1.0]$ is the H9 model prediction confidence. If prediction confidence drops (e.g., $c = 0.35$ under sparse historical data), the influence of the prediction is discounted towards current observed crowd.

4. **Journey Duration Component ($s_{\text{time}}$):**
   $$\text{EffDuration} = \max\left(5.0, \text{Duration}_{\text{base}} - \text{PriorityBonus}\right)$$
   $$s_{\text{time}} = \max\left(0.10, \min\left(1.0, 1.0 - \frac{\text{EffDuration}}{60.0}\right)\right)$$
   Buses utilizing dedicated bus lanes (e.g., Route 205 on Banerji Road) receive an 8-minute corridor advantage.

5. **Fare Component ($s_{\text{fare}}$):**
   $$s_{\text{fare}} = \max\left(0.10, \min\left(1.0, 1.0 - \frac{\text{Fare}_{\text{INR}}}{40.0}\right)\right)$$

6. **Corridor Reliability Adjustment ($r$):**
   $$r = 1.03 \text{ if priority lane else } 1.00$$

### 4.2 Preference Weight Vectors

| Factor | Balanced (Default) | Fastest | Least Crowded | Lowest Fare |
|:---|:---:|:---:|:---:|:---:|
| $w_{\text{eta}}$ | $0.25$ | **$0.45$** | $0.15$ | $0.15$ |
| $w_{\text{crowd}}$ | $0.25$ | $0.10$ | **$0.40$** | $0.15$ |
| $w_{\text{pred}}$ | $0.20$ | $0.10$ | **$0.30$** | $0.10$ |
| $w_{\text{time}}$ | $0.15$ | **$0.25$** | $0.10$ | $0.10$ |
| $w_{\text{fare}}$ | $0.15$ | $0.10$ | $0.05$ | **$0.50$** |
| **Sum** | **$1.00$** | **$1.00$** | **$1.00$** | **$1.00$** |

### 4.3 Composite Score & Clamping

$$\text{RawScore} = \left(w_{\text{eta}} s_{\text{eta}} + w_{\text{crowd}} s_{\text{crowd}} + w_{\text{pred}} s_{\text{pred}} + w_{\text{time}} s_{\text{time}} + w_{\text{fare}} s_{\text{fare}}\right) \times r$$
$$\text{JourneyScore} = \text{round}\left(\max\left(0.0, \min\left(100.0, \text{RawScore} \times 100.0\right)\right), 1\right)$$

---

## 5. Elimination of Hardcoded Winners

A critical mandate of Phase H10 is the **complete absence of static preferences or hardcoding for Bus 205**.

### Verification Matrix:

| Test Scenario | Bus 205 State | Alternative Bus State | Result Winner | Rationale |
|:---|:---|:---|:---:|:---|
| **High Occupancy** | $96\%$ occupied, ETA 12m | Bus 14A ($25\%$ occupied, ETA 4m) | **Bus 14A** | Lower crowd & earlier arrival easily overpower Bus 205. |
| **Fastest Mode** | ETA 18m, 45m journey | Bus 12 (ETA 2m, 32m journey) | **Bus 12** | Bus 12 provides immediate pickup and faster arrival. |
| **Corridor Switch** | Origin: Fort Kochi, Dest: Infopark | Bus 14A, Bus 12 | **Bus 14A / 12** | Bus 205 is not a direct candidate for Fort Kochi ➔ Infopark. |
| **Dynamic Flip** | Occupancy increases from $30\%$ to $85\%$ | Bus 12 occupancy at $22\%$ | **Bus 12** | Recommendation shifts dynamically in response to telemetry updates. |

---

## 6. Deterministic Explanation Engine

Explanations are strictly grounded in data deltas and generated via deterministic logic without external LLM calls or marketing hyperbole:

- **Balanced Winner:**
  > *"We recommend Bus 12 for the best overall balance of arrival timing, cabin crowding, and journey duration."*
- **Crowd Advantage:**
  > *"Bus 14A arrives 3 minutes later than Bus 205, but is expected to be significantly less crowded (25% vs 96%)."*
- **Fastest Advantage:**
  > *"Bus 14A offers the quickest journey time, arriving in 2 minutes via express routing."*
- **Low-Data Transparency:**
  > *"Limited historical crowd telemetry available for this corridor; recommendation is primarily weighted by arrival ETA and distance."*

All explanations adhere to strict honesty guidelines: using *"is expected to be"* rather than claiming certainty (*"will definitely be"*).

---

## 7. Data Quality Rating

Every recommendation transparently declares its underlying data quality rating:

$$\text{Data Quality} = \begin{cases} 
\text{HIGH} & \text{if Live CV Replay telemetry is active and prediction confidence } \ge 0.75 \\
\text{MEDIUM} & \text{if Live GPS simulation telemetry is active with standard predictions} \\
\text{LOW} & \text{if unmonitored bus or status is LOW\_DATA}
\end{cases}$$

---

## 8. Test Suite Verification (24-Point Specification)

The test suite in `backend/tests/test_recommendation_h10.py` explicitly covers all 24 requirements from the controlled specification, plus edge cases and latency benchmarking:

```powershell
============================= test session starts =============================
platform win32 -- Python 3.14.6, pytest-9.1.1, pluggy-1.6.0
rootdir: D:\Bus_Sense_Ai\backend
collected 27 items

tests/test_recommendation_h10.py::test_01_candidate_bus_retrieval PASSED        [  3%]
tests/test_recommendation_h10.py::test_02_destination_filtering PASSED          [  7%]
tests/test_recommendation_h10.py::test_03_balanced_preference PASSED            [ 11%]
tests/test_recommendation_h10.py::test_04_fastest_preference PASSED             [ 14%]
tests/test_recommendation_h10.py::test_05_least_crowded_preference PASSED        [ 18%]
tests/test_recommendation_h10.py::test_06_lowest_fare_preference PASSED         [ 22%]
tests/test_recommendation_h10.py::test_07_eta_scoring PASSED                    [ 25%]
tests/test_recommendation_h10.py::test_08_current_crowd_scoring PASSED          [ 29%]
tests/test_recommendation_h10.py::test_09_predicted_crowd_scoring PASSED        [ 33%]
tests/test_recommendation_h10.py::test_10_prediction_confidence_weighting PASSED[ 37%]
tests/test_recommendation_h10.py::test_11_low_data_prediction_handling PASSED   [ 40%]
tests/test_recommendation_h10.py::test_12_data_quality_calculation PASSED       [ 44%]
tests/test_recommendation_h10.py::test_13_explanation_generation PASSED         [ 48%]
tests/test_recommendation_h10.py::test_14_alternative_recommendations PASSED    [ 51%]
tests/test_recommendation_h10.py::test_15_no_candidate_case PASSED              [ 55%]
tests/test_recommendation_h10.py::test_16_no_hardcoded_bus_205_winner PASSED    [ 59%]
tests/test_recommendation_h10.py::test_17_changing_occupancy_changes_recommendation PASSED [ 62%]
tests/test_recommendation_h10.py::test_18_changing_eta_changes_recommendation PASSED [ 66%]
tests/test_recommendation_h10.py::test_19_changing_destination_changes_candidate_set PASSED [ 70%]
tests/test_recommendation_h10.py::test_20_authorization PASSED                  [ 74%]
tests/test_recommendation_h10.py::test_21_api_schema PASSED                     [ 77%]
tests/test_recommendation_h10.py::test_22_passenger_recommendation_integration PASSED [ 81%]
tests/test_recommendation_h10.py::test_23_authority_recommendation_integration PASSED [ 85%]
tests/test_recommendation_h10.py::test_24_existing_h1_h9_regression PASSED     [ 88%]
tests/test_recommendation_h10.py::test_edge_case_full_occupancy_100_percent PASSED [ 92%]
tests/test_recommendation_h10.py::test_edge_case_invalid_preference_mode PASSED[ 96%]
tests/test_recommendation_h10.py::test_recommendation_latency_performance PASSED[100%]

======================== 27 passed, 1 warning in 4.52s ========================
```

---

## 9. Comprehensive System Regression Status

Across all three platform stacks, full regression testing completed with **zero failures**:

| Stack | Suite | Passed | Skipped | Failed | Notes |
|:---|:---|:---:|:---:|:---:|:---|
| **Backend** | `backend/tests/` (10 suites) | **121** | 1 | **0** | Replay video skipped; all H1–H10 tests passing. |
| **Frontend** | `npm.cmd --prefix frontend test` | **19** | 0 | **0** | All 12 Authority suites passed. |
| **Frontend Build** | `npm.cmd --prefix frontend run build` | **22/22** | 0 | **0** | All 22 static/dynamic Next.js routes compiled. |
| **Mobile Flutter** | `flutter test` | **96** | 0 | **0** | All 6 test suites passed. |
| **Mobile Analyze** | `flutter analyze apps/mobile` | **0 issues** | 0 | **0** | Verified clean codebase. |

---

## 10. Known Limitations & Strict Boundaries

1. **Simulated GPS Feeds:** Real-time vehicle positions are generated by the mathematical waypoint simulation engine along Greater Kochi corridors; production GTFS-RT ingestion is deferred.
2. **Prototype Corridor Scope:** Stop-matching and candidate extraction currently model three primary Greater Kochi corridors (Aluva ➔ Vyttila, Fort Kochi ➔ Infopark, Kaloor ➔ Infopark).
3. **No Autonomous Dispatch:** Authority recommendations strictly assist human transit dispatchers; no automated route changes or fleet maneuvers occur without human authorization.
4. **Zero Biometrics:** All Computer Vision inputs remain strictly anonymous head/body bounding counts.

---

## 11. Final Phase Status

```
============================================================
FINAL REPORT MUST STATE
============================================================

H10 STATUS:
COMPLETED

Recommendation engine:
Multi-factor normalized scoring engine balancing ETA, live occupancy,
H9 Ridge demand forecasts, journey duration, transit fare, and priority
bus lane advantages with confidence weighting and data quality rating.

Candidate selection:
Direction-aware stop sequence matching across Greater Kochi transit
corridors (Route 205, Route 14A, Route 12).

Scoring factors:
1. ETA Component (s_eta)
2. Current Crowd Component (s_crowd)
3. Predicted Crowd Component with Confidence Discounting (s_pred)
4. Journey Duration & Priority Bus Lane Component (s_time)
5. Transit Fare Component (s_fare)
6. Corridor Reliability Multiplier

Preference modes:
- balanced (default)
- fastest
- least_crowded
- lowest_fare

H9 prediction integration:
Dynamic horizon selection based on estimated journey duration:
+15m for <= 20 min, +30m for <= 45 min, +60m for > 45 min.
Confidence discounting blends forecast toward current crowd under sparse data.

Data quality:
HIGH (CV Replay active + confident prediction)
MEDIUM (Simulated telemetry active)
LOW (Unmonitored bus or low-data fallback)

Low-data behavior:
Graceful fallback to ETA and distance weighting; transparent disclosures
without throwing runtime errors or inventing confidence.

API:
- GET  /api/recommendations/plan?origin={}&destination={}&preference={}
- POST /api/recommendations/plan
- GET  /api/recommendations/preferences

Passenger integration:
Native integration with Flutter JourneyPlanModel, Explore & Route Planning,
Smart Recommendation card, and Bus Details screen.

Authority integration:
Native integration with Next.js AI Operations, Diagnostic score breakdowns,
and 4-tier decision hierarchy: LIVE DATA -> PREDICTION -> RECOMMENDATION -> HUMAN DECISION.

Hardcoded Bus 205 winner:
NONE (Zero hardcoded preference; recommendation shifts dynamically with
occupancy, ETA, prediction, destination, and user preferences).

Example recommendation:
Origin: Kaloor Metro Station, Destination: Infopark Phase 1 Express Bay
Preference: least_crowded
Recommended: Bus 12 (Score: 78.4, Occupancy: 18.2%, ETA: 5 min)
Alternative: Bus 14A (Score: 61.2, Occupancy: 88.9%, ETA: 2 min)
Explanation: "Bus 12 is recommended for 70.7% lower crowding despite arriving 3 minutes later."

Backend tests:
121 passed, 1 skipped (sample video), 0 failed (backend/tests/)

Flutter tests:
96 passed, 0 failed (apps/mobile)

Flutter analyze:
0 issues found (apps/mobile)

Authority build:
22/22 routes successfully compiled (frontend)

Authority tests:
19 passed, 0 failed (frontend/tests/)

Known limitations:
Prototype Greater Kochi corridor network; simulated GPS telemetry feed;
human-in-the-loop operational review required.

NEXT PHASE:
H11 — RAG AI / INTELLIGENT TRANSPORT ASSISTANT
============================================================
```
