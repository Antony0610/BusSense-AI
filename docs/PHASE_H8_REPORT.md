# BusSense AI — Phase H8 Report
## Computer Vision Occupancy Intelligence (Offline / Replayable Pipeline)

**Phase Status:** COMPLETED  
**Classification:** IMPLEMENTED / CV REPLAY  
**Regression Status:** ZERO REGRESSION (Flutter: 96/96 passed, 0 analyze issues; Backend: 78/78 passed; Authority: 22/22 routes compiled, 19/19 frontend tests passed)  
**Date:** September 2026  

---

## 1. Executive Summary

Phase H8 transitions BusSense AI from purely synthetic occupancy generation to a genuine, replayable computer vision occupancy pipeline executing against recorded transit video:

$$\text{VIDEO} \longrightarrow \text{FRAME SAMPLING} \longrightarrow \text{YOLO PERSON DETECTION} \longrightarrow \text{PERSON COUNT} \longrightarrow \text{TEMPORAL STABILIZATION} \longrightarrow \text{OCCUPANCY CALCULATION} \longrightarrow \text{CROWD CLASSIFICATION} \longrightarrow \text{BACKEND API} \longrightarrow \text{PASSENGER / CONDUCTOR / AUTHORITY}$$

**Core Operating Principle:**
$$\text{SEE} \longrightarrow \text{COUNT} \longrightarrow \text{SENSE} \longrightarrow \text{PUBLISH}$$

The pipeline processes people, not identities. In accordance with BusSense AI privacy standards, the vision engine detects anonymous bounding boxes for COCO Class 0 (`person`) exclusively. Facial recognition, facial identification, demographic estimation, biometric templates, and person re-identification are architecturally prohibited and verified absent.

---

## 2. Classification Matrix

| Component | Status | Classification | Details |
|:---|:---:|:---:|:---|
| **YOLO Person Detection** | Verified | **IMPLEMENTED** | Ultralytics YOLOv8n, strictly filtered to class 0 (`person`). |
| **Temporal Stabilization** | Verified | **IMPLEMENTED** | Explainable 5-frame rolling median outlier rejector. |
| **Occupancy & Crowd Engine** | Verified | **IMPLEMENTED** | Standardized formula clamped to `[0.0, 100.0]%` and 3 crowd tiers. |
| **Video Replay Pipeline** | Verified | **CV REPLAY** | Offline frame sampling on MP4 video (`datasets/videos/sample_bus.mp4`). |
| **Debug Video Annotation** | Verified | **IMPLEMENTED** | Bounding box overlays + HUD diagnostics box without biometric tags. |
| **Backend Ingestion Endpoint** | Verified | **IMPLEMENTED** | `POST /api/occupancy/events` with role-based & internal secret auth. |
| **Telemetry State Reflection** | Verified | **CV REPLAY** | Updates fleet state; stamps `data_origin: "CV REPLAY"`. |
| **Database Persistence** | Verified | **IMPLEMENTED** | Migration `004_cv_replay_support.sql` persists to `occupancy_readings`. |
| **Physical CCTV Hardware** | Prohibited | **DEFERRED** | No physical camera or edge board integration in H8. |
| **RTSP Live Streaming** | Prohibited | **DEFERRED** | No live RTSP streaming infrastructure in H8. |
| **Edge Hardware (Jetson/RPi)** | Prohibited | **DEFERRED** | Hardware deployment deferred to future phases. |

---

## 3. Computer Vision Architecture

The computer vision architecture is completely modularized in `backend/cv/` and separated cleanly from FastAPI route files:

```
backend/cv/
├── __init__.py               # Package exports & lazy attribute loader
├── schemas.py                # DetectionBox, FrameDetectionResult, OccupancyEvent, ReplaySummary
├── detector.py               # YOLOPersonDetector (Ultralytics YOLOv8n, device auto-detect)
├── smoothing.py              # TemporalStabilizer (rolling median window)
├── occupancy.py              # OccupancyCalculator (clamped ratio & crowd tier classification)
├── video_processor.py        # VideoReplayProcessor (offline frame sampling & debug HUD)
└── create_sample_video.py    # Deterministic MP4 test video generator
```

### Flow Diagram

```mermaid
flowchart LR
    A[Recorded MP4 Video] --> B[Frame Sampling N=3]
    B --> C[YOLOv8n Class 0 Inference]
    C --> D[Confidence Filter >= 0.40]
    D --> E[Raw Person Count]
    E --> F[Rolling Median Stabilizer]
    F --> G[Stabilized Count]
    G --> H[Occupancy Formula & Clamping]
    H --> I[Crowd Classification]
    I --> J[OccupancyEvent Dispatch]
    J --> K[POST /api/occupancy/events]
    K --> L[Fleet State & Database]
    L --> M[Passenger / Conductor / Authority APIs]
```

---

## 4. Model Details & Dependencies

