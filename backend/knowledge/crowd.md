# BusSense AI — Cabin Crowd Intelligence & Privacy Architecture
Document ID: KB-CROWD
Category: CROWD_INTELLIGENCE_AND_PRIVACY
Version: 1.1.0
Last Verified: October 2026

## 1. Zero-Biometrics Privacy Policy & Crowd Estimation
- **Cabin Crowd Estimation Standard:** BusSense AI cabin crowd estimation and occupancy sensing uses an edge-compatible YOLOv8 object detector strictly locked to COCO Class 0 (`person`) bounding boxes to estimate cabin crowding without violating privacy.
- **Strict Privacy Guarantees:**
  - ZERO facial recognition: The system does NOT perform facial recognition or facial geometry indexing.
  - ZERO biometric identification or demographic classification (no age, gender, or race classification).
  - ZERO passenger tracking across transit journeys.
  - Video frames are processed in transient RAM; video streams are never stored or archived on disk.
  - Temporal smoothing uses an explainable 5-frame rolling median to reject transient camera flicker.

## 2. Cabin Density Thresholds & Crowd Classification
- **LOW Crowd:** Cabin occupancy strictly below 50% (< 27 passengers on a 55-seat bus). Seating is widely available.
- **MODERATE Crowd:** Cabin occupancy between 50% and 80% (28 to 44 passengers). Limited seating remains; standing room begins.
- **CROWDED:** Cabin occupancy strictly exceeds 80% (> 44 passengers). Heavy standing load; boarding delays likely.

## 3. Four-Horizon Demand Forecasting
- **Forecaster Model:** scikit-learn Ridge regression with cyclical time encoding ($\sin/\cos$ hour) and temporal lag features.
- **Prediction Horizons:**
  - **NOW (+0 min):** Current telemetric or CV replay passenger occupancy.
  - **+15 MIN:** Near-term stop progression projection.
  - **+30 MIN:** Mid-journey corridor demand projection.
  - **+60 MIN:** Terminal arrival crowd projection.
- **Low-Data Transparency:** When a corridor or bus has sparse observation records, predictions are returned with `status: "LOW_DATA"` and discounted confidence (< 0.60).
- **Truth Labels:** All occupancy data is explicitly labeled as `LIVE DATA`, `CV REPLAY`, `SIMULATED DATA`, or `PREDICTION`.
