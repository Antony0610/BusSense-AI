"""Database client interfacing with Supabase PostgreSQL and local storage."""
from __future__ import annotations

import hashlib
import time
import uuid
from datetime import datetime, timezone
from typing import Any

from backend.config import settings

# In-memory fast state store for active runtime tracking & offline fallback
_STATE: dict[str, Any] = {
    "buses": {},
    "telemetry": [],
    "tickets": {},
    "sos_alerts": [],
    "dispatch_logs": [],
    "reports": [],
}


def _init_default_fleet():
    if _STATE["buses"]:
        return
    defaults = [
        {"bus_id": "KSRTC-101", "operator_type": "KSRTC", "route_number": "R1", "capacity": 50, "registration_number": "KL-15-A-1001", "safety_score": 9.6, "sprite_type": "ksrtc_standard", "passenger_count": 22, "lat": 8.5241, "lon": 76.9366, "speed": 38.0, "heading": 45.0},
        {"bus_id": "KSRTC-102", "operator_type": "KSRTC", "route_number": "R1", "capacity": 50, "registration_number": "KL-15-A-1002", "safety_score": 9.4, "sprite_type": "ksrtc_standard", "passenger_count": 46, "lat": 8.5350, "lon": 76.9450, "speed": 25.0, "heading": 50.0},
        {"bus_id": "PVT-201", "operator_type": "PRIVATE", "route_number": "R1", "capacity": 40, "registration_number": "KL-01-P-2201", "safety_score": 9.1, "sprite_type": "pvt_cruiser", "passenger_count": 24, "lat": 8.5410, "lon": 76.9520, "speed": 42.0, "heading": 48.0},
        {"bus_id": "KSRTC-103", "operator_type": "KSRTC", "route_number": "R2", "capacity": 50, "registration_number": "KL-15-A-1003", "safety_score": 9.5, "sprite_type": "ksrtc_standard", "passenger_count": 18, "lat": 8.4830, "lon": 76.9440, "speed": 40.0, "heading": 180.0},
        {"bus_id": "PVT-202", "operator_type": "PRIVATE", "route_number": "R2", "capacity": 38, "registration_number": "KL-01-P-2202", "safety_score": 8.9, "sprite_type": "pvt_cruiser", "passenger_count": 14, "lat": 8.4720, "lon": 76.9520, "speed": 35.0, "heading": 175.0},
        {"bus_id": "KSRTC-104", "operator_type": "KSRTC", "route_number": "R3", "capacity": 50, "registration_number": "KL-15-A-1004", "safety_score": 9.7, "sprite_type": "ksrtc_standard", "passenger_count": 48, "lat": 8.5280, "lon": 76.9420, "speed": 20.0, "heading": 320.0},
        {"bus_id": "PVT-203", "operator_type": "PRIVATE", "route_number": "R3", "capacity": 42, "registration_number": "KL-01-P-2203", "safety_score": 9.2, "sprite_type": "pvt_cruiser", "passenger_count": 20, "lat": 8.5350, "lon": 76.9380, "speed": 38.0, "heading": 315.0},
        {"bus_id": "KSRTC-105", "operator_type": "KSRTC", "route_number": "R4", "capacity": 48, "registration_number": "KL-15-A-1005", "safety_score": 9.5, "sprite_type": "ksrtc_standard", "passenger_count": 12, "lat": 8.5240, "lon": 76.9370, "speed": 30.0, "heading": 90.0},
        {"bus_id": "PVT-204", "operator_type": "PRIVATE", "route_number": "R4", "capacity": 36, "registration_number": "KL-01-P-2204", "safety_score": 9.0, "sprite_type": "pvt_cruiser", "passenger_count": 10, "lat": 8.5150, "lon": 76.9480, "speed": 32.0, "heading": 85.0},
    ]
    for b in defaults:
        cap = b["capacity"]
        passengers = b["passenger_count"]
        occ = round((passengers / cap) * 100, 1)
        tier = "RED" if occ >= 80 else ("YELLOW" if occ >= 50 else "GREEN")
        _STATE["buses"][b["bus_id"]] = {
            "bus_id": b["bus_id"],
            "operator_type": b["operator_type"],
            "route_number": b["route_number"],
            "registration_number": b["registration_number"],
            "capacity": cap,
            "passenger_count": passengers,
            "occupancy_percentage": occ,
            "seat_availability": max(cap - passengers, 0),
            "crowd_tier": tier,
            "latitude": b["lat"],
            "longitude": b["lon"],
            "speed_kmh": b["speed"],
            "heading_deg": b["heading"],
            "status": "active",
            "safety_score": b["safety_score"],
            "sprite_type": b["sprite_type"],
            "eta_minutes": 6,
            "comfort_index": round(max(0.0, ((cap - passengers) / cap) * 100), 1),
        }


