"""Comprehensive automated test suite for BusSense AI 2.0 FastAPI Backend & ML Engine."""
from __future__ import annotations

import sys
from pathlib import Path

# Add project root to Python path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import pytest
from fastapi.testclient import TestClient

from backend.main import app
from backend.services.demand_ml import ml_engine
from backend.services.gps_telemetry_sim import calculate_bearing, interpolate_route, KERALA_CORRIDORS
from backend.services.rebalance_ai import calculate_fleet_rebalances

client = TestClient(app)


def test_health_check_returns_healthy():
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["version"] == "2.0.0"
    assert data["ml_engine"] == "online"


def test_list_buses_returns_active_fleet():
    response = client.get("/api/buses")
    assert response.status_code == 200
    buses = response.json()
    assert len(buses) >= 9
    ksrtc_bus = next((b for b in buses if b["operator_type"] == "KSRTC"), None)
    assert ksrtc_bus is not None
    assert "occupancy_percentage" in ksrtc_bus
    assert "crowd_tier" in ksrtc_bus
    assert "speed_kmh" in ksrtc_bus
    assert "heading_deg" in ksrtc_bus


def test_list_buses_filter_by_operator():
    response = client.get("/api/buses?operator=KSRTC")
    assert response.status_code == 200
    buses = response.json()
    assert all(b["operator_type"] == "KSRTC" for b in buses)


def test_telemetry_ingestion_calculates_metrics():
    payload = {
        "bus_id": "KSRTC-101",
        "route_number": "R1",
        "latitude": 8.5255,
        "longitude": 76.9380,
        "passenger_count": 25,
        "capacity": 50,
        "speed_kmh": 42.0,
        "heading_deg": 45.0,
    }
    response = client.post(
        "/api/telemetry/ingest",
        json=payload,
        headers={"X-Edge-API-Key": "bussense_edge_secret_key_2026"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["occupancy_percentage"] == 50.0
    assert data["seat_availability"] == 25
    assert data["crowd_tier"] == "YELLOW"


def test_telemetry_ingestion_rejects_invalid_key():
    payload = {
        "bus_id": "KSRTC-101",
        "route_number": "R1",
        "latitude": 8.5255,
        "longitude": 76.9380,
        "passenger_count": 25,
    }
    response = client.post(
        "/api/telemetry/ingest",
        json=payload,
        headers={"X-Edge-API-Key": "wrong_key"},
    )
    assert response.status_code == 403


def test_smart_qr_ticket_booking_and_validation():
    # 1. Book Ticket
    book_payload = {
        "user_id": "usr-test-123",
        "bus_id": "PVT-204",  # Low occupancy bus (10/36 = 27.7%) -> 20% discount applies
        "route_number": "R4",
        "origin_stop": "Central Railway Station",
        "destination_stop": "Government Medical College",
        "seat_number": "12B",
        "base_fare": 40.0,
    }
    book_res = client.post("/api/tickets/book", json=book_payload)
    assert book_res.status_code == 201
    ticket = book_res.json()
    assert ticket["seat_number"] == "12B"
    assert ticket["discount_pct"] == 20.0
    assert ticket["final_fare"] == 32.0
    assert "qr_code_hash" in ticket
    qr_hash = ticket["qr_code_hash"]

    # 2. Validate Ticket with Conductor
    val_res = client.post("/api/tickets/validate", json={"qr_code_hash": qr_hash, "bus_id": "PVT-204"})
    assert val_res.status_code == 200
    val_data = val_res.json()
    assert val_data["valid"] is True
    assert val_data["status"] == "validated"

    # 3. Prevent Double-Scanning
    double_res = client.post("/api/tickets/validate", json={"qr_code_hash": qr_hash, "bus_id": "PVT-204"})
    assert double_res.status_code == 400


def test_emergency_sos_broadcast():
    sos_payload = {
        "user_id": "usr-test-999",
        "bus_id": "KSRTC-104",
        "route_number": "R3",
        "latitude": 8.5280,
        "longitude": 76.9420,
        "message": "Immediate Medical Support Required",
    }
    response = client.post("/api/sos/broadcast", json=sos_payload)
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "active"
    assert "sos_id" in data


def test_dispatch_relief_bus():
    dispatch_payload = {
        "route_number": "R1",
        "operator_type": "KSRTC",
        "reason": "Peak Hour Overcrowding Relief",
    }
    response = client.post("/api/dispatch", json=dispatch_payload)
    assert response.status_code == 201
    data = response.json()
    assert "bus_id" in data
    assert "KSRTC-EXTRA" in data["bus_id"]


def test_ml_demand_prediction_speed_and_format():
    result = ml_engine.predict_route("R1")
    assert result["route_number"] == "R1"
    assert len(result["predicted_hourly"]) == 24
    assert result["inference_time_ms"] < 25.0  # Must be fast sub-25ms
    assert result["model_type"] == "RandomForestRegressor"
    assert "recommended_action" in result


def test_autonomous_fleet_rebalancer():
    recommendations = calculate_fleet_rebalances()
    assert len(recommendations) >= 1
    rec = recommendations[0]
    assert "source_route" in rec
    assert "target_route" in rec
    assert "predicted_congestion_reduction_pct" in rec


def test_physics_gps_simulator_bearing_and_interpolation():
    waypoints = KERALA_CORRIDORS["R1"]
    lat, lon, speed, bearing = interpolate_route(waypoints, 0.25)
    assert 8.4 < lat < 8.7
    assert 76.8 < lon < 77.1
    assert 0.0 <= speed <= 60.0
    assert 0.0 <= bearing <= 360.0

    bearing_calc = calculate_bearing(8.5241, 76.9366, 8.5300, 76.9400)
    assert 0.0 <= bearing_calc <= 360.0
