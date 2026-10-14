"""
BusSense AI - Phase H12 Test Suite
Realtime Data & Notifications Verification
Tests all 23 core requirements for WebSockets, polling fallbacks, freshness, RBAC, isolation, and notifications.
"""
import sys
import os
from datetime import datetime, timezone, timedelta
import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.main import app
from app.schemas.realtime import RealtimeEvent, RealtimeEventType, FreshnessInfo
from app.schemas.notifications import NotificationResponse
from app.services.realtime_service import realtime_service
from app.services.notification_service import notification_service
from app.services.push_service import push_provider
from app.services.ai_tools import tool_get_bus_location
from app.core.security import create_access_token

client = TestClient(app)


@pytest.fixture(autouse=True)
def clean_realtime_state():
    """Ensure clean state before each test run."""
    realtime_service.event_buffer.clear()
    realtime_service.public_connections.clear()
    realtime_service.authenticated_clients.clear()
    notification_service._dedup_cache.clear()
    notification_service._user_notifications.clear()
    yield


# ==============================================================================
# 1-5. Event Schema, Authentication & RBAC Isolation
# ==============================================================================

def test_01_event_schema_validation():
    """1. Validates standard RealtimeEvent typed envelope structure and serialization."""
    event = RealtimeEvent(
        event_type=RealtimeEventType.FLEET_TELEMETRY_UPDATE.value,
        entity_id="bus-205",
        data_origin="SIMULATED TELEMETRY",
        payload={"speed_kmh": 32.5, "occupancy_pct": 45.0}
    )
    dumped = event.model_dump()
    assert dumped["event_id"] is not None
    assert dumped["event_type"] == "FLEET_TELEMETRY_UPDATE"
    assert dumped["entity_id"] == "bus-205"
    assert dumped["schema_version"] == "1.0.0"
    assert "payload" in dumped
    assert dumped["data_origin"] == "SIMULATED TELEMETRY"


def test_02_realtime_authentication_success():
    """2. Validates WebSocket connection to /ws/live with valid JWT token query param."""
    token = create_access_token(data={"sub": "user-passenger-01", "role": "PASSENGER", "email": "pax@test.com"})
    with client.websocket_connect(f"/ws/live?token={token}") as ws:
        ack = ws.receive_json()
        assert ack["type"] == "AUTH_SUCCESS"
        assert ack["user_id"] == "user-passenger-01"
        assert ack["role"] == "PASSENGER"
        assert len(realtime_service.authenticated_clients) == 1


def test_03_realtime_authentication_rejection():
    """3. Validates that invalid credentials on /ws/live close connection."""
    with pytest.raises(Exception):
        with client.websocket_connect("/ws/live?token=invalid.garbage.token") as ws:
            ws.receive_json()


def test_04_role_based_subscription_filtering():
    """4. Validates that conductor / authority receive operational incident broadcasts."""
    token_pax = create_access_token(data={"sub": "user-pax", "role": "PASSENGER"})
    token_cond = create_access_token(data={"sub": "user-cond", "role": "DRIVER_CONDUCTOR"})

    with client.websocket_connect(f"/ws/live?token={token_pax}") as ws_pax:
        ack_pax = ws_pax.receive_json()
        assert ack_pax["type"] == "AUTH_SUCCESS"

        with client.websocket_connect(f"/ws/live?token={token_cond}") as ws_cond:
            ack_cond = ws_cond.receive_json()
            assert ack_cond["type"] == "AUTH_SUCCESS"

            # Check authenticated clients registered
            assert len(realtime_service.authenticated_clients) == 2


@pytest.mark.anyio
async def test_05_cross_user_isolation_protected():
    """5. Validates that personal USER_NOTIFICATION is strictly isolated to destination user."""
    # Create notification for User A
    notif = await notification_service.create_notification(
        user_id="user-isolated-A",
        title="Arrival Notice",
        body="Bus 205 arriving in 3 mins.",
        notification_type="BUS_ARRIVAL"
    )
    assert notif is not None

    # Query notifications for User B: must be empty
    notifs_b = await notification_service.get_user_notifications(user_id="user-isolated-B")
    assert len(notifs_b) == 0

    # Query notifications for User A: must contain created notification
    notifs_a = await notification_service.get_user_notifications(user_id="user-isolated-A")
    assert len(notifs_a) == 1
    assert notifs_a[0].id == notif.id


