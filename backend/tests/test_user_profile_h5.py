import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token

client = TestClient(app)

@pytest.fixture
def passenger_auth_headers():
    token = create_access_token({
        "sub": "a1111111-1111-1111-1111-111111111111",
        "email": "commuter@bussense.ai",
        "role": "PASSENGER",
        "full_name": "Ananya Sharma"
    })
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def secondary_commuter_headers():
    token = create_access_token({
        "sub": "b2222222-2222-2222-2222-222222222222",
        "email": "secondary@bussense.ai",
        "role": "PASSENGER",
        "full_name": "Rahul Verma"
    })
    return {"Authorization": f"Bearer {token}"}

def test_user_profile_unauthenticated_rejected():
    """Unauthenticated access to profile is strictly rejected with 401."""
    resp = client.get("/api/user/profile")
    assert resp.status_code == 401

def test_get_passenger_profile(passenger_auth_headers):
    """Authenticated commuter can retrieve their profile."""
    resp = client.get("/api/user/profile", headers=passenger_auth_headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["email"] == "commuter@bussense.ai"
    assert "full_name" in data
    assert data["role"] == "PASSENGER"
    assert data["account_status"] == "ACTIVE"

def test_update_passenger_profile(passenger_auth_headers):
    """Commuter can update their full name and preferred language."""
    resp = client.patch(
        "/api/user/profile",
        headers=passenger_auth_headers,
        json={"full_name": "Ananya S. Nair", "preferred_language": "ml"}
    )
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["full_name"] == "Ananya S. Nair"
    assert data["preferred_language"] == "ml"

def test_saved_places_lifecycle(passenger_auth_headers):
    """Commuter can list, add, and delete saved favorite destinations."""
    # 1. Get initial saved places
    resp = client.get("/api/user/favorites", headers=passenger_auth_headers)
    assert resp.status_code == 200
    initial_count = len(resp.json()["data"])

    # 2. Add a new saved place
    add_resp = client.post(
        "/api/user/favorites",
        headers=passenger_auth_headers,
        json={
            "label": "Campus",
            "item_type": "DESTINATION",
            "reference_id": "CUSAT Metro Stand",
            "address": "South Kalamassery, Kochi"
        }
    )
    assert add_resp.status_code == 201
    created_place = add_resp.json()["data"]
    assert created_place["label"] == "Campus"
    assert created_place["reference_id"] == "CUSAT Metro Stand"
    place_id = created_place["id"]

    # 3. Verify place exists in list
    list_resp = client.get("/api/user/favorites", headers=passenger_auth_headers)
    assert len(list_resp.json()["data"]) == initial_count + 1

    # 4. Delete the place
    del_resp = client.delete(f"/api/user/favorites/{place_id}", headers=passenger_auth_headers)
    assert del_resp.status_code == 200
    assert del_resp.json()["data"]["deleted"] is True

def test_user_preferences_lifecycle(passenger_auth_headers):
    """Commuter can fetch and update their notification and appearance preferences."""
    # 1. Get preferences
    resp = client.get("/api/user/preferences", headers=passenger_auth_headers)
    assert resp.status_code == 200
    prefs = resp.json()["data"]
    assert "master_notifications" in prefs
    assert "bus_arrival" in prefs

    # 2. Update preferences
    update_resp = client.put(
        "/api/user/preferences",
        headers=passenger_auth_headers,
        json={
            "master_notifications": True,
            "bus_arrival": True,
            "journey_updates": False,
            "crowd_alerts": True,
            "service_alerts": True,
            "ticket_updates": True,
            "language": "ml",
            "theme_mode": "dark"
        }
    )
    assert update_resp.status_code == 200
    updated = update_resp.json()["data"]
    assert updated["journey_updates"] is False
    assert updated["language"] == "ml"
    assert updated["theme_mode"] == "dark"

def test_passenger_report_submission(passenger_auth_headers):
    """Commuter can submit an issue report and receive a tracked reference ID."""
    resp = client.post(
        "/api/user/reports",
        headers=passenger_auth_headers,
        json={
            "category": "BUS_VEHICLE",
            "title": "Air conditioning weak on Bus 205",
            "description": "Cabin temperature warm during afternoon peak run.",
            "bus_number": "205",
            "route_number": "12"
        }
    )
    assert resp.status_code == 201
    data = resp.json()["data"]
    assert data["id"].startswith("REP-KL-")
    assert data["category"] == "BUS_VEHICLE"
    assert data["status"] == "REPORTED"

def test_export_passenger_data(passenger_auth_headers):
    """Commuter can request a structured export of their account data."""
    resp = client.get("/api/user/export-data", headers=passenger_auth_headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert "profile" in data
    assert "saved_places" in data
    assert "preferences" in data
    assert "ticket_summary" in data
    assert data["truth_label"] == "PROTOTYPE DATA EXPORT"

def test_deactivate_passenger_account(passenger_auth_headers):
    """Deactivation without confirmation fails; with confirmation succeeds."""
    # 1. Without confirmation: rejected 400
    fail_resp = client.post(
        "/api/user/deactivate",
        headers=passenger_auth_headers,
        json={"confirm": False}
    )
    assert fail_resp.status_code == 400

    # 2. With confirmation: succeeds
    ok_resp = client.post(
        "/api/user/deactivate",
        headers=passenger_auth_headers,
        json={"confirm": True}
    )
    assert ok_resp.status_code == 200
    assert ok_resp.json()["data"]["deactivated"] is True
