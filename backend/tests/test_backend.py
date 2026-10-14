import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["platform"] == "BusSense AI Intelligence Platform"
    assert data["status"] == "OPERATIONAL"

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_buses_telemetry():
    response = client.get("/api/buses")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]) >= 3
    # Check bus 205 exists and is properly structured
    bus_205 = next((b for b in data["data"] if b["bus_number"] == "205"), None)
    assert bus_205 is not None
    assert bus_205["occupancy_pct"] < 50.0 # Low crowd tier
    assert bus_205["crowd_level"] == "LOW"

def test_crowd_forecasting():
    response = client.get("/api/occupancy/forecast/205")
    assert response.status_code == 200
    data = response.json()
    assert len(data["data"]) == 4 # NOW, +15 MIN, +30 MIN, +60 MIN
    assert data["data"][0]["time_offset"] == "NOW"

def test_smart_recommendations():
    response = client.get("/api/recommendations/plan?origin=Kaloor&destination=Vyttila")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["recommended_bus"]["bus_number"] == "205"
    assert data["recommended_bus"]["is_recommended"] is True
    assert "priority lane" in data["recommended_bus"]["why_recommended"].lower()

from app.core.security import create_access_token

def get_auth_headers(role: str = "PASSENGER", email: str = "test@bussense.ai", user_id: str = None):
    uid = user_id or ("11111111-1111-1111-1111-111111111111" if role == "PASSENGER" else "22222222-2222-2222-2222-222222222222")
    token = create_access_token({
        "sub": uid,
        "email": email,
        "role": role,
        "full_name": f"Test {role}"
    })
    return {"Authorization": f"Bearer {token}"}

def test_ticket_booking_and_qr_validation():
    passenger_headers = get_auth_headers("PASSENGER", "passenger@bussense.ai")
    conductor_headers = get_auth_headers("DRIVER_CONDUCTOR", "conductor@bussense.ai")

    # 1. Book a ticket as Passenger
    book_resp = client.post("/api/tickets/book", headers=passenger_headers, json={
        "bus_number": "205",
        "route_number": "205",
        "origin_stop": "Kaloor Metro Station",
        "destination_stop": "Vyttila Mobility Hub",
        "passenger_name": "Test Commuter",
        "fare_amount": 25.0
    })
    assert book_resp.status_code == 200
    ticket_data = book_resp.json()["data"]
    qr_hash = ticket_data["qr_code_hash"]
    assert ticket_data["status"] == "VALID"
    assert ticket_data["qr_code_data_uri"].startswith("data:image/png;base64,")

    # 2. Conductor Validates Ticket first time -> Should be VALID
    val_resp = client.post("/api/tickets/validate", headers=conductor_headers, json={
        "qr_code_hash": qr_hash,
        "bus_number": "205"
    })
    assert val_resp.status_code == 200
    assert val_resp.json()["data"]["result"] == "VALID"

    # 3. Second validation -> Should be ALREADY_USED
    val_resp_2 = client.post("/api/tickets/validate", headers=conductor_headers, json={
        "qr_code_hash": qr_hash,
        "bus_number": "205"
    })
    assert val_resp_2.status_code == 200
    assert val_resp_2.json()["data"]["result"] == "ALREADY_USED"

def test_rag_ai_assistant():
    passenger_headers = get_auth_headers("PASSENGER", "passenger@bussense.ai")

    # Ask why bus 205 is recommended
    chat_resp = client.post("/api/ai/chat", headers=passenger_headers, json={
        "question": "Which bus is less crowded and why was it recommended?",
        "user_location": "Kaloor Metro Station, Kochi"
    })
    assert chat_resp.status_code == 200
    ans_data = chat_resp.json()["data"]
    assert "205" in ans_data["answer"]
    assert len(ans_data["sources"]) > 0

    # Test unknown out-of-domain question fallback
    fallback_resp = client.post("/api/ai/chat", headers=passenger_headers, json={
        "question": "What is the stock price of Apple on NASDAQ?",
        "user_location": "Kaloor Metro Station, Kochi"
    })
    assert fallback_resp.status_code == 200
    assert "I don't have enough reliable information to answer that" in fallback_resp.json()["data"]["answer"]
