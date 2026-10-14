"""
BusSense AI - Phase H3 Automated API Contract & Consistency Test Suite
Verifies all newly completed endpoints:
1. Trips API: GET /api/trips, GET /api/trips/{trip_id}, authentication & 404 handling.
2. Locations API: GET /api/locations, GET /api/locations/{bus_identifier}, 404 handling.
3. Crowd API: GET /api/crowd, GET /api/crowd/{bus_identifier}, standard threshold mapping.
4. Predictions API: GET /api/predictions, GET /api/predictions/{bus_number}, 4-horizon calculations.
5. Occupancy Predictions Compatibility: GET /api/occupancy/predictions.
6. Alerts API: GET /api/alerts, GET /api/alerts/active, GET /api/alerts/{id}.
7. Payments API: GET /api/payments/my, GET /api/payments audit with strict RBAC enforcement.
"""
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token

client = TestClient(app)

def get_headers(role: str, user_id: str = "33333333-3333-3333-3333-333333333333", email: str = "test@bussense.ai"):
    token = create_access_token({
        "sub": user_id,
        "email": email,
        "role": role,
        "full_name": f"Test {role}"
    })
    return {"Authorization": f"Bearer {token}"}

def test_trips_endpoints_and_rbac():
    """Verify Trips API list, detail, authentication requirement, and 404 handling."""
    # 1. Unauthenticated request must return 401
    resp_unauth = client.get("/api/trips")
    assert resp_unauth.status_code == 401, f"Expected 401 for unauthenticated /api/trips, got {resp_unauth.status_code}"
    assert "detail" in resp_unauth.json()

    # 2. Authenticated passenger request must succeed
    p_headers = get_headers("PASSENGER")
    resp_list = client.get("/api/trips", headers=p_headers)
    assert resp_list.status_code == 200
    data = resp_list.json().get("data", [])
    assert isinstance(data, list)
    assert len(data) > 0, "Expected at least one active corridor trip"
    
    trip0 = data[0]
    assert "trip_id" in trip0
    assert "bus_number" in trip0
    assert "current_status" in trip0
    assert "occupancy_pct" in trip0
    assert "crowd_level" in trip0
    assert trip0["data_origin"] == "SIMULATED DATA"


    # 3. Retrieve specific trip by trip_id
    valid_trip_id = trip0["trip_id"]
    resp_detail = client.get(f"/api/trips/{valid_trip_id}", headers=p_headers)
    assert resp_detail.status_code == 200
    detail_data = resp_detail.json().get("data", {})
    assert detail_data["trip_id"] == valid_trip_id

    # 4. Non-existent trip must return 404
    resp_404 = client.get("/api/trips/non-existent-trip-id-9999", headers=p_headers)
    assert resp_404.status_code == 404
    assert "detail" in resp_404.json()

def test_locations_endpoints():
    """Verify Locations API returns GPS coordinates, speed, heading, and 404 for invalid bus."""
    # 1. List all vehicle locations
    resp = client.get("/api/locations")
    assert resp.status_code == 200
    locations = resp.json().get("data", [])
    assert isinstance(locations, list)
    assert len(locations) >= 2, "Expected multiple active buses"

    loc0 = locations[0]
    assert "bus_id" in loc0
    assert "bus_number" in loc0
    assert "latitude" in loc0
    assert "longitude" in loc0
    assert loc0["data_origin"] == "SIMULATED DATA"


    # 2. Get specific location by bus number (205)
    resp_205 = client.get("/api/locations/205")
    assert resp_205.status_code == 200
    b205 = resp_205.json().get("data", {})
    assert b205["bus_number"] == "205"
    assert isinstance(b205["latitude"], float)
    assert isinstance(b205["longitude"], float)

    # 3. Non-existent bus location must return 404
    resp_404 = client.get("/api/locations/UNKNOWN_BUS_9999")
    assert resp_404.status_code == 404
    assert "detail" in resp_404.json()

def test_crowd_endpoints_and_thresholds():
    """Verify Crowd API returns standardized occupancy load and respect established thresholds."""
    # 1. List fleet crowd levels
    resp = client.get("/api/crowd")
    assert resp.status_code == 200
    crowd_list = resp.json().get("data", [])
    assert len(crowd_list) > 0

    c0 = crowd_list[0]
    assert "occupancy_pct" in c0
    assert "passenger_count" in c0
    assert "capacity" in c0
    assert c0["crowd_level"] in ["LOW", "MODERATE", "CROWDED"]
    assert c0["privacy_standard"] == "PERSON_COUNTING_ONLY_NO_FACIAL_RECOGNITION"

    # 2. Query specific bus crowd by bus_number
    resp_crowd_205 = client.get("/api/crowd/205")
    assert resp_crowd_205.status_code == 200
    data_205 = resp_crowd_205.json().get("data", {})
    assert data_205["bus_number"] == "205"

    # 3. Non-existent bus crowd returns 404
    resp_404 = client.get("/api/crowd/INVALID_BUS_999")
    assert resp_404.status_code == 404

