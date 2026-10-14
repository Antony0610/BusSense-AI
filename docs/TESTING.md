# BusSense AI — Testing & Verification Guide

This document outlines the testing strategy, test suites, test coverage, and commands for running automated tests across the BusSense AI codebase.

---

## 1. Test Suite Summary

The backend includes a comprehensive automated test suite (`backend/tests/test_backend.py`) covering core business logic, forecasting models, computer vision classifiers, cryptographic ticketing, and RAG assistant pipelines.

| Test Function | Target Component | Verifications Performed | Status |
|---|---|---|:---:|
| `test_root_endpoint` | `GET /` | API service identity and healthy root response | PASS |
| `test_health_endpoint` | `GET /health` | System health check and Supabase connectivity | PASS |
| `test_buses_telemetry` | `GET /api/buses` | Active fleet retrieval, GPS coordinates, occupancy | PASS |
| `test_crowd_forecasting` | `demand_forecaster.py` | Multi-horizon Ridge prediction (+0, +15, +30, +60m) | PASS |
| `test_smart_recommendations` | `recommendation_engine.py`| Multi-factor scoring, seat probability, "Why" drawer | PASS |
| `test_ticket_booking_and_qr_validation`| `ticket_service.py` | Pass booking, Base64 QR generation, conductor scan | PASS |
| `test_rag_ai_assistant` | `rag_service.py` | Grounded RAG query, source citation, live telemetry | PASS |

---

## 2. Test Execution Commands

### Running Backend Automated Tests
From the project root:
```powershell
# Windows PowerShell:
& "backend/.venv/Scripts/python.exe" -m pytest backend/tests/ -v
```

Expected Output:
```
backend/tests/test_backend.py::test_root_endpoint PASSED                  [ 14%]
backend/tests/test_backend.py::test_health_endpoint PASSED                [ 28%]
backend/tests/test_backend.py::test_buses_telemetry PASSED                [ 42%]
backend/tests/test_backend.py::test_crowd_forecasting PASSED              [ 57%]
backend/tests/test_backend.py::test_smart_recommendations PASSED          [ 71%]
backend/tests/test_backend.py::test_ticket_booking_and_qr_validation PASSED [ 85%]
backend/tests/test_backend.py::test_rag_ai_assistant PASSED              [100%]

============================== 7 passed in 0.84s ==============================
```

### Running Frontend Compilation & Build Validation
From the project root:
```powershell
npm.cmd --prefix frontend run build
```

---

## 3. Test Categories & Scenarios

### 1. Computer Vision Unit Tests
- Verifies that `calculate_occupancy(23, 55)` yields `41.8%`.
- Verifies that `classify_crowd(41.8)` returns `"LOW"`.
- Verifies that `classify_crowd(65.0)` returns `"MODERATE"`.
- Verifies that `classify_crowd(88.0)` returns `"CROWDED"`.

### 2. Digital Pass Validation Lifecycle Tests
- Tests initial booking yields `status: "VALID"`.
- First conductor validation returns `validation_result: "VALID"` and transitions ticket to `"USED"`.
- Second scan of identical QR payload immediately returns `validation_result: "ALREADY_USED"`.
- Scans past expiration window return `validation_result: "EXPIRED"`.

### 3. RAG Grounding & Anti-Hallucination Tests
- Queries mentioning active buses verify that live occupancy is injected into the response context.
- Queries regarding unsupported routes assert that the standardized fallback message is triggered.
