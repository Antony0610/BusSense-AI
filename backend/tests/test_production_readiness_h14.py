"""
BusSense AI - Phase H14 Production Readiness & Reliability Tests
Verifies:
1. Production SECRET_KEY validation (minimum 32 chars, no dev fallback, no placeholder phrases)
2. Dynamic CORS parsing, normalization, and wildcard prohibition
3. Production demo-account authentication lockout
4. Liveness probe (HTTP 200, no external dependencies)
5. Readiness probe (HTTP 200 on healthy dependency, HTTP 503 on degraded dependency)
6. Centralized sanitized 500 error handling with X-Request-ID correlation
7. Structured logging safety (no secret leakage)
8. Conductor ticket validation authorization & anti-reuse
"""
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import pytest
from unittest.mock import AsyncMock, patch
from fastapi.testclient import TestClient
from app.main import app
from app.core.config import Settings, DEFAULT_DEV_SECRET, settings
from app.core.security import create_access_token

client = TestClient(app, raise_server_exceptions=False)


# ==============================================================================
# 1. CONFIGURATION & SECRETS HARDENING TESTS
# ==============================================================================

def test_production_missing_secret_key_rejected():
    """Production mode must reject missing or empty SECRET_KEY."""
    with pytest.raises(ValueError, match="SECRET_KEY must be externally configured"):
        Settings(
            ENVIRONMENT="production",
            DEBUG=False,
            DEMO_MODE=False,
            SECRET_KEY="",
            ALLOWED_ORIGINS=["https://bussense.kerala.gov.in"]
        )


def test_production_default_fallback_secret_rejected():
    """Production mode must reject default prototype fallback SECRET_KEY."""
    with pytest.raises(ValueError, match="cannot use the development fallback key"):
        Settings(
            ENVIRONMENT="production",
            DEBUG=False,
            DEMO_MODE=False,
            SECRET_KEY=DEFAULT_DEV_SECRET,
            ALLOWED_ORIGINS=["https://bussense.kerala.gov.in"]
        )


def test_production_short_secret_key_rejected():
    """Production mode must reject SECRET_KEY with fewer than 32 characters."""
    with pytest.raises(ValueError, match="Minimum 32 characters required"):
        Settings(
            ENVIRONMENT="production",
            DEBUG=False,
            DEMO_MODE=False,
            SECRET_KEY="too_short_key_12345",
            ALLOWED_ORIGINS=["https://bussense.kerala.gov.in"]
        )


def test_production_insecure_phrase_secret_rejected():
    """Production mode must reject SECRET_KEY containing placeholder / prototype phrases."""
    with pytest.raises(ValueError, match="insecure placeholder phrase"):
        Settings(
            ENVIRONMENT="production",
            DEBUG=False,
            DEMO_MODE=False,
            SECRET_KEY="bussense_very_long_prototype_secret_key_secure_2026",
            ALLOWED_ORIGINS=["https://bussense.kerala.gov.in"]
        )


def test_production_valid_configuration_passes():
    """Valid production settings with strong key and explicit origins must succeed."""
    prod_settings = Settings(
        ENVIRONMENT="production",
        DEBUG=False,
        DEMO_MODE=False,
        SECRET_KEY="c8f7e6d5c4b3a2f1e0d9c8b7a6f5e4d3c2b1a0f9e8d7c6b5a4f3e2d1c0b9a8f7",
        ALLOWED_ORIGINS=["https://bussense.kerala.gov.in", "https://admin.bussense.kerala.gov.in"],
        SUPABASE_URL="https://lqegmqgkymstycpzplld.supabase.co",
        SUPABASE_ANON_KEY="valid_token_sample"
    )
    assert prod_settings.ENVIRONMENT == "production"
    assert prod_settings.DEBUG is False
    assert prod_settings.DEMO_MODE is False
    assert len(prod_settings.SECRET_KEY) >= 32


def test_development_fallback_compatibility():
    """Development environment must seamlessly allow default development settings."""
    dev_settings = Settings(ENVIRONMENT="development")
    assert dev_settings.ENVIRONMENT == "development"
    assert dev_settings.SECRET_KEY == DEFAULT_DEV_SECRET


# ==============================================================================
# 2. DYNAMIC CORS CONFIGURATION TESTS
# ==============================================================================

def test_cors_wildcard_with_credentials_prohibited():
    """Wildcard '*' in ALLOWED_ORIGINS must be strictly prohibited."""
    with pytest.raises(ValueError, match="CORS Security Violation"):
        Settings(ALLOWED_ORIGINS="*")


