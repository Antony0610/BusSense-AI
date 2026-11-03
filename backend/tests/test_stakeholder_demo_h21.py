"""
BusSense AI - Phase H21 Stakeholder Demonstration Test Suite
Automates and validates the complete 11-step end-to-end demonstration workflow:
1. Commuter browses active transit corridors (GET /api/routes)
2. Commuter discovers origin/destination stops (GET /api/stops)
3. Commuter checks corridor fleet status (GET /api/buses)
4. Commuter queries live crowd and occupancy levels (GET /api/crowd)
5. Commuter requests multi-factor journey recommendation (POST /api/recommendations/plan)
6. Commuter books digital ticket on chosen service (POST /api/tickets/book)
7. Commuter views digital ticket & QR validation token (GET /api/tickets/my)
8. Conductor cockpit atomically validates boarding pass (POST /api/tickets/validate)
9. Automated CCTV headcount stream updates bus occupancy (POST /api/ingest/cctv-occupancy)
10. Transit Authority Dashboard tracks pilot fleet & provider status (GET /api/ingest/pilot-monitor)
11. Transit Authority reviews 4-horizon demand forecasts (GET /api/predictions)
12. Full end-to-end integrated stakeholder demonstration run
"""
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import pytest
from datetime import datetime, timezone
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token

client = TestClient(app)

def get_auth_headers(role: str, user_id: str = "33333333-3333-3333-3333-333333333333", email: str = "demo@bussense.ai"):
    token = create_access_token({
        "sub": user_id,
        "email": email,
        "role": role,
        "full_name": f"Demo {role}"
    })
    return {"Authorization": f"Bearer {token}"}


# Step 1: Commuter route discovery
def test_demo_step01_commuter_routes_lookup():
    p_headers = get_auth_headers("PASSENGER")
    resp = client.get("/api/routes", headers=p_headers)
    assert resp.status_code == 200, f"Expected 200, got {resp.status_code}"
    body = resp.json()
    routes = body.get("data", [])
    assert isinstance(routes, list)
    assert len(routes) >= 2, "Expected at least 2 primary corridors (e.g. Route 205 & 14A)"
    route_numbers = [r.get("route_number") for r in routes]
    assert "205" in route_numbers or "14A" in route_numbers


# Step 2: Commuter stop lookup
def test_demo_step02_commuter_stops_lookup():
    p_headers = get_auth_headers("PASSENGER")
    resp = client.get("/api/stops", headers=p_headers)
    assert resp.status_code == 200
    body = resp.json()
    stops = body.get("data", [])
    assert isinstance(stops, list)
    assert len(stops) >= 5, "Expected corridor stops available for Greater Kochi"
    stop_names = [s.get("stop_name", "") for s in stops]
    assert any("Aluva" in name or "Vyttila" in name or "Kaloor" in name or "Edappally" in name for name in stop_names)


# Step 3: Active fleet status
def test_demo_step03_active_fleet_status():
    p_headers = get_auth_headers("PASSENGER")
    resp = client.get("/api/buses", headers=p_headers)
    assert resp.status_code == 200
    body = resp.json()
    buses = body.get("data", [])
    assert isinstance(buses, list)
    assert len(buses) >= 1
    bus0 = buses[0]
    assert "bus_number" in bus0
    assert "capacity" in bus0 or "current_occupancy" in bus0


# Step 4: Real-time crowd levels
def test_demo_step04_realtime_occupancy_and_crowd():
    p_headers = get_auth_headers("PASSENGER")
    resp = client.get("/api/crowd", headers=p_headers)
    assert resp.status_code == 200
    body = resp.json()
    crowd_list = body.get("data", [])
    assert isinstance(crowd_list, list)
    assert len(crowd_list) >= 1
    item = crowd_list[0]
    assert "crowd_level" in item
    assert item["crowd_level"] in ["LOW", "MODERATE", "PACKED", "STANDING_ONLY", "CRITICAL", "CROWDED"]
    assert "occupancy_pct" in item


