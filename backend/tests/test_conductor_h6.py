import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token

client = TestClient(app)

def get_headers(role: str, user_id: str = "driver-user-id", email: str = "driver@bussense.ai"):
    token = create_access_token({
        "sub": user_id,
        "email": email,
        "role": role,
        "full_name": f"Test {role}"
    })
    return {"Authorization": f"Bearer {token}"}

def test_conductor_endpoints_unauthenticated_rejected():
    """Unauthenticated access to conductor endpoints must return 401."""
    resp = client.get("/api/conductor/shift")
    assert resp.status_code == 401

    resp_checkin = client.post("/api/conductor/check-in", json={"duty_id": "DUTY-TEST-1"})
    assert resp_checkin.status_code == 401

    resp_pair = client.post("/api/conductor/pair", json={"bus_number": "205", "route_number": "12"})
    assert resp_pair.status_code == 401

    resp_start = client.post("/api/conductor/trips/start", json={"trip_id": "trip-test-1"})
    assert resp_start.status_code == 401

    resp_complete = client.post("/api/conductor/trips/complete", json={"trip_id": "trip-test-1"})
    assert resp_complete.status_code == 401

def test_conductor_endpoints_passenger_rejected():
    """PASSENGER role must be rejected with 403 Forbidden on conductor endpoints."""
    passenger_headers = get_headers("PASSENGER", email="passenger@bussense.ai")

    resp = client.get("/api/conductor/shift", headers=passenger_headers)
    assert resp.status_code == 403

    resp_pair = client.post("/api/conductor/pair", headers=passenger_headers, json={"bus_number": "205", "route_number": "12"})
    assert resp_pair.status_code == 403

def test_conductor_shift_retrieval_and_check_in():
    """DRIVER_CONDUCTOR can retrieve shift state and check in for duty."""
    headers = get_headers("DRIVER_CONDUCTOR", user_id="cond-101", email="suresh.kumar@bussense.kerala.gov.in")

    # 1. Retrieve initial shift
    resp = client.get("/api/conductor/shift", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["role"] == "DRIVER_CONDUCTOR"
    assert "duty_id" in data
    assert data["data_origin"] == "SIMULATED DATA"

    # 2. Check in for duty
    resp_checkin = client.post("/api/conductor/check-in", headers=headers, json={"duty_id": "DUTY-KL-402"})
    assert resp_checkin.status_code == 200
    checkin_data = resp_checkin.json()["data"]
    assert checkin_data["status"] == "CHECKED_IN"
    assert checkin_data["duty_id"] == "DUTY-KL-402"

def test_conductor_bus_pairing():
    """Conductor can pair with a vehicle and route."""
    headers = get_headers("DRIVER_CONDUCTOR", user_id="cond-102", email="conductor.ernakulam@bussense.ai")

    resp_pair = client.post("/api/conductor/pair", headers=headers, json={
        "bus_number": "14A",
        "route_number": "3B",
        "trip_code": "TRIP-14A-MORNING"
    })
    assert resp_pair.status_code == 200
    paired = resp_pair.json()["data"]
    assert paired["bus_number"] == "14A"
    assert paired["route_number"] == "3B"
    assert paired["pairing_status"] == "PAIRED"
    assert paired["active_trip"] is not None
    assert paired["active_trip"]["bus_number"] == "14A"

def test_conductor_trip_lifecycle_start_and_complete():
    """Conductor can start and complete a trip with layover staging."""
    headers = get_headers("DRIVER_CONDUCTOR", user_id="cond-103", email="crew.kaloor@bussense.ai")

    # Start trip
    resp_start = client.post("/api/conductor/trips/start", headers=headers, json={
        "trip_id": "trip-sim-205"
    })
    assert resp_start.status_code == 200
    started = resp_start.json()["data"]
    assert started["active_trip"]["status"] == "ACTIVE"

    # Complete trip
    resp_complete = client.post("/api/conductor/trips/complete", headers=headers, json={
        "trip_id": "trip-sim-205"
    })
    assert resp_complete.status_code == 200
    summary = resp_complete.json()["data"]
    assert summary["status"] == "COMPLETED"
    assert summary["layover_minutes"] == 15
    assert summary["trip_duration_minutes"] > 0
    assert summary["data_origin"] == "SIMULATED DATA"

def test_authority_access_to_conductor_endpoints():
    """AUTHORITY role can access conductor endpoints (supervisor override)."""
    authority_headers = get_headers("AUTHORITY", user_id="auth-99", email="controller@bussense.ai")
    resp = client.get("/api/conductor/shift", headers=authority_headers)
    assert resp.status_code == 200