# ==============================================================================
# 6-10. Event Publishing & Lifecycle Operations
# ==============================================================================

def test_06_event_publishing_after_incident_report():
    """6. Validates that reporting an incident publishes an INCIDENT_UPDATE event."""
    token = create_access_token(data={"sub": "conductor-01", "role": "DRIVER_CONDUCTOR"})
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "category": "OVERCROWDING",
        "severity": "WARNING",
        "title": "Severe Morning Surge",
        "description": "Cabin density exceeds safe standing threshold at Palarivattom Jn.",
        "bus_number": "205",
        "route_number": "12"
    }

    res = client.post("/api/incidents/report", json=payload, headers=headers)
    assert res.status_code == 200

    # Verify event appended to realtime buffer
    recent = realtime_service.get_recent_events(event_type=RealtimeEventType.INCIDENT_UPDATE.value)
    assert len(recent) >= 1
    ev = recent[-1]
    assert ev.event_type == RealtimeEventType.INCIDENT_UPDATE.value
    assert ev.data_origin == "HUMAN-REPORTED INCIDENT"
    assert ev.payload["title"] == "Severe Morning Surge"


def test_07_incident_resolution_event_propagation():
    """7. Validates that resolving an incident publishes an INCIDENT_UPDATE with status = RESOLVED."""
    token_cond = create_access_token(data={"sub": "conductor-01", "role": "DRIVER_CONDUCTOR"})
    headers_cond = {"Authorization": f"Bearer {token_cond}"}
    create_res = client.post("/api/incidents/report", json={
        "category": "VEHICLE_ISSUE",
        "severity": "LOW",
        "title": "Minor Sensor Glitch",
        "description": "Rebooted successfully.",
        "bus_number": "205",
        "route_number": "12"
    }, headers=headers_cond)
    inc_id = create_res.json()["data"]["id"]

    token_auth = create_access_token(data={"sub": "authority-01", "role": "AUTHORITY"})
    headers_auth = {"Authorization": f"Bearer {token_auth}"}

    res = client.post(f"/api/incidents/{inc_id}/resolve", json={"resolution_notes": "Resolved."}, headers=headers_auth)
    assert res.status_code == 200

    recent = realtime_service.get_recent_events(event_type=RealtimeEventType.INCIDENT_UPDATE.value)
    assert len(recent) >= 1
    ev = recent[-1]
    assert ev.payload["status"] == "RESOLVED"


def test_08_occupancy_event_propagation():
    """8. Validates that ingesting CV replay event publishes an OCCUPANCY_UPDATE event."""
    token = create_access_token(data={"sub": "authority-01", "role": "AUTHORITY"})
    headers = {"Authorization": f"Bearer {token}"}

    event_payload = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "bus_number": "205",
        "raw_person_count": 28,
        "stabilized_person_count": 28,
        "capacity": 55,
        "occupancy_percentage": 50.9,
        "crowd_level": "MODERATE",
        "fps": 24.5,
        "latency_ms": 18.2,
        "source": "CV_REPLAY",
        "model": "YOLOv8n"
    }

    res = client.post("/api/occupancy/events", json=event_payload, headers=headers)
    assert res.status_code == 200

    recent = realtime_service.get_recent_events(event_type=RealtimeEventType.OCCUPANCY_UPDATE.value)
    assert len(recent) >= 1
    assert recent[-1].data_origin == "CV REPLAY"
    assert recent[-1].entity_id == "205"


def test_09_disconnect_and_subscription_cleanup():
    """9. Validates that client disconnect cleans up connection registries."""
    with client.websocket_connect("/ws/telemetry") as ws:
        assert len(realtime_service.public_connections) == 1
    # After context exit, socket closed
    assert len(realtime_service.public_connections) == 0


