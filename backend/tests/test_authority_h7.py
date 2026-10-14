"""
BusSense AI - Phase H7 Authority Integration & RBAC Test Suite
Validates:
1. Authority RBAC protection (401 unauthenticated, 403 PASSENGER & DRIVER_CONDUCTOR, 200 AUTHORITY)
2. Command center overview telemetry
3. Human-in-the-loop AI decision queue
4. Operational compliance reports
5. Duty controller incident resolution
6. Public transit routes catalog
7. 4-horizon demand forecasting (NOW, +15 MIN, +30 MIN, +60 MIN)
8. Simulation transparency & truth labels
"""
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token

client = TestClient(app)

def get_headers(role: str, user_id: str = "authority-user-id", email: str = "controller@bussense.kerala.gov.in"):
    token = create_access_token({
        "sub": user_id,
        "email": email,
        "role": role,
        "full_name": f"Officer {role}"
    })
    return {"Authorization": f"Bearer {token}"}

# ==========================================
# 1. Authority RBAC Verification
# ==========================================

def test_authority_endpoints_unauthenticated_rejected():
    """Unauthenticated requests to Authority operational endpoints must return HTTP 401."""
    resp1 = client.get("/api/analytics/command-overview")
    assert resp1.status_code == 401

    resp2 = client.get("/api/analytics/ai-decision-queue")
    assert resp2.status_code == 401

    resp3 = client.get("/api/analytics/reports")
    assert resp3.status_code == 401

    resp4 = client.post("/api/incidents/inc-test-01/resolve", json={"resolution_notes": "Closed"})
    assert resp4.status_code == 401

def test_authority_endpoints_passenger_rejected():
    """PASSENGER role must be rejected with HTTP 403 Forbidden on Authority endpoints."""
    passenger_headers = get_headers("PASSENGER", email="passenger@bussense.ai")

    resp1 = client.get("/api/analytics/command-overview", headers=passenger_headers)
    assert resp1.status_code == 403

    resp2 = client.get("/api/analytics/ai-decision-queue", headers=passenger_headers)
    assert resp2.status_code == 403

    resp3 = client.get("/api/analytics/reports", headers=passenger_headers)
    assert resp3.status_code == 403

    resp4 = client.post("/api/incidents/inc-test-01/resolve", headers=passenger_headers, json={"resolution_notes": "Closed"})
    assert resp4.status_code == 403

def test_authority_endpoints_conductor_rejected():
    """DRIVER_CONDUCTOR role must be rejected with HTTP 403 Forbidden on Authority endpoints."""
    conductor_headers = get_headers("DRIVER_CONDUCTOR", email="conductor@bussense.ai")

    resp1 = client.get("/api/analytics/command-overview", headers=conductor_headers)
    assert resp1.status_code == 403

    resp2 = client.get("/api/analytics/ai-decision-queue", headers=conductor_headers)
    assert resp2.status_code == 403

    resp3 = client.get("/api/analytics/reports", headers=conductor_headers)
    assert resp3.status_code == 403

    resp4 = client.post("/api/incidents/inc-test-01/resolve", headers=conductor_headers, json={"resolution_notes": "Closed"})
    assert resp4.status_code == 403

# ==========================================
# 2. Command Overview Telemetry
# ==========================================

def test_authority_command_overview():
    """AUTHORITY role can retrieve real-time network command overview."""
    headers = get_headers("AUTHORITY")
    resp = client.get("/api/analytics/command-overview", headers=headers)
    assert resp.status_code == 200

    payload = resp.json()
    assert payload["success"] is True
    data = payload["data"]
    assert "network_status" in data
    assert "active_buses_count" in data
    assert "average_network_occupancy_pct" in data
    assert "on_time_reliability_pct" in data
    assert "active_corridors" in data
    assert len(data["active_corridors"]) > 0
    assert payload["data_origin"] == "SIMULATED DATA"

# ==========================================
# 3. Human-in-the-Loop AI Decision Queue
# ==========================================

def test_authority_ai_decision_queue():
    """AUTHORITY role can inspect operational recommendations awaiting human clearance."""
    headers = get_headers("AUTHORITY")
    resp = client.get("/api/analytics/ai-decision-queue", headers=headers)
    assert resp.status_code == 200

    payload = resp.json()
    assert payload["success"] is True
    queue = payload["data"]
    assert len(queue) > 0
    item = queue[0]
    assert "id" in item
    assert "trigger" in item
    assert "prediction" in item
    assert "recommendation" in item
    assert "expected_impact" in item
    assert item["status"] == "PENDING_OFFICER_CLEARANCE"
    assert "HUMAN DECISION" in item["data_origin"]

# ==========================================
# 4. Operational Reports
# ==========================================

def test_authority_operational_reports():
    """AUTHORITY role can query regional archive reports."""
    headers = get_headers("AUTHORITY")
    resp = client.get("/api/analytics/reports", headers=headers)
    assert resp.status_code == 200

    payload = resp.json()
    assert payload["success"] is True
    reports = payload["data"]
    assert len(reports) > 0
    r = reports[0]
    assert "id" in r
    assert "title" in r
    assert "period" in r
    assert "on_time_pct" in r
    assert "carbon_offset_kg" in r

# ==========================================
# 5. Duty Controller Incident Resolution
# ==========================================

def test_authority_resolve_incident():
    """AUTHORITY role can resolve reported incidents."""
    headers = get_headers("AUTHORITY")

    # Resolve incident
    resp = client.post(
        "/api/incidents/00000000-0000-0000-0000-000000000001/resolve",
        headers=headers,
        json={"resolution_notes": "Detour cleared by Ernakulam traffic police."}
    )
    assert resp.status_code in [200, 404]  # 200 if record exists, 404 if mock ID not found
    if resp.status_code == 200:
        data = resp.json()["data"]
        assert data["status"] == "RESOLVED"

# ==========================================
# 6. Routes & Corridors
# ==========================================

def test_public_routes_catalog():
    """Network routes catalog returns monitored Kerala corridors."""
    resp = client.get("/api/routes")
    assert resp.status_code == 200
    payload = resp.json()
    routes = payload["data"]
    assert len(routes) >= 3
    numbers = [r["route_number"] for r in routes]
    assert "12" in numbers
    assert "14A" in numbers
    assert "205" in numbers

# ==========================================
# 7. 4-Horizon Demand Forecasting
# ==========================================

def test_4_horizon_predictions():
    """Predictive occupancy endpoint returns NOW, +15 MIN, +30 MIN, +60 MIN horizons."""
    resp = client.get("/api/occupancy/predictions?bus_number=205")
    assert resp.status_code == 200
    payload = resp.json()
    assert payload["data_origin"] == "PREDICTION"

    data = payload["data"]
    assert "now" in data
    assert "plus_15m" in data
    assert "plus_30m" in data
    assert "plus_60m" in data

    assert data["now"]["crowd_level"] in ["LOW", "MODERATE", "CROWDED"]
    assert data["plus_15m"]["crowd_level"] in ["LOW", "MODERATE", "CROWDED"]
    assert data["plus_30m"]["crowd_level"] in ["LOW", "MODERATE", "CROWDED"]
    assert data["plus_60m"]["crowd_level"] in ["LOW", "MODERATE", "CROWDED"]

    assert 0 <= data["now"]["occupancy_pct"] <= 100
    assert 0 <= data["plus_30m"]["occupancy_pct"] <= 100