_init_default_fleet()


def get_all_buses(operator: str | None = None, route: str | None = None) -> list[dict]:
    buses = list(_STATE["buses"].values())
    if operator:
        buses = [b for b in buses if b["operator_type"].upper() == operator.upper()]
    if route:
        buses = [b for b in buses if b["route_number"].upper() == route.upper()]
    return buses


def update_bus_telemetry(
    bus_id: str,
    route_number: str,
    latitude: float,
    longitude: float,
    passenger_count: int,
    capacity: int = 50,
    speed_kmh: float = 35.0,
    heading_deg: float = 0.0,
    source: str = "edge_yolo",
) -> dict:
    occ = round((passenger_count / max(capacity, 1)) * 100, 1)
    tier = "RED" if occ >= 80 else ("YELLOW" if occ >= 50 else "GREEN")
    avail = max(capacity - passenger_count, 0)
    comfort = round(max(0.0, ((capacity - passenger_count) / max(capacity, 1)) * 100), 1)
    now_iso = datetime.now(timezone.utc).isoformat()

    record = {
        "bus_id": bus_id,
        "route_number": route_number,
        "capacity": capacity,
        "passenger_count": passenger_count,
        "occupancy_percentage": occ,
        "seat_availability": avail,
        "crowd_tier": tier,
        "latitude": latitude,
        "longitude": longitude,
        "speed_kmh": speed_kmh,
        "heading_deg": heading_deg,
        "comfort_index": comfort,
        "source": source,
        "timestamp": now_iso,
    }

    if bus_id in _STATE["buses"]:
        _STATE["buses"][bus_id].update(record)
    else:
        _STATE["buses"][bus_id] = {
            **record,
            "operator_type": "KSRTC" if "KSRTC" in bus_id else "PRIVATE",
            "registration_number": f"KL-01-XX-{int(time.time()) % 9000 + 1000}",
            "status": "active",
            "safety_score": 9.2,
            "sprite_type": "ksrtc_standard" if "KSRTC" in bus_id else "pvt_cruiser",
            "eta_minutes": 5,
        }

    _STATE["telemetry"].append(record)
    return record


def book_ticket(
    user_id: str,
    bus_id: str,
    route_number: str,
    origin_stop: str,
    destination_stop: str,
    seat_number: str,
    base_fare: float = 40.0,
) -> dict:
    ticket_id = str(uuid.uuid4())
    bus = _STATE["buses"].get(bus_id, {})
    occ = bus.get("occupancy_percentage", 50.0)

    # Dynamic Green Commute Discount: 20% discount on low-crowd buses
    discount_pct = 20.0 if occ < 50.0 else (10.0 if occ < 75.0 else 0.0)
    final_fare = round(base_fare * (1.0 - (discount_pct / 100.0)), 2)

    raw_token = f"{ticket_id}:{user_id}:{bus_id}:{seat_number}:{time.time()}"
    qr_hash = hashlib.sha256(raw_token.encode()).hexdigest()[:24]
    now_iso = datetime.now(timezone.utc).isoformat()
    valid_until = datetime.now(timezone.utc).replace(hour=23, minute=59).isoformat()

    ticket = {
        "ticket_id": ticket_id,
        "user_id": user_id,
        "bus_id": bus_id,
        "route_number": route_number,
        "origin_stop": origin_stop,
        "destination_stop": destination_stop,
        "seat_number": seat_number,
        "base_fare": base_fare,
        "discount_pct": discount_pct,
        "final_fare": final_fare,
        "qr_code_hash": qr_hash,
        "status": "active",
        "valid_until": valid_until,
        "created_at": now_iso,
    }
    _STATE["tickets"][qr_hash] = ticket
    return ticket


