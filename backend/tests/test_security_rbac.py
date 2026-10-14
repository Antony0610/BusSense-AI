import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token

client = TestClient(app)

def get_headers(role: str, user_id: str = "test-user-id", email: str = "test@bussense.ai"):
    token = create_access_token({
        "sub": user_id,
        "email": email,
        "role": role,
        "full_name": f"Test {role}"
    })
    return {"Authorization": f"Bearer {token}"}

def test_unauthenticated_request_rejected():
    """Unauthenticated request to protected endpoints must return 401."""
    resp = client.get("/api/auth/me")
    assert resp.status_code == 401
    assert "detail" in resp.json()

    resp_tickets = client.get("/api/tickets/my")
    assert resp_tickets.status_code == 401

    resp_command = client.get("/api/analytics/command-overview")
    assert resp_command.status_code == 401

def test_invalid_token_rejected():
    """Request with malformed / invalid signature token must return 401."""
    headers = {"Authorization": "Bearer invalid.token.payload"}
    resp = client.get("/api/auth/me", headers=headers)
    assert resp.status_code == 401
    assert "Could not validate credentials" in resp.json()["detail"]

def test_passenger_role_boundaries():
    """Passenger should NOT be allowed to access driver or authority endpoints."""
    headers = get_headers("PASSENGER", email="passenger@bussense.ai")

    # Passenger trying to access conductor ticket validation -> 403
    resp_val = client.post("/api/tickets/validate", headers=headers, json={
        "qr_code_hash": "dummy_hash",
        "bus_number": "205"
    })
    assert resp_val.status_code == 403
    assert "Access denied" in resp_val.json()["detail"]

    # Passenger trying to access authority command overview -> 403
    resp_cmd = client.get("/api/analytics/command-overview", headers=headers)
    assert resp_cmd.status_code == 403
    assert "Access denied" in resp_cmd.json()["detail"]

    # Passenger trying to create corridor -> 403
    resp_route = client.post("/api/routes", headers=headers, json={
        "route_number": "999",
        "route_name": "Unauthorized Route",
        "origin": "A",
        "destination": "B",
        "total_stops": 5,
        "corridor_type": "SECONDARY",
        "base_fare": 20.0
    })
    assert resp_route.status_code == 403

def test_driver_conductor_role_boundaries():
    """Driver/Conductor can validate tickets, but cannot resolve incidents or access authority command."""
    driver_headers = get_headers("DRIVER_CONDUCTOR", email="driver@bussense.ai")

    # Conductor can reach validate endpoint (even if ticket not found, it won't be 403)
    resp_val = client.post("/api/tickets/validate", headers=driver_headers, json={
        "qr_code_hash": "non_existent_qr",
        "bus_number": "205"
    })
    assert resp_val.status_code in [200, 404]

    # Driver cannot resolve incidents -> 403
    resp_resolve = client.post("/api/incidents/inc-test-1/resolve", headers=driver_headers, json={
        "resolution_notes": "Driver trying to resolve"
    })
    assert resp_resolve.status_code == 403

    # Driver cannot view authority command overview -> 403
    resp_cmd = client.get("/api/analytics/command-overview", headers=driver_headers)
    assert resp_cmd.status_code == 403

def test_authority_role_access():
    """Authority role can access authority endpoints successfully."""
    auth_headers = get_headers("AUTHORITY", email="authority@bussense.ai")

    resp_cmd = client.get("/api/analytics/command-overview", headers=auth_headers)
    assert resp_cmd.status_code == 200
    assert resp_cmd.json()["success"] is True

    resp_queue = client.get("/api/analytics/ai-decision-queue", headers=auth_headers)
    assert resp_queue.status_code == 200

    resp_reports = client.get("/api/analytics/reports", headers=auth_headers)
    assert resp_reports.status_code == 200

def test_logout_and_token_revocation():
    """After logout, token is revoked and subsequent requests fail with 401."""
    # Obtain a fresh token via dev login
    login_resp = client.post("/api/auth/login", json={
        "email": "rahul.nair@bussense.kerala.gov.in",
        "password": "demo1234"
    })
    assert login_resp.status_code == 200
    token = login_resp.json()["data"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Before logout: user can access /api/auth/me
    resp_before = client.get("/api/auth/me", headers=headers)
    assert resp_before.status_code == 200
    assert resp_before.json()["data"]["email"] == "rahul.nair@bussense.kerala.gov.in"

    # Logout
    logout_resp = client.post("/api/auth/logout", headers=headers)
    assert logout_resp.status_code == 200
    assert logout_resp.json()["success"] is True

    # After logout: token must be rejected with 401
    resp_after = client.get("/api/auth/me", headers=headers)
    assert resp_after.status_code == 401
    assert "revoked" in resp_after.json()["detail"].lower()