# Step 5: Commuter recommendation engine planning
def test_demo_step05_recommendation_journey_planning():
    p_headers = get_auth_headers("PASSENGER")
    plan_payload = {
        "origin": "Kaloor Metro Station, Kochi",
        "destination": "Vyttila Mobility Hub",
        "preference": "balanced"
    }
    resp = client.post("/api/recommendations/plan", json=plan_payload, headers=p_headers)
    assert resp.status_code == 200
    body = resp.json()
    rec = body.get("data", {})
    assert "origin_stop" in rec or "origin" in rec
    assert "recommended_bus" in rec
    assert rec["recommended_bus"] is not None
    assert "explanation" in rec


# Step 6: Commuter ticket booking
def test_demo_step06_ticket_booking():
    p_headers = get_auth_headers("PASSENGER")
    booking_payload = {
        "bus_number": "205",
        "route_number": "205",
        "origin_stop": "Kaloor Metro Station",
        "destination_stop": "Vyttila Mobility Hub",
        "passenger_name": "Demo Commuter",
        "fare_amount": 25.0
    }
    resp = client.post("/api/tickets/book", json=booking_payload, headers=p_headers)
    assert resp.status_code == 200
    body = resp.json()
    ticket = body.get("data", {})
    assert "ticket_id" in ticket or "qr_code_hash" in ticket
    assert ticket.get("status") == "VALID"
    assert "qr_code_data_uri" in ticket


# Step 7: Commuter views active tickets with QR data
def test_demo_step07_ticket_qr_and_my_tickets():
    p_headers = get_auth_headers("PASSENGER")
    resp = client.get("/api/tickets/my", headers=p_headers)
    assert resp.status_code == 200
    body = resp.json()
    tickets = body.get("data", [])
    assert isinstance(tickets, list)
    assert len(tickets) >= 1
    t0 = tickets[0]
    assert "qr_code_hash" in t0 or "ticket_id" in t0


# Step 8: Conductor validates boarding pass atomically
def test_demo_step08_conductor_atomic_ticket_validation():
    p_headers = get_auth_headers("PASSENGER")
    c_headers = get_auth_headers("DRIVER_CONDUCTOR")

    # Book a fresh ticket to validate
    booking_payload = {
        "bus_number": "205",
        "route_number": "205",
        "origin_stop": "Kaloor Metro Station",
        "destination_stop": "Palarivattom",
        "passenger_name": "Validation Passenger",
        "fare_amount": 15.0
    }
    book_resp = client.post("/api/tickets/book", json=booking_payload, headers=p_headers)
    assert book_resp.status_code == 200
    ticket = book_resp.json().get("data", {})
    qr_hash = ticket["qr_code_hash"]

    # Conductor validates ticket (first scan -> VALID)
    val_payload = {
        "qr_code_hash": qr_hash,
        "bus_number": "205"
    }
    val_resp = client.post("/api/tickets/validate", json=val_payload, headers=c_headers)
    assert val_resp.status_code == 200
    val_data = val_resp.json().get("data", {})
    assert val_data.get("result") == "VALID"

    # Conductor validates ticket second time -> ALREADY_USED
    val_resp2 = client.post("/api/tickets/validate", json=val_payload, headers=c_headers)
    assert val_resp2.status_code == 200
    val_data2 = val_resp2.json().get("data", {})
    assert val_data2.get("result") == "ALREADY_USED"


# Step 9: Ingest CCTV occupancy headcount record
def test_demo_step09_cctv_occupancy_ingestion():
    a_headers = get_auth_headers("AUTHORITY")
    cctv_payload = {
        "bus_number": "205",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "raw_person_count": 32,
        "stabilized_person_count": 30,
        "capacity": 45,
        "confidence_score": 0.89,
        "model_version": "yolov8n-headcount-v2.1",
        "camera_id": "CAM-KOCHI-205-01",
        "privacy_standard": "PERSON_COUNTING_ONLY_NO_BIOMETRICS",
        "data_origin": "CV REPLAY"
    }
    resp = client.post("/api/ingest/cctv-occupancy", json=cctv_payload, headers=a_headers)
    assert resp.status_code == 200
    body = resp.json()
    data = body.get("data", {})
    assert data.get("accepted") >= 1