def validate_ticket(qr_code_hash: str, bus_id: str) -> dict:
    ticket = _STATE["tickets"].get(qr_code_hash)
    if not ticket:
        return {"valid": False, "status": "invalid", "message": "Ticket not found or expired"}
    if ticket["status"] == "used":
        return {"valid": False, "status": "already_used", "message": "Ticket has already been scanned"}
    ticket["status"] = "used"
    ticket["validated_at"] = datetime.now(timezone.utc).isoformat()
    return {
        "valid": True,
        "ticket_id": ticket["ticket_id"],
        "seat_number": ticket["seat_number"],
        "status": "validated",
        "message": f"Valid ticket for seat {ticket['seat_number']}",
    }


def record_sos_alert(
    latitude: float,
    longitude: float,
    user_id: str | None = None,
    bus_id: str | None = None,
    route_number: str | None = None,
    message: str = "Emergency SOS Triggered by Passenger",
) -> dict:
    alert_id = str(uuid.uuid4())
    now_iso = datetime.now(timezone.utc).isoformat()
    alert = {
        "sos_id": alert_id,
        "user_id": user_id,
        "bus_id": bus_id,
        "route_number": route_number,
        "latitude": latitude,
        "longitude": longitude,
        "message": message,
        "status": "active",
        "created_at": now_iso,
    }
    _STATE["sos_alerts"].append(alert)
    return alert


def dispatch_relief_bus(route_number: str, operator_type: str = "KSRTC", reason: str = "Surge Relief Dispatch") -> dict:
    count = sum(1 for b in _STATE["buses"].values() if b.get("route_number") == route_number)
    new_id = f"{operator_type}-EXTRA-{count + 1}"
    now_iso = datetime.now(timezone.utc).isoformat()

    new_bus = {
        "bus_id": new_id,
        "operator_type": operator_type,
        "route_number": route_number,
        "registration_number": f"KL-01-EX-{count + 1:02d}",
        "capacity": 50,
        "passenger_count": 8,
        "occupancy_percentage": 16.0,
        "seat_availability": 42,
        "crowd_tier": "GREEN",
        "latitude": 8.5241,
        "longitude": 76.9366,
        "speed_kmh": 40.0,
        "heading_deg": 45.0,
        "status": "dispatched_extra",
        "safety_score": 9.8,
        "sprite_type": "ksrtc_standard" if operator_type == "KSRTC" else "pvt_cruiser",
        "eta_minutes": 3,
        "comfort_index": 84.0,
    }
    _STATE["buses"][new_id] = new_bus
    _STATE["dispatch_logs"].append({
        "bus_id": new_id,
        "route_number": route_number,
        "operator_type": operator_type,
        "reason": reason,
        "dispatched_at": now_iso,
    })
    return {
        "message": f"Dispatched extra {operator_type} bus {new_id} to Route {route_number}",
        "bus_id": new_id,
        "route_number": route_number,
        "operator_type": operator_type,
        "dispatched_at": now_iso,
    }


def record_passenger_report(
    message: str,
    report_type: str = "overcrowding",
    user_id: str | None = None,
    bus_id: str | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
) -> dict:
    rep_id = str(uuid.uuid4())
    now_iso = datetime.now(timezone.utc).isoformat()
    record = {
        "id": rep_id,
        "user_id": user_id,
        "bus_id": bus_id,
        "report_type": report_type,
        "message": message,
        "latitude": latitude,
        "longitude": longitude,
        "status": "pending",
        "created_at": now_iso,
    }
    _STATE["reports"].append(record)
    return record