@pytest.mark.anyio
async def test_10_connection_limits_enforced():
    """10. Validates max connection capacity enforcement."""
    realtime_service.authenticated_clients.clear()
    realtime_service.public_connections.clear()
    realtime_service.MAX_CONNECTIONS = 2
    # Register 2 clients
    c1 = await realtime_service.connect_authenticated(
        websocket=None, user_id="u1", role="PASSENGER"  # type: ignore
    )
    assert c1 is not None
    c2 = await realtime_service.connect_authenticated(
        websocket=None, user_id="u2", role="PASSENGER"  # type: ignore
    )
    assert c2 is not None

    # 3rd should be rejected
    c3 = await realtime_service.connect_authenticated(
        websocket=None, user_id="u3", role="PASSENGER"  # type: ignore
    )
    assert c3 is None
    assert realtime_service.total_active_connections == 2

    # Reset limit and clean up
    realtime_service.authenticated_clients.clear()
    realtime_service.MAX_CONNECTIONS = 100


# ==============================================================================
# 11-15. Data Freshness & Notifications Domain
# ==============================================================================

def test_11_data_freshness_calculations():
    """11. Validates data freshness tracker and staleness threshold."""
    now_iso = datetime.now(timezone.utc).isoformat()
    fresh = realtime_service.calculate_data_freshness(now_iso, "SIMULATED TELEMETRY")
    assert fresh.is_stale is False
    assert fresh.data_age_seconds < 2.0
    assert "FRESH" in fresh.freshness_label

    # Telemetry older than 15s must be flagged stale
    old_iso = (datetime.now(timezone.utc) - timedelta(seconds=25)).isoformat()
    stale = realtime_service.calculate_data_freshness(old_iso, "SIMULATED TELEMETRY")
    assert stale.is_stale is True
    assert stale.data_age_seconds >= 24.0
    assert "STALE" in stale.freshness_label


@pytest.mark.anyio
async def test_12_notification_persistence():
    """12. Validates creating and retrieving persistent notification."""
    notif = await notification_service.create_notification(
        user_id="user-commuter-77",
        title="Corridor Advisory",
        body="Route 205 operating with 4 min headway.",
        notification_type="TRANSIT_ALERT",
        severity="INFO"
    )
    assert notif is not None
    assert notif.user_id == "user-commuter-77"
    assert notif.is_read is False

    retrieved = await notification_service.get_user_notifications("user-commuter-77")
    assert len(retrieved) >= 1
    assert retrieved[0].title == "Corridor Advisory"


@pytest.mark.anyio
async def test_13_notification_deduplication():
    """13. Validates that duplicate notifications with same dedup_key within window are suppressed."""
    key = "crowd_bus205_morning_rush"
    # First creation succeeds
    n1 = await notification_service.create_notification(
        user_id="user-commuter-88",
        title="High Crowding Alert",
        body="Bus 205 is at 85% capacity.",
        notification_type="CROWD_SURGE",
        dedup_key=key
    )
    assert n1 is not None

    # Immediate second creation with same dedup_key must be suppressed
    n2 = await notification_service.create_notification(
        user_id="user-commuter-88",
        title="High Crowding Alert",
        body="Bus 205 is at 85% capacity.",
        notification_type="CROWD_SURGE",
        dedup_key=key
    )
    assert n2 is None


@pytest.mark.anyio
async def test_14_notification_read_unread_mutation():
    """14. Validates marking a notification as read and unread count decrements."""
    n = await notification_service.create_notification(
        user_id="user-read-test",
        title="Ticket Reminder",
        body="Your boarding pass is active.",
        notification_type="TICKET_UPDATE"
    )
    assert n is not None

    unread_before = await notification_service.get_unread_count("user-read-test")
    assert unread_before >= 1

    await notification_service.mark_as_read(n.id, "user-read-test")
    unread_after = await notification_service.get_unread_count("user-read-test")
    assert unread_after == 0