def test_predictions_endpoints():
    """Verify Predictions API, route trajectories, and frontend compatibility format."""
    # 1. Fleet predictions summary
    resp = client.get("/api/predictions")
    assert resp.status_code == 200
    preds = resp.json().get("data", [])
    assert len(preds) > 0
    p0 = preds[0]
    assert "bus_number" in p0
    assert "horizon" in p0
    assert "now" in p0["horizon"]
    assert "plus_15m" in p0["horizon"]
    assert "plus_30m" in p0["horizon"]
    assert "plus_60m" in p0["horizon"]
    assert p0["data_origin"] == "PREDICTION"

    # 2. Specific bus prediction trajectory (4 points: NOW, +15 MIN, +30 MIN, +60 MIN)
    resp_205 = client.get("/api/predictions/205")
    assert resp_205.status_code == 200
    points = resp_205.json().get("data", [])
    assert len(points) == 4
    offsets = [p["time_offset"] for p in points]
    assert offsets == ["NOW", "+15 MIN", "+30 MIN", "+60 MIN"]

    # 3. Frontend compatibility endpoint GET /api/occupancy/predictions
    resp_compat = client.get("/api/occupancy/predictions?bus_number=205")
    assert resp_compat.status_code == 200
    compat_data = resp_compat.json().get("data", {})
    assert "now" in compat_data
    assert "plus_15m" in compat_data
    assert "plus_30m" in compat_data
    assert "plus_60m" in compat_data
    assert "occupancy_pct" in compat_data["now"]
    assert "crowd_level" in compat_data["now"]

    # 4. Unknown bus prediction returns 404
    resp_404 = client.get("/api/predictions/UNKNOWN_ROUTE_8888")
    assert resp_404.status_code == 404

def test_alerts_endpoints():
    """Verify Alerts API standardized under /api/alerts and /api/alerts/active."""
    # 1. List alerts
    resp = client.get("/api/alerts")
    assert resp.status_code == 200
    alerts = resp.json().get("data", [])
    assert isinstance(alerts, list)

    # 2. Active alerts alias
    resp_active = client.get("/api/alerts/active")
    assert resp_active.status_code == 200
    assert isinstance(resp_active.json().get("data", []), list)

    # 3. Non-existent alert returns 404
    resp_404 = client.get("/api/alerts/00000000-0000-0000-0000-000000009999")
    assert resp_404.status_code == 404

def test_payments_endpoints_and_rbac():
    """Verify Payments API multi-tenant user access and authority ledger RBAC boundaries."""
    # 1. Unauthenticated request to /api/payments/my returns 401
    resp_unauth = client.get("/api/payments/my")
    assert resp_unauth.status_code == 401

    # 2. Authenticated passenger access to /api/payments/my returns 200
    p_headers = get_headers("PASSENGER")
    resp_my = client.get("/api/payments/my", headers=p_headers)
    assert resp_my.status_code == 200
    assert isinstance(resp_my.json().get("data", []), list)

    # 3. Commuter trying to access full authority payments audit returns 403 Forbidden
    resp_p_forbidden = client.get("/api/payments", headers=p_headers)
    assert resp_p_forbidden.status_code == 403
    assert "access denied" in resp_p_forbidden.json().get("detail", "").lower()


    # 4. Driver trying to access payments audit returns 403 Forbidden
    d_headers = get_headers("DRIVER_CONDUCTOR")
    resp_d_forbidden = client.get("/api/payments", headers=d_headers)
    assert resp_d_forbidden.status_code == 403

    # 5. Transport Authority access to payments audit returns 200
    a_headers = get_headers("AUTHORITY")
    resp_auth_audit = client.get("/api/payments", headers=a_headers)
    assert resp_auth_audit.status_code == 200
    payments_list = resp_auth_audit.json().get("data", [])
    assert isinstance(payments_list, list)
    if payments_list:
        p0 = payments_list[0]
        assert "amount" in p0
        assert "currency" in p0
        assert "status" in p0
        assert p0["provider"] == "SANDBOX"
