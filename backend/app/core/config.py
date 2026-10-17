"""
BusSense AI - Central Configuration Settings
Hardened for Production Readiness (H14):
- Production SECRET_KEY validation (minimum 32 chars, no dev fallback)
- Dynamic CORS origin parsing (comma-separated or list, no wildcards)
- Production DEMO_MODE and DEBUG locks
- Explicit Supabase Service Role Key support for backend-only operations
"""
import os
from pathlib import Path
from typing import Optional, List
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, field_validator, model_validator

# Base Directory
BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent

# Default development secret key (strictly prohibited in production)
DEFAULT_DEV_SECRET = "bussense_ai_super_secret_jwt_key_2026_prototype_secure"

class Settings(BaseSettings):
    ENVIRONMENT: str = Field(default="development")
    DEBUG: bool = Field(default=False)
    DEMO_MODE: bool = Field(default=True)

    # Server Settings
    BACKEND_HOST: str = Field(default="0.0.0.0")
    BACKEND_PORT: int = Field(default=8000)
    SECRET_KEY: str = Field(default=DEFAULT_DEV_SECRET)
    ALGORITHM: str = Field(default="HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=60 * 24 * 7) # 7 days for prototype
    ALLOWED_ORIGINS: List[str] = Field(
        default=["http://localhost:3000", "http://127.0.0.1:3000"]
    )

    # Supabase Settings (Project: Bus_Sense_AI / lqegmqgkymstycpzplld)
    SUPABASE_URL: str = Field(default="https://lqegmqgkymstycpzplld.supabase.co")
    SUPABASE_ANON_KEY: str = Field(
        default="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxxZWdtcWdreW1zdHljcHpwbGxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0MTg4MTksImV4cCI6MjEwNTk5NDgxOX0.7GxTajcD4CyhlyTca39zziut7DntTQuBsYebZz2hVu0"
    )
    SUPABASE_SERVICE_ROLE_KEY: Optional[str] = Field(default=None)
    SUPABASE_PUBLISHABLE_KEY: str = Field(default="sb_publishable_6bZHWy_5kBZ2nuzk3SZBnw_F9v1XL0S")

    # Simulation & Corridor Settings
    SIMULATION_INTERVAL_SECONDS: int = Field(default=3)
    DEFAULT_TRANSIT_CITY: str = Field(default="Kochi, Kerala")
    
    # Computer Vision Mode
    CV_MODE: str = Field(default="SIMULATION") # "REAL_VIDEO" or "SIMULATION"
    YOLO_MODEL_PATH: str = Field(default="yolov8n.pt")

    # Payment Gateway Sandbox
    PAYMENT_GATEWAY_MODE: str = Field(default="SIMULATED")
    RAZORPAY_KEY_ID: str = Field(default="rzp_test_demo_placeholder")
    RAZORPAY_KEY_SECRET: str = Field(default="rzp_test_secret_placeholder")

    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def parse_allowed_origins(cls, v):
        if isinstance(v, str):
            v = v.strip()
            if v.startswith("[") and v.endswith("]"):
                import json
                try:
                    items = json.loads(v)
                except Exception:
                    items = [x.strip() for x in v[1:-1].split(",") if x.strip()]
            else:
                items = [x.strip() for x in v.split(",") if x.strip()]
            return [origin.rstrip("/") for origin in items if origin]
        elif isinstance(v, (list, tuple, set)):
            return [str(origin).strip().rstrip("/") for origin in v if str(origin).strip()]
        return v

    @model_validator(mode="after")
    def validate_security_and_environment(self) -> "Settings":
        is_prod = self.ENVIRONMENT.lower() == "production"

        # Wildcard with credentials check
        if "*" in self.ALLOWED_ORIGINS:
            raise ValueError(
                "CORS Security Violation: Wildcard '*' in ALLOWED_ORIGINS is prohibited when allow_credentials=True."
            )

        if is_prod:
            # 1. SECRET_KEY validation
            if not self.SECRET_KEY or self.SECRET_KEY == DEFAULT_DEV_SECRET:
                raise ValueError(
                    "Production configuration error: SECRET_KEY must be externally configured and cannot use the development fallback key."
                )
            if len(self.SECRET_KEY) < 32:
                raise ValueError(
                    f"Production configuration error: SECRET_KEY is too short ({len(self.SECRET_KEY)} chars). Minimum 32 characters required."
                )
            insecure_phrases = ["prototype", "default", "secret_jwt_key", "password", "changeme", "example"]
            if any(phrase in self.SECRET_KEY.lower() for phrase in insecure_phrases):
                raise ValueError(
                    "Production configuration error: SECRET_KEY contains an insecure placeholder phrase."
                )

            # 2. DEBUG and DEMO_MODE must be False in production
            if self.DEBUG:
                raise ValueError("Production configuration error: DEBUG must be set to False in production.")
            if self.DEMO_MODE:
                raise ValueError("Production configuration error: DEMO_MODE must be set to False in production.")

            # 3. ALLOWED_ORIGINS validation in production
            if not self.ALLOWED_ORIGINS:
                raise ValueError("Production configuration error: ALLOWED_ORIGINS must be explicitly configured.")
            localhost_origins = {"http://localhost:3000", "http://127.0.0.1:3000", "localhost", "127.0.0.1"}
            if set(self.ALLOWED_ORIGINS).issubset(localhost_origins):
                raise ValueError(
                    "Production configuration error: ALLOWED_ORIGINS contains only localhost in production. Explicit production domain(s) required."
                )

            # 4. SUPABASE_URL validation
            if not self.SUPABASE_URL.startswith("https://"):
                raise ValueError("Production configuration error: SUPABASE_URL must be a secure https:// endpoint.")
            if not self.SUPABASE_ANON_KEY:
                raise ValueError("Production configuration error: SUPABASE_ANON_KEY must be configured.")

        return self

settings = Settings()

# Controlled Development Demo Credentials (Used ONLY when DEMO_MODE=True AND ENVIRONMENT!=production)
DEV_ACCOUNTS = {
    "passenger": {
        "id": "11111111-1111-1111-1111-111111111111",
        "email": "rahul.nair@bussense.kerala.gov.in",
        "role": "PASSENGER",
        "full_name": "Rahul Nair",
        "hashed_password": "$2b$12$bn4cUexl9v/tGerfV3H2D.HsM8zLzKauzS5WbU.3lvae0m0C094li"
    },
    "driver": {
        "id": "22222222-2222-2222-2222-222222222222",
        "email": "suresh.kumar@bussense.kerala.gov.in",
        "role": "DRIVER_CONDUCTOR",
        "full_name": "Suresh Kumar (Driver #402)",
        "hashed_password": "$2b$12$bn4cUexl9v/tGerfV3H2D.HsM8zLzKauzS5WbU.3lvae0m0C094li"
    },
    "authority": {
        "id": "33333333-3333-3333-3333-333333333333",
        "email": "controller.vyttila@bussense.kerala.gov.in",
        "role": "AUTHORITY",
        "full_name": "Anjali Menon (Traffic Controller)",
        "hashed_password": "$2b$12$bn4cUexl9v/tGerfV3H2D.HsM8zLzKauzS5WbU.3lvae0m0C094li"
    }
}