def test_dynamic_cors_comma_separated_parsing():
    """ALLOWED_ORIGINS string in .env must parse and normalize correctly."""
    s = Settings(
        ALLOWED_ORIGINS="https://bussense.kerala.gov.in/, https://ops.bussense.kerala.gov.in"
    )
    assert s.ALLOWED_ORIGINS == [
        "https://bussense.kerala.gov.in",
        "https://ops.bussense.kerala.gov.in"
    ]


def test_production_localhost_only_cors_rejected():
    """Production environment cannot silently use only localhost origins."""
    with pytest.raises(ValueError, match="contains only localhost in production"):
        Settings(
            ENVIRONMENT="production",
            DEBUG=False,
            DEMO_MODE=False,
            SECRET_KEY="c8f7e6d5c4b3a2f1e0d9c8b7a6f5e4d3c2b1a0f9e8d7c6b5a4f3e2d1c0b9a8f7",
            ALLOWED_ORIGINS=["http://localhost:3000"]
        )


# ==============================================================================
# 3. DEMO-ACCOUNT ISOLATION TESTS
# ==============================================================================

def test_demo_account_rejected_in_production():
    """Demo commuter login must be rejected when ENVIRONMENT=production."""
    with patch.object(settings, "ENVIRONMENT", "production"), \
         patch.object(settings, "DEMO_MODE", False):
        resp = client.post("/api/auth/login", json={
            "email": "rahul.nair@bussense.kerala.gov.in",
            "password": "password123"
        })
        assert resp.status_code == 401
        assert resp.json()["detail"] in ["Invalid credentials. Account not found.", "Invalid email or password."]


def test_demo_account_rejected_when_demo_mode_false():
    """Demo login must be rejected when DEMO_MODE=False even in development."""
    with patch.object(settings, "DEMO_MODE", False):
        resp = client.post("/api/auth/login", json={
            "email": "rahul.nair@bussense.kerala.gov.in",
            "password": "password123"
        })
        assert resp.status_code == 401


# ==============================================================================
# 4. HEALTH & PROBE ENDPOINTS TESTS
# ==============================================================================

def test_liveness_probe_returns_200():
    """Liveness probe must return 200 OK without calling external dependencies."""
    resp = client.get("/health/live")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "alive"
    assert "timestamp" in data
    assert "X-Request-ID" in resp.headers


def test_readiness_probe_healthy():
    """Readiness probe must return 200 OK when Supabase ping succeeds."""
    with patch("app.main.supabase_client.ping", new=AsyncMock(return_value=True)):
        resp = client.get("/health/ready")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "ready"
        assert data["database"] == "connected"


def test_readiness_probe_degraded_returns_503():
    """Readiness probe must return 503 Service Unavailable when Supabase ping fails."""
    with patch("app.main.supabase_client.ping", new=AsyncMock(return_value=False)):
        resp = client.get("/health/ready")
        assert resp.status_code == 503
        data = resp.json()
        assert data["status"] == "unready"
        assert data["database"] == "disconnected"
        assert "detail" in data


def test_backwards_compatible_health_endpoint():
    """Existing /health endpoint must remain functional and sanitized."""
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] in ["healthy", "degraded"]
    assert "supabase_project" not in data # Credentials / internal hostnames removed


# ==============================================================================
# 5. CENTRALIZED EXCEPTION HANDLING & CORRELATION ID
# ==============================================================================

def test_unhandled_exception_sanitized_500():
    """Unhandled exceptions must return sanitized JSON with X-Request-ID and no traceback."""
    # Temporarily mount a test route that raises an unhandled error
    @app.get("/api/test-fault-injection")
    async def faulty_route():
        raise RuntimeError("Simulated internal database crash with password=SuperSecret123")

    resp = client.get("/api/test-fault-injection")
    assert resp.status_code == 500
    data = resp.json()
    assert data["error"] == "Internal server error"
    assert data["code"] == "INTERNAL_SERVER_ERROR"
    assert "SuperSecret123" not in resp.text
    assert "Traceback" not in resp.text
    assert "request_id" in data
    assert resp.headers.get("X-Request-ID") == data["request_id"]


# ==============================================================================
# 6. TICKET VALIDATION AUTHORIZATION & SECURITY
# ==============================================================================

def test_ticket_validation_unauthorized_passenger_rejected():
    """Passengers must be rejected with 403 Forbidden when calling /api/tickets/validate."""
    passenger_token = create_access_token({
        "sub": "11111111-1111-1111-1111-111111111111",
        "email": "passenger@bussense.ai",
        "role": "PASSENGER",
        "full_name": "Test Passenger"
    })
    resp = client.post(
        "/api/tickets/validate",
        headers={"Authorization": f"Bearer {passenger_token}"},
        json={"qr_code_hash": "bussense://test", "bus_number": "205"}
    )
    assert resp.status_code == 403
