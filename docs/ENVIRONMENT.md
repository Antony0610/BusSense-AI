# BusSense AI — Environment Variables & Configuration

This document specifies all environment variables utilized across the BusSense AI backend and frontend applications.

---

## 1. Environment Variable Reference

| Variable Name | Required? | Default / Example Value | Description |
|---|:---:|---|---|
| `ENVIRONMENT` | Yes | `development` | Runtime environment (`development`, `staging`, `production`). |
| `DEBUG` | Yes | `True` | Enables FastAPI auto-reload and verbose logging. |
| `DEMO_MODE` | Yes | `True` | Enables pre-seeded demo accounts and simulated telemetry physics. |
| `BACKEND_HOST` | Yes | `0.0.0.0` | Host interface for FastAPI ASGI server. |
| `BACKEND_PORT` | Yes | `8000` | Port for FastAPI ASGI server. |
| `SECRET_KEY` | Yes | `[REDACTED_SECURE_JWT_SECRET]` | Cryptographic secret for signing JWTs and ticket HMACs. |
| `DATABASE_URL` | Optional | `postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres` | Direct PostgreSQL connection string for database migrations. |
| `SUPABASE_URL` | Yes | `https://lqegmqgkymstycpzplld.supabase.co` | Supabase project API gateway endpoint. |
| `SUPABASE_ANON_KEY` | Yes | `[REDACTED_SUPABASE_ANON_KEY]` | Supabase anonymous public client key with RLS enforcement. |
| `SUPABASE_SERVICE_ROLE_KEY` | Optional | `[REDACTED_SERVICE_KEY]` | Supabase service key for administrative schema migrations. |
| `SUPABASE_PUBLISHABLE_KEY` | Optional | `sb_publishable_6bZHWy_5kBZ2nuzk3SZBnw_F9v1XL0S` | Client-side publishable telemetry access key. |
| `SIMULATION_INTERVAL_SECONDS`| Yes | `2` | Headway interval for the background GPS physics ticker. |
| `DEFAULT_TRANSIT_CITY` | Yes | `Kochi` | Regional center for corridor initialization. |
| `CV_MODE` | Yes | `SIMULATION` | Vision pipeline mode (`SIMULATION` or `REAL_VIDEO`). |
| `YOLO_MODEL_PATH` | Optional | `yolov8n.pt` | Path to YOLOv8 weights file for edge inference. |
| `PAYMENT_GATEWAY_MODE` | Yes | `SIMULATED` | Payment engine mode (`SIMULATED` or `RAZORPAY_TEST`). |
| `RAZORPAY_KEY_ID` | Optional | `rzp_test_placeholder` | Razorpay sandbox merchant key ID. |
| `RAZORPAY_KEY_SECRET` | Optional | `rzp_test_secret_placeholder` | Razorpay sandbox merchant secret key. |
| `AI_API_KEY` | Optional | `placeholder_llm_api_key` | Optional external LLM API key (Gemini / Anthropic / OpenAI). |
| `MAP_API_KEY` | Optional | `placeholder_map_tile_key` | Optional vector map tile provider API key. |

---

## 2. Configuration Loading Mechanism

- **Backend:** Loaded via Pydantic `BaseSettings` in `backend/app/core/config.py`.
- **Frontend:** Client-facing environment variables are prefixed with `NEXT_PUBLIC_` (e.g. `NEXT_PUBLIC_BACKEND_URL=http://localhost:8000`).
- **Security Rule:** Never check `.env` into Git repositories. Always commit `.env.example` with sanitized placeholder values.
