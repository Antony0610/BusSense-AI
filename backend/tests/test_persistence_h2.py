"""
BusSense AI - Phase H2 Persistent Database Transactions Test Suite
Exercises real Supabase PostgreSQL persistence for:
1. Tickets
2. Payments
3. Ticket Validations
4. Cross-user isolation (Passenger A cannot see Passenger B's tickets)
5. Anti-reuse validation
6. Incidents reporting and resolution RBAC
7. Alerts & Reports database persistence
"""
import sys
import os
import uuid
import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from app.main import app
from app.core.security import create_access_token
from app.core.supabase import supabase_client

client = TestClient(app)

PASSENGER_A_ID = "11111111-1111-1111-1111-111111111111"
PASSENGER_B_ID = "44444444-4444-4444-4444-444444444444"
DRIVER_ID = "22222222-2222-2222-2222-222222222222"
AUTHORITY_ID = "33333333-3333-3333-3333-333333333333"

def get_auth_headers(role: str, user_id: str, email: str, full_name: str):
    token = create_access_token({
        "sub": user_id,
        "email": email,
        "role": role,
        "full_name": full_name
    })
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def passenger_a_headers():
    return get_auth_headers("PASSENGER", PASSENGER_A_ID, "rahul.nair@bussense.kerala.gov.in", "Rahul Nair")

@pytest.fixture
def passenger_b_headers():
    return get_auth_headers("PASSENGER", PASSENGER_B_ID, "deepa.thomas@bussense.kerala.gov.in", "Deepa Thomas")

@pytest.fixture
def driver_headers():
    return get_auth_headers("DRIVER_CONDUCTOR", DRIVER_ID, "suresh.kumar@bussense.kerala.gov.in", "Suresh Kumar")

@pytest.fixture
def authority_headers():
    return get_auth_headers("AUTHORITY", AUTHORITY_ID, "controller.vyttila@bussense.kerala.gov.in", "Anjali Menon")

def test_ticket_booking_and_payment_persists(passenger_a_headers):
    """
    Test 1 & 5: When a ticket is booked:
    - Ticket row is created and persisted in Supabase `tickets` table.
    - Matching simulated payment row is created in `payments` table.
    """
    book_resp = client.post("/api/tickets/book", headers=passenger_a_headers, json={
        "bus_number": "205",
        "route_number": "205",
        "origin_stop": "Kaloor Metro Station",
        "destination_stop": "Vyttila Mobility Hub",
        "passenger_name": "Rahul Nair",
        "fare_amount": 25.0
    })
    assert book_resp.status_code == 200
    ticket_data = book_resp.json()["data"]
    ticket_id = ticket_data["id"]
    qr_hash = ticket_data["qr_code_hash"]
    ticket_number = ticket_data["ticket_number"]

    assert ticket_number.startswith("BS-KL-2026-")
    assert ticket_data["status"] == "VALID"
    assert ticket_data["qr_code_data_uri"].startswith("data:image/png;base64,")

    # Verify persistent ticket record directly in Supabase
    db_tickets = client.app.state # or direct supabase query
    import anyio
    async def verify_db():
        rows = await supabase_client.get("tickets", {"id": f"eq.{ticket_id}"})
        assert len(rows) == 1
        assert rows[0]["ticket_number"] == ticket_number
        assert rows[0]["user_id"] == PASSENGER_A_ID
        assert float(rows[0]["fare_amount"]) == 25.0
        assert rows[0]["status"] == "VALID"

        # Verify payment record in Supabase
        pay_rows = await supabase_client.get("payments", {"ticket_id": f"eq.{ticket_id}"})
        assert len(pay_rows) >= 1
        assert pay_rows[0]["status"] == "COMPLETED"
        assert pay_rows[0]["user_id"] == PASSENGER_A_ID

    anyio.run(verify_db)

def test_ticket_retrieval_and_user_isolation(passenger_a_headers, passenger_b_headers):
    """
    Test 2 & 10: Passenger A only retrieves their own tickets.
    Passenger B cannot retrieve Passenger A's tickets.
    """
    # 1. Passenger A books a distinct ticket
    book_resp = client.post("/api/tickets/book", headers=passenger_a_headers, json={
        "bus_number": "205",
        "route_number": "205",
        "origin_stop": "Edappally Toll",
        "destination_stop": "MG Road",
        "passenger_name": "Rahul Nair",
        "fare_amount": 30.0
    })
    assert book_resp.status_code == 200
    booked_ticket_num = book_resp.json()["data"]["ticket_number"]

    # 2. Passenger A calls GET /api/tickets/my -> MUST contain this ticket
    resp_a = client.get("/api/tickets/my", headers=passenger_a_headers)
    assert resp_a.status_code == 200
    tickets_a = resp_a.json()["data"]
    ticket_nums_a = [t["ticket_number"] for t in tickets_a]
    assert booked_ticket_num in ticket_nums_a

    # 3. Passenger B calls GET /api/tickets/my -> MUST NOT contain Passenger A's ticket
    resp_b = client.get("/api/tickets/my", headers=passenger_b_headers)
    assert resp_b.status_code == 200
    tickets_b = resp_b.json()["data"]
    ticket_nums_b = [t["ticket_number"] for t in tickets_b]
    assert booked_ticket_num not in ticket_nums_b