# Step 10: Transit Authority pilot monitoring & provider status
def test_demo_step10_authority_pilot_monitoring():
    a_headers = get_auth_headers("AUTHORITY")
    resp = client.get("/api/ingest/pilot-monitor", headers=a_headers)
    assert resp.status_code == 200
    body = resp.json()
    mon = body.get("data", {})
    assert "total_active_vehicles" in mon
    assert "connected_vehicles_count" in mon
    assert "freshness_ratio_pct" in mon
    assert mon.get("privacy_standard") == "PERSON_COUNTING_ONLY_NO_BIOMETRICS"


# Step 11: Multi-horizon demand predictions
def test_demo_step11_multi_horizon_demand_predictions():
    p_headers = get_auth_headers("PASSENGER")
    resp = client.get("/api/predictions", headers=p_headers)
    assert resp.status_code == 200
    body = resp.json()
    preds = body.get("data", [])
    assert isinstance(preds, list)
    assert len(preds) >= 1
    pred0 = preds[0]
    assert "bus_number" in pred0
    assert "horizon" in pred0 or "predictions" in pred0 or "forecasts" in pred0


# Step 12: Integrated end-to-end demonstration flow
def test_demo_step12_integrated_stakeholder_workflow():
    """
    Executes all demonstration actions in continuous sequence simulating
    a live stakeholder evaluation session before transport commissioners.
    """
    p_headers = get_auth_headers("PASSENGER")
    c_headers = get_auth_headers("DRIVER_CONDUCTOR")
    a_headers = get_auth_headers("AUTHORITY")

    # 1. Commuter discovers network
    routes = client.get("/api/routes", headers=p_headers).json().get("data", [])
    assert len(routes) > 0

    # 2. Commuter queries journey advice
    plan = client.post("/api/recommendations/plan", json={
        "origin": "Kaloor Metro Station, Kochi",
        "destination": "Vyttila Mobility Hub",
        "preference": "balanced"
    }, headers=p_headers).json().get("data", {})
    assert plan.get("recommended_bus") is not None

    # 3. Commuter books digital ticket
    ticket = client.post("/api/tickets/book", json={
        "bus_number": "205",
        "route_number": "205",
        "origin_stop": "Kaloor Metro Station",
        "destination_stop": "Vyttila Mobility Hub",
        "passenger_name": "Stakeholder VIP Commuter",
        "fare_amount": 25.0
    }, headers=p_headers).json().get("data", {})
    qr_hash = ticket["qr_code_hash"]

    # 4. Conductor verifies boarding
    val = client.post("/api/tickets/validate", json={
        "qr_code_hash": qr_hash,
        "bus_number": "205"
    }, headers=c_headers).json().get("data", {})
    assert val.get("result") == "VALID"

    # 5. Telemetry update received
    cctv = client.post("/api/ingest/cctv-occupancy", json={
        "bus_number": "205",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "raw_person_count": 28,
        "stabilized_person_count": 27,
        "capacity": 45,
        "confidence_score": 0.91,
        "model_version": "yolov8n-headcount-v2.1",
        "camera_id": "CAM-KOCHI-205-01",
        "privacy_standard": "PERSON_COUNTING_ONLY_NO_BIOMETRICS",
        "data_origin": "CV REPLAY"
    }, headers=a_headers).json().get("data", {})
    assert cctv.get("accepted") >= 1

    # 6. Authority cockpit confirms real-time health
    monitor = client.get("/api/ingest/pilot-monitor", headers=a_headers).json().get("data", {})
    assert monitor.get("privacy_standard") == "PERSON_COUNTING_ONLY_NO_BIOMETRICS"
    assert monitor.get("total_active_vehicles") >= 1
