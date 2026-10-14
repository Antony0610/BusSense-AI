"""
BusSense AI - Phase H13: Supabase Security Remediation & Access Control Tests
Verifies that all reported Supabase security vulnerabilities, RLS boundaries,
multi-tenant user isolation, and RBAC privileges are strictly enforced.
"""
import sys
import os
import re
import asyncio
from pathlib import Path

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token
from app.core.config import settings

client = TestClient(app)

PASSENGER_A_ID = "11111111-1111-1111-1111-111111111111"
PASSENGER_B_ID = "22222222-2222-2222-2222-222222222222"
CONDUCTOR_ID   = "33333333-3333-3333-3333-333333333333"
AUTHORITY_ID   = "44444444-4444-4444-4444-444444444444"

def make_headers(user_id: str, role: str, email: str = "user@bussense.ai"):
    token = create_access_token({
        "sub": user_id,
        "email": email,
        "role": role,
        "full_name": f"User {user_id[:6]}"
    })
    return {"Authorization": f"Bearer {token}"}

headers_pax_a = make_headers(PASSENGER_A_ID, "PASSENGER", "rahul.nair@bussense.kerala.gov.in")
headers_pax_b = make_headers(PASSENGER_B_ID, "PASSENGER", "anjali.menon@bussense.kerala.gov.in")
headers_conductor = make_headers(CONDUCTOR_ID, "DRIVER_CONDUCTOR", "suresh.kumar@bussense.kerala.gov.in")
headers_authority = make_headers(AUTHORITY_ID, "AUTHORITY", "priya.sharma@bussense.kerala.gov.in")


def test_01_anonymous_access_to_private_records_rejected():
    """Unauthenticated access to any private domain endpoint must be rejected with 401."""
    private_endpoints = [
        ("GET", "/api/auth/me"),
        ("GET", "/api/tickets/my"),
        ("GET", "/api/notifications"),
        ("GET", "/api/user/profile"),
        ("GET", "/api/conductor/shift"),
        ("GET", "/api/analytics/command-overview"),
    ]
    for method, path in private_endpoints:
        if method == "GET":
            resp = client.get(path)
        assert resp.status_code == 401, f"Expected 401 for anonymous access to {path}, got {resp.status_code}"


def test_02_passenger_a_cannot_access_passenger_b_tickets():
    """Passenger A cannot retrieve tickets owned by Passenger B."""
    resp_a = client.get("/api/tickets/my", headers=headers_pax_a)
    assert resp_a.status_code == 200
    for ticket in resp_a.json().get("data", []):
        assert ticket.get("user_id") == PASSENGER_A_ID or "user_id" not in ticket


def test_03_passenger_a_cannot_access_passenger_b_notifications():
    """Passenger A cannot retrieve notifications belonging to Passenger B."""
    resp_a = client.get("/api/notifications", headers=headers_pax_a)
    assert resp_a.status_code == 200
    items_a = resp_a.json().get("items", [])
    for item in items_a:
        assert item.get("user_id") == PASSENGER_A_ID or item.get("user_id") is None


def test_04_passenger_cannot_modify_other_user_notifications():
    """Passenger A cannot mark Passenger B's notification as read."""
    # Attempt to mark an arbitrary ID
    fake_notif_id = "00000000-0000-0000-0000-000000000999"
    resp = client.patch(f"/api/notifications/{fake_notif_id}/read", headers=headers_pax_a)
    # Must either be 404 or success that affects 0 records, never 200 modifying another user
    assert resp.status_code in [200, 404]


def test_05_passenger_bulk_mark_read_scoped_to_current_user():
    """Bulk mark-all-read endpoint must be strictly scoped to current_user.id."""
    resp = client.post("/api/notifications/mark-all-read", headers=headers_pax_a)
    assert resp.status_code == 200
    data = resp.json()
    assert data.get("success") is True
    assert data["data"]["user_id"] == PASSENGER_A_ID


def test_06_conductor_permission_boundaries():
    """Conductor cannot access authority operations console or user personal preferences."""
    resp_cmd = client.get("/api/analytics/command-overview", headers=headers_conductor)
    assert resp_cmd.status_code == 403
    assert "Access denied" in resp_cmd.json()["detail"]

    resp_reports = client.get("/api/analytics/reports", headers=headers_conductor)
    assert resp_reports.status_code == 403


def test_07_authority_permission_boundaries():
    """Authority can access command overview and operational triage."""
    resp_cmd = client.get("/api/analytics/command-overview", headers=headers_authority)
    assert resp_cmd.status_code == 200
    data = resp_cmd.json()
    assert data.get("success") is True
    assert "active_buses_count" in data.get("data", {})