def test_atomic_ticket_validation_and_anti_reuse(passenger_a_headers, driver_headers):
    """
    Test 3 & 4:
    - Conductor validates ticket -> returns VALID.
    - Validation is persisted in `ticket_validations` table.
    - Ticket status updated to USED in `tickets` table.
    - Subsequent validation attempt returns ALREADY_USED (anti-reuse).
    """
    # 1. Book a ticket
    book_resp = client.post("/api/tickets/book", headers=passenger_a_headers, json={
        "bus_number": "205",
        "route_number": "205",
        "origin_stop": "Kaloor",
        "destination_stop": "Vyttila",
        "passenger_name": "Rahul Nair",
        "fare_amount": 25.0
    })
    ticket_data = book_resp.json()["data"]
    qr_hash = ticket_data["qr_code_hash"]
    ticket_id = ticket_data["id"]

    # 2. First validation by conductor -> VALID
    val_resp_1 = client.post("/api/tickets/validate", headers=driver_headers, json={
        "qr_code_hash": qr_hash,
        "bus_number": "205"
    })
    assert val_resp_1.status_code == 200
    res_1 = val_resp_1.json()["data"]
    assert res_1["result"] == "VALID"
    assert res_1["is_valid"] is True

    # 3. Verify in database: ticket status is USED, and ticket_validations record exists
    import anyio
    async def verify_validation_db():
        t_rows = await supabase_client.get("tickets", {"id": f"eq.{ticket_id}"})
        assert len(t_rows) == 1
        assert t_rows[0]["status"] == "USED"

        v_rows = await supabase_client.get("ticket_validations", {"ticket_id": f"eq.{ticket_id}"})
        assert len(v_rows) >= 1
        assert v_rows[0]["result"] == "VALID"

    anyio.run(verify_validation_db)

    # 4. Second validation of same ticket -> ALREADY_USED
    val_resp_2 = client.post("/api/tickets/validate", headers=driver_headers, json={
        "qr_code_hash": qr_hash,
        "bus_number": "205"
    })
    assert val_resp_2.status_code == 200
    res_2 = val_resp_2.json()["data"]
    assert res_2["result"] == "ALREADY_USED"
    assert res_2["is_valid"] is False

def test_incident_persistence_and_resolution_rbac(driver_headers, passenger_a_headers, authority_headers):
    """
    Test 6, 7, 11, 12:
    - Driver logs incident -> persisted in Supabase `incidents` table.
    - Passenger and driver cannot resolve incidents (403 Forbidden).
    - Authority resolves incident -> status updated to RESOLVED in Supabase.
    """
    # 1. Driver logs an incident
    rep_resp = client.post("/api/incidents/report", headers=driver_headers, json={
        "bus_number": "205",
        "route_number": "205",
        "category": "ROUTE_OBSTRUCTION",
        "severity": "WARNING",
        "title": "Waterlogging near Palarivattom Junction",
        "description": "Left lane flooded after rain; vehicles moving slowly."
    })
    assert rep_resp.status_code == 200
    inc_data = rep_resp.json()["data"]
    incident_id = inc_data["id"]
    assert inc_data["status"] == "REPORTED"

    # Verify incident exists in Supabase
    import anyio
    async def verify_inc_db():
        rows = await supabase_client.get("incidents", {"id": f"eq.{incident_id}"})
        assert len(rows) == 1
        assert rows[0]["status"] == "REPORTED"
        assert rows[0]["category"] == "ROUTE_OBSTRUCTION"

    anyio.run(verify_inc_db)

    # 2. Passenger tries to resolve -> 403 Forbidden
    resp_pass_res = client.post(f"/api/incidents/{incident_id}/resolve", headers=passenger_a_headers, json={
        "resolution_notes": "Passenger trying to resolve"
    })
    assert resp_pass_res.status_code == 403

    # 3. Driver tries to resolve -> 403 Forbidden
    resp_driver_res = client.post(f"/api/incidents/{incident_id}/resolve", headers=driver_headers, json={
        "resolution_notes": "Driver trying to resolve"
    })
    assert resp_driver_res.status_code == 403

    # 4. Authority resolves incident -> 200 Success
    resp_auth_res = client.post(f"/api/incidents/{incident_id}/resolve", headers=authority_headers, json={
        "resolution_notes": "Drainage pumps deployed, corridor cleared."
    })
    assert resp_auth_res.status_code == 200
    res_data = resp_auth_res.json()["data"]
    assert res_data["status"] == "RESOLVED"
    assert res_data["resolved_at"] is not None

    # Verify persistent status in Supabase is RESOLVED
    async def verify_inc_resolved():
        rows = await supabase_client.get("incidents", {"id": f"eq.{incident_id}"})
        assert len(rows) == 1
        assert rows[0]["status"] == "RESOLVED"
        assert rows[0]["resolved_at"] is not None

    anyio.run(verify_inc_resolved)

def test_alerts_and_reports_persistence(authority_headers):
    """
    Test 8: Alerts and operational reports are retrieved from Supabase PostgreSQL.
    """
    # 1. Alerts retrieval
    resp_alerts = client.get("/api/incidents/alerts")
    assert resp_alerts.status_code == 200
    alerts = resp_alerts.json()["data"]
    assert len(alerts) >= 1
    assert "title" in alerts[0]

    # 2. Reports retrieval
    resp_reports = client.get("/api/analytics/reports", headers=authority_headers)
    assert resp_reports.status_code == 200
    reports = resp_reports.json()["data"]
    assert len(reports) >= 1
    assert "on_time_pct" in reports[0]

def test_crowd_predictions_persistence():
    """
    Test: Crowd forecast queries persist predictions into `crowd_predictions` table.
    """
    resp = client.get("/api/occupancy/forecast/205")
    assert resp.status_code == 200
    forecast_points = resp.json()["data"]
    assert len(forecast_points) == 4

    # Verify records in Supabase crowd_predictions
    import anyio
    async def verify_preds():
        preds = await supabase_client.get("crowd_predictions", {"order": "created_at.desc", "limit": "5"})
        assert len(preds) >= 1
        assert preds[0]["data_origin"] == "PREDICTION"

    anyio.run(verify_preds)