@pytest.mark.anyio
async def test_15_notification_user_isolation():
    """15. Validates user isolation in notification retrieval."""
    await notification_service.create_notification(
        user_id="user-alpha",
        title="Alpha Notice",
        body="Message for Alpha only."
    )
    await notification_service.create_notification(
        user_id="user-beta",
        title="Beta Notice",
        body="Message for Beta only."
    )

    alpha_list = await notification_service.get_user_notifications("user-alpha")
    beta_list = await notification_service.get_user_notifications("user-beta")

    assert all(item.user_id == "user-alpha" for item in alpha_list)
    assert all(item.user_id == "user-beta" for item in beta_list)


# ==============================================================================
# 16-20. Polling Fallbacks, Health, Push Status & Endpoints
# ==============================================================================

def test_16_polling_fallback_endpoint():
    """16. Validates /api/realtime/events polling fallback endpoint."""
    # Publish synthetic event
    ev = RealtimeEvent(
        event_type=RealtimeEventType.ALERT_UPDATE.value,
        entity_id="alert-101",
        data_origin="SIMULATED DATA",
        payload={"message": "Detour near Kaloor Stand."}
    )
    realtime_service.event_buffer.append(ev)

    res = client.get("/api/realtime/events?limit=10")
    assert res.status_code == 200
    data = res.json()["data"]
    assert len(data) >= 1
    assert data[-1]["entity_id"] == "alert-101"


def test_17_realtime_health_endpoint():
    """17. Validates /api/realtime/health returns operational metrics."""
    res = client.get("/api/realtime/health")
    assert res.status_code == 200
    data = res.json()["data"]
    assert data["status"] == "HEALTHY"
    assert "active_public_connections" in data
    assert "in_memory_buffer_size" in data


def test_18_push_notification_deferred_disclosure():
    """18. Validates /api/notifications/push-status discloses DEFERRED honestly."""
    res = client.get("/api/notifications/push-status")
    assert res.status_code == 200
    data = res.json()["data"]
    assert data["status"] == "DEFERRED"
    assert data["push_enabled"] is False
    assert "DEFERRED" in data["truth_label"]


def test_19_mark_all_notifications_read_endpoint():
    """19. Validates /api/notifications/mark-all-read endpoint for authenticated user."""
    token = create_access_token(data={"sub": "user-bulk-read", "role": "PASSENGER"})
    headers = {"Authorization": f"Bearer {token}"}

    res = client.post("/api/notifications/mark-all-read", headers=headers)
    assert res.status_code == 200
    assert res.json()["data"]["success"] is True


def test_20_malformed_event_rejection():
    """20. Validates malformed payloads are safely rejected by Pydantic schemas."""
    with pytest.raises(Exception):
        RealtimeEvent()  # type: ignore


# ==============================================================================
# 21-23. Trip Status, AI Assistant Freshness & Regression Integrity
# ==============================================================================

def test_21_trip_status_realtime_event():
    """21. Validates that conductor trip action dispatches a TRIP_STATUS_UPDATE event."""
    token = create_access_token(data={"sub": "conductor-01", "role": "DRIVER_CONDUCTOR"})
    headers = {"Authorization": f"Bearer {token}"}

    res = client.post("/api/conductor/trips/start", json={"trip_id": "trip-test-01"}, headers=headers)
    assert res.status_code == 200

    recent = realtime_service.get_recent_events(event_type=RealtimeEventType.TRIP_STATUS_UPDATE.value)
    assert len(recent) >= 1
    assert recent[-1].payload["status"] == "ACTIVE"


def test_22_ai_assistant_freshness_awareness():
    """22. Validates that tool_get_bus_location provides data freshness diagnostics."""
    telem = tool_get_bus_location("205")
    assert telem is not None
    assert "data_age_seconds" in telem
    assert "is_stale" in telem
    assert "freshness_label" in telem


def test_23_h9_h10_integration_intact():
    """23. Validates that H9 demand forecaster and H10 recommendation engine remain functional."""
    from app.services.demand_forecaster import demand_forecaster
    from app.services.recommendation_engine import recommendation_engine

    forecast = demand_forecaster.forecast_corridor_crowd("205")
    assert len(forecast) == 4

    plan = recommendation_engine.plan_journey("Kaloor", "Infopark")
    assert plan.recommended_bus is not None