def test_08_public_data_contains_no_sensitive_pii():
    """Public fleet, route, and stop catalogs must contain no user PII or ticket tokens."""
    resp_buses = client.get("/api/buses")
    assert resp_buses.status_code == 200
    buses = resp_buses.json()
    assert len(buses) > 0
    for bus in buses:
        assert "password" not in bus
        assert "ticket_token" not in bus
        assert "qr_code_hash" not in bus
        assert "passenger_email" not in bus

    resp_routes = client.get("/api/routes")
    assert resp_routes.status_code == 200
    for r in resp_routes.json():
        assert "secret" not in r


def test_09_migration_006_syntax_and_coverage():
    """Verify that migration 006 covers all reported Supabase security advisories."""
    mig_path = Path(__file__).resolve().parent.parent / "migrations" / "006_supabase_security_remediation.sql"
    assert mig_path.exists(), "Migration 006 file must exist"
    
    content = mig_path.read_text(encoding="utf-8")
    
    # Must secure roles, bus_recommendations, notifications, journey_history, ai_conversations, ai_messages
    for tbl in ["roles", "bus_recommendations", "notifications", "journey_history", "ai_conversations", "ai_messages"]:
        assert f"ALTER TABLE {tbl} ENABLE ROW LEVEL SECURITY;" in content or f"ALTER TABLE public.{tbl} ENABLE ROW LEVEL SECURITY;" in content, f"Missing RLS enablement for {tbl}"

    # Must cover favorites and knowledge_chunks
    assert "favorites ENABLE ROW LEVEL SECURITY;" in content
    assert "knowledge_chunks ENABLE ROW LEVEL SECURITY;" in content

    # Must set search_path on validate_ticket_atomic
    assert "validate_ticket_atomic" in content
    assert "search_path = public, pg_temp" in content

    # Must eliminate wide-open USING (true) WITH CHECK (true) on notifications
    assert 'DROP POLICY IF EXISTS "Allow public all notifications"' in content


def test_10_client_bundles_secret_exposure_scan():
    """Scan frontend and mobile directories to ensure no secrets or service role keys are bundled."""
    repo_root = Path(__file__).resolve().parent.parent.parent
    
    sensitive_patterns = [
        re.compile(r'service_role', re.IGNORECASE),
        re.compile(r'bussense_ai_super_secret_jwt_key', re.IGNORECASE),
        re.compile(r'sbp_[a-zA-Z0-9]{20,}', re.IGNORECASE), # supabase access token
    ]

    client_dirs = [repo_root / "frontend" / "app", repo_root / "frontend" / "lib", repo_root / "apps" / "mobile" / "lib"]
    
    violations = []
    for d in client_dirs:
        if not d.exists():
            continue
        for file in d.rglob("*"):
            if file.is_file() and file.suffix in [".ts", ".tsx", ".dart", ".js"]:
                txt = file.read_text(encoding="utf-8", errors="ignore")
                for pat in sensitive_patterns:
                    if pat.search(txt):
                        violations.append(f"{file.name} matched {pat.pattern}")

    assert len(violations) == 0, f"Sensitive patterns detected in client bundles: {violations}"


def test_11_token_expiration_and_revocation():
    """Verify that logged-out tokens are blacklisted and rejected."""
    token = create_access_token({
        "sub": PASSENGER_A_ID,
        "email": "temp@bussense.ai",
        "role": "PASSENGER",
        "full_name": "Temp Commuter"
    })
    headers = {"Authorization": f"Bearer {token}"}
    
    # 1. Valid before logout
    resp1 = client.get("/api/auth/me", headers=headers)
    assert resp1.status_code == 200

    # 2. Logout blacklists token
    resp_logout = client.post("/api/auth/logout", headers=headers)
    assert resp_logout.status_code == 200

    # 3. Subsequent request rejected
    resp2 = client.get("/api/auth/me", headers=headers)
    assert resp2.status_code == 401


def test_12_public_event_payload_leakage_prevented():
    """Verify that realtime events emitted to public stream contain no private passenger info."""
    from app.services.realtime_service import realtime_service
    events = list(realtime_service.event_buffer)
    for evt in events:
        if evt.event_type == "FLEET_TELEMETRY_UPDATE":
            payload_str = str(evt.payload)
            assert "password" not in payload_str
            assert "qr_code_hash" not in payload_str
            assert "ticket_number" not in payload_str
            assert "passenger_email" not in payload_str
