"""
BusSense AI - Central Configuration Settings
"""
import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

# Base Directory
BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent

class Settings(BaseSettings):
    ENVIRONMENT: str = Field(default="development")
    DEBUG: bool = Field(default=False)
    DEMO_MODE: bool = Field(default=True)

    # Server Settings
    BACKEND_HOST: str = Field(default="0.0.0.0")
    BACKEND_PORT: int = Field(default=8000)
    SECRET_KEY: str = Field(default="bussense_ai_super_secret_jwt_key_2026_prototype_secure")
    ALGORITHM: str = Field(default="HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=60 * 24 * 7) # 7 days for prototype
    ALLOWED_ORIGINS: list[str] = Field(
        default=["http://localhost:3000", "http://127.0.0.1:3000"]
    )

    # Supabase Settings (Project: Bus_Sense_AI / lqegmqgkymstycpzplld)
    SUPABASE_URL: str = Field(default="https://lqegmqgkymstycpzplld.supabase.co")
    SUPABASE_ANON_KEY: str = Field(
        default="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxxZWdtcWdreW1zdHljcHpwbGxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0MTg4MTksImV4cCI6MjEwNTk5NDgxOX0.7GxTajcD4CyhlyTca39zziut7DntTQuBsYebZz2hVu0"
    )
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

settings = Settings()

# Controlled Development Demo Credentials (Used ONLY when DEMO_MODE=True in development)
# Passwords are properly stored as bcrypt hashes ($2b$12$)
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