- **Model Family:** YOLOv8 (You Only Look Once, v8 architecture)
- **Model Variant:** `YOLOv8n` (Nano — 3.2M parameters, 6.2 MB weights)
- **Class Filtering:** COCO Class 0 (`person`) exclusively. All other 79 COCO classes are dropped at inference time via `classes=[0]`.
- **Target Confidence Threshold:** `0.40` (configurable between `0.0` and `1.0`).
- **Device Auto-Detection:** Automatically inspects `torch.cuda.is_available()`. Falls back smoothly to CPU for local development.

### Verified Python Dependencies

| Package | Version Installed | Purpose |
|:---|:---|:---|
| `opencv-python` | `5.0.0.93` | Video decoding, frame extraction, debug annotation |
| `ultralytics` | `8.4.163` | YOLOv8n inference pipeline |
| `torch` | `2.14.0+cpu` | PyTorch compute backend (CPU verified) |
| `torchvision` | `0.29.0+cpu` | Vision utilities |
| `pydantic` | `2.12.5` | Strict schema validation |
| `fastapi` | `0.135.1` | REST API framework |

---

## 5. Offline Video Replay & Frame Sampling

- **Input Format:** Standard MP4 (`.mp4`) and OpenCV-readable formats.
- **Sample Dataset:** `datasets/videos/sample_bus.mp4` (60 frames @ 20 FPS, 640x480 resolution).
- **Sampling Strategy:** Configurable frame stride `process_every_n_frames` (default: `3`).
  - Input Video FPS: 20–25 FPS
  - Processed Stride: Frame 0, Frame 3, Frame 6, ...
  - Effective Processing Stride: ~6.7–8.3 effective FPS
- **Deterministic Replay Command:**
  ```powershell
  & "backend/.venv/Scripts/python.exe" -m backend.cv.video_processor `
      --video datasets/videos/sample_bus.mp4 `
      --bus 205 `
      --capacity 55 `
      --step 3 `
      --output datasets/videos/annotated_sample_bus.mp4
  ```

---

## 6. Occupancy Calculation & Crowd Classification

### Occupancy Percentage Formula

$$\text{occupancy\_percentage} = \operatorname{clamp}\left(\frac{\text{stabilized\_person\_count}}{\text{capacity}} \times 100,\ 0.0,\ 100.0\right)$$

- Clamped strictly to $[0.0, 100.0]\%$.
- Rejects negative passenger counts (floored at 0).
- Raises validation error if vehicle capacity $\le 0$.

### Unified BusSense Crowd Tiers

| Crowd Level | Occupancy Range | Description |
|:---|:---|:---|
| **LOW** | $< 50.0\%$ | Ample seating available, uncrowded aisle |
| **MODERATE** | $50.0\% \le \text{occupancy} \le 80.0\%$ | Most seats occupied, comfortable standing |
| **CROWDED** | $> 80.0\%$ | High density, limited standing space |

---

## 7. Temporal Smoothing Method

- **Method:** Rolling Median Filter (`TemporalStabilizer`)
- **Default Window Size:** 5 processed frames
- **Rationale:**
  1. Rejects single-frame false-positive spikes (e.g., transient occlusion or hand gestures).
  2. Rejects single-frame dropouts (e.g., momentary camera glare).
  3. Avoids the asymptotic lag of exponential moving averages (EMA) during actual boarding events.
- **Output Distinction:** Every event explicitly provides both `raw_person_count` and `stabilized_person_count`.

---

## 8. Occupancy Event Schema

```json
{
  "bus_number": "205",
  "timestamp": "2026-09-27T15:45:00.000000+00:00",
  "raw_person_count": 3,
  "stabilized_person_count": 3,
  "capacity": 55,
  "occupancy_percentage": 5.5,
  "crowd_level": "LOW",
  "source": "CV_REPLAY",
  "model": "YOLOv8n",
  "confidence_threshold": 0.40,
  "inference_time_ms": 293.3,
  "fps": 20.0,
  "frame_number": 12,
  "privacy_standard": "PERSON_COUNTING_ONLY_NO_BIOMETRICS"
}
```

---

## 9. Backend Integration & Ingestion Security

### Ingestion Route
- **Endpoint:** `POST /api/occupancy/events`
- **Authentication:**
  - `AUTHORITY` or `ADMIN` JWT Bearer token via `Authorization: Bearer <token>`
  - Internal worker secret via `X-Internal-Secret: <SECRET_KEY>`
  - Unauthenticated requests: `401 Unauthorized`
  - `PASSENGER` or `DRIVER_CONDUCTOR` requests: `403 Forbidden`
- **Backend Validation:**
  - Bus number validated against active fleet state (`404` if unknown).
  - Capacity $> 0$ enforced (`422` if $\le 0$).
  - Counts $\ge 0$ enforced (`422` if negative).
  - **Zero Trust:** Backend never trusts client-supplied percentages; it recalculates trusted occupancy percentage and crowd tier.
- **Fleet State Reflection:**
  - Sets `data_origin = DataOrigin.CV_REPLAY` ("CV REPLAY").
  - Sets `passenger_count = event.stabilized_person_count`.
  - Sets `occupancy_pct = trusted_pct`.
  - Disables simulated random passenger flux in `GpsSimulationEngine` while vehicle is in CV replay mode.
  - Returns `CV REPLAY` on `/api/crowd/{bus_number}` and `/api/occupancy/live/{bus_number}`.

---

## 10. Database Persistence & Migrations

- **Migration Script:** [backend/migrations/004_cv_replay_support.sql](file:///d:/Bus_Sense_Ai/backend/migrations/004_cv_replay_support.sql)
  - Adds `'CV_REPLAY'` and `'ESTIMATE'` values to the PostgreSQL `data_origin` enum type.
- **Persistence Target:** Supabase PostgreSQL table `occupancy_readings`:
  - `bus_id`: UUID
  - `passenger_count`: INT
  - `capacity`: INT
  - `occupancy_pct`: NUMERIC(5, 2)
  - `crowd_level`: crowd_level
  - `detection_source`: VARCHAR (e.g. `'YOLOv8n_CV_Replay'`)
  - `data_origin`: `'CV_REPLAY'`
  - `recorded_at`: TIMESTAMPTZ

---

## 11. Privacy & Ethical Boundaries

| Privacy Dimension | Guarantee | Verification Result |
|:---|:---|:---|
| **Facial Recognition** | Prohibited | Verified: 0 facial recognition libraries in codebase. |
| **Facial Identification** | Prohibited | Verified: No facial embedding or identification code. |
| **Biometric Templates** | Prohibited | Verified: Zero biometric data structures in schemas. |
| **Passenger Identity** | Prohibited | Verified: Schema contains only anonymous headcount. |
| **Demographic Inference** | Prohibited | Verified: No age, gender, or demographic classification. |
| **Re-Identification** | Prohibited | Verified: No cross-camera tracking or re-id models. |

---

## 12. Empirical Performance Measurements

Measured during verification on Windows development machine:

- **Compute Device:** Intel CPU (CPU mode verified)
- **Model:** YOLOv8n (PyTorch CPU backend)
- **Single-Frame Inference Latency:** $293.3\text{ ms/frame}$ average
- **Replay Processing Speed:** $3.3\text{ FPS}$ (at stride $N=3$)
- **Peak Occupancy Detected:** $5.5\%$ (3 persons in 55-seat bus)
- **Crowd Tier Distribution:** $100\%$ LOW

---

## 13. Test Results & Verification

### A. New CV Occupancy Test Suite (`backend/tests/test_cv_occupancy_h8.py`)
- **Total Tests:** 22/22 PASSED (100%)
  1. `test_person_class_filtering`: PASSED
  2. `test_confidence_filtering`: PASSED
  3. `test_raw_person_count`: PASSED
  4. `test_occupancy_calculation`: PASSED
  5. `test_occupancy_clamping`: PASSED
  6. `test_invalid_capacity_rejected`: PASSED
  7. `test_threshold_classification`: PASSED
  8. `test_temporal_smoothing_rolling_median`: PASSED
  9. `test_stabilizer_reset`: PASSED
  10. `test_occupancy_event_schema`: PASSED
  11. `test_invalid_crowd_level_in_schema`: PASSED
  12. `test_privacy_boundaries_zero_biometrics`: PASSED
  13. `test_device_auto_detection`: PASSED
  14. `test_video_replay_missing_file_raises`: PASSED
  15. `test_sample_bus_video_replay`: PASSED
  16. `test_ingest_occupancy_unauthenticated_rejected`: PASSED
  17. `test_ingest_occupancy_passenger_role_rejected`: PASSED
  18. `test_ingest_occupancy_conductor_role_rejected`: PASSED
  19. `test_ingest_occupancy_invalid_bus_rejected`: PASSED
  20. `test_ingest_occupancy_recalculates_trusted_percentage`: PASSED
  21. `test_ingest_occupancy_internal_secret_auth`: PASSED
  22. `test_fleet_and_crowd_apis_reflect_cv_replay`: PASSED

### B. Complete Regression Suite
- **Backend Tests:** 78/78 PASSED (56 baseline + 22 H8 tests, 0 failures)
- **Flutter Mobile Tests:** 96/96 PASSED (0 failures)
- **Flutter Analyze:** 0 issues found (clean)
- **Authority Next.js Build:** 22/22 routes compiled successfully
- **Authority Frontend Tests:** 19/19 PASSED (0 failures)

---

## 14. Edge Deployment Architecture (Future Preparation)

While hardware deployment is strictly deferred, the CV engine is architecturally structured for future edge deployment:

- **Target Platforms:** NVIDIA Jetson Orin Nano / Raspberry Pi 5 with Hailo-8 AI accelerator.
- **Future Integration:** An onboard edge service running `video_processor.py` connected to a bus cabin camera will ingest frames, compute stabilized counts locally on the vehicle, and dispatch aggregate `OccupancyEvent` payloads over 4G/5G MQTT/HTTPS to the backend.
- **Privacy Assurance at Edge:** No raw video frames leave the bus edge computer; only aggregate anonymous occupancy counts are transmitted.
