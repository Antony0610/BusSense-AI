"""
BusSense AI - Conductor / Driver Operational Service
Manages operational shift check-in, vehicle pairing, active cockpit state, and trip completion.
"""
from typing import Dict, Any, Optional
from datetime import datetime, timezone
import uuid
from app.schemas.conductor import (
    ConductorShiftResponse,
    ConductorTripCompletionResponse
)
from app.schemas.common import DataOrigin, CrowdLevel
from app.services.gps_simulator import gps_simulator
from app.core.supabase import supabase_client
from app.schemas.realtime import RealtimeEvent, RealtimeEventType
from app.services.realtime_service import realtime_service

class ConductorService:
    def __init__(self):
        # In-memory operational shift cache per conductor user_id
        self._shifts: Dict[str, Dict[str, Any]] = {}
        self._validated_counts: Dict[str, int] = {}

    def _get_or_create_shift(self, user_id: str, full_name: str) -> Dict[str, Any]:
        if user_id not in self._shifts:
            # Seed default active pairing for standard Kochi corridor (Bus 205, Route 12)
            self._shifts[user_id] = {
                "duty_id": "DUTY-KL-402",
                "staff_name": full_name or "Suresh Kumar (Driver #402)",
                "staff_id": user_id,
                "role": "DRIVER_CONDUCTOR",
                "status": "CHECKED_IN",
                "pairing_status": "PAIRED",
                "bus_number": "205",
                "route_number": "12",
                "shift_name": "Morning Peak Corridor Shift",
                "shift_hours": "06:00 – 14:00",
                "check_in_time": datetime.now(timezone.utc).isoformat(),
                "trip_status": "ACTIVE",
                "trip_id": "trip-sim-205",
                "trip_code": "TRIP-205-ACTIVE",
                "origin": "Aluva Metro Station",
                "destination": "Vyttila Mobility Hub",
            }
        return self._shifts[user_id]

    async def get_shift(self, user_id: str, full_name: str) -> ConductorShiftResponse:
        shift_data = self._get_or_create_shift(user_id, full_name)
        bus_number = shift_data.get("bus_number", "205")
        telemetry = gps_simulator.get_bus_telemetry(bus_number)

        active_trip_info = None
        if shift_data.get("pairing_status") == "PAIRED":
            active_trip_info = {
                "trip_id": shift_data.get("trip_id", f"trip-sim-{bus_number}"),
                "trip_code": shift_data.get("trip_code", f"TRIP-{bus_number}-ACTIVE"),
                "bus_number": bus_number,
                "route_number": shift_data.get("route_number", "12"),
                "origin": shift_data.get("origin", "Aluva Metro Station"),
                "destination": shift_data.get("destination", "Vyttila Mobility Hub"),
                "current_stop": telemetry.get("current_stop", "Palarivattom Jn"),
                "next_stop": telemetry.get("next_stop", "Kaloor Central Stand"),
                "status": shift_data.get("trip_status", "ACTIVE"),
                "occupancy_pct": float(telemetry.get("occupancy_pct", 41.8)),
                "crowd_level": telemetry.get("crowd_level", CrowdLevel.LOW),
                "eta_minutes": 6,
                "progress_pct": 0.65,
                "speed_kmh": telemetry.get("speed_kmh", 28.5),
            }

        return ConductorShiftResponse(
            duty_id=shift_data["duty_id"],
            staff_name=shift_data["staff_name"],
            staff_id=shift_data["staff_id"],
            role="DRIVER_CONDUCTOR",
            status=shift_data["status"],
            pairing_status=shift_data["pairing_status"],
            bus_number=shift_data["bus_number"],
            route_number=shift_data["route_number"],
            shift_name=shift_data["shift_name"],
            shift_hours=shift_data["shift_hours"],
            active_trip=active_trip_info,
            check_in_time=shift_data.get("check_in_time"),
            data_origin=DataOrigin.SIMULATED
        )

    async def check_in(self, user_id: str, full_name: str, duty_id: Optional[str] = None) -> ConductorShiftResponse:
        shift_data = self._get_or_create_shift(user_id, full_name)
        if duty_id:
            shift_data["duty_id"] = duty_id
        shift_data["status"] = "CHECKED_IN"
        shift_data["check_in_time"] = datetime.now(timezone.utc).isoformat()
        return await self.get_shift(user_id, full_name)

    async def pair_bus(
        self,
        user_id: str,
        full_name: str,
        bus_number: str,
        route_number: str,
        trip_code: Optional[str] = None
    ) -> ConductorShiftResponse:
        shift_data = self._get_or_create_shift(user_id, full_name)
        shift_data["bus_number"] = bus_number
        shift_data["route_number"] = route_number
        shift_data["pairing_status"] = "PAIRED"
        shift_data["trip_status"] = "NOT_STARTED"
        shift_data["trip_id"] = f"trip-sim-{bus_number}"
        shift_data["trip_code"] = trip_code or f"TRIP-{bus_number}-ACTIVE"
        return await self.get_shift(user_id, full_name)

    async def start_trip(self, user_id: str, full_name: str, trip_id: Optional[str] = None) -> ConductorShiftResponse:
        shift_data = self._get_or_create_shift(user_id, full_name)
        shift_data["trip_status"] = "ACTIVE"
        if trip_id:
            shift_data["trip_id"] = trip_id
        bus_number = shift_data.get("bus_number", "205")
        await realtime_service.publish_event(RealtimeEvent(
            event_type=RealtimeEventType.TRIP_STATUS_UPDATE.value,
            entity_id=bus_number,
            data_origin="SIMULATED TELEMETRY",
            payload={"trip_id": shift_data.get("trip_id"), "status": "ACTIVE", "bus_number": bus_number}
        ))
        return await self.get_shift(user_id, full_name)

    async def complete_trip(
        self,
        user_id: str,
        full_name: str,
        trip_id: Optional[str] = None,
        notes: Optional[str] = None
    ) -> ConductorTripCompletionResponse:
        shift_data = self._get_or_create_shift(user_id, full_name)
        bus_number = shift_data.get("bus_number", "205")
        route_number = shift_data.get("route_number", "12")
        t_id = trip_id or shift_data.get("trip_id", f"trip-sim-{bus_number}")

        # Mark trip as completed
        shift_data["trip_status"] = "COMPLETED"
        telemetry = gps_simulator.get_bus_telemetry(bus_number)

        now = datetime.now(timezone.utc).isoformat()
        validated_count = self._validated_counts.get(bus_number, 18)

        await realtime_service.publish_event(RealtimeEvent(
            event_type=RealtimeEventType.TRIP_STATUS_UPDATE.value,
            entity_id=bus_number,
            data_origin="SIMULATED TELEMETRY",
            payload={"trip_id": t_id, "status": "COMPLETED", "bus_number": bus_number, "completed_at": now}
        ))

        return ConductorTripCompletionResponse(
            trip_id=t_id,
            bus_number=bus_number,
            route_number=route_number,
            status="COMPLETED",
            completed_at=now,
            trip_duration_minutes=42,
            final_occupancy_pct=float(telemetry.get("occupancy_pct", 41.8)),
            tickets_validated_count=validated_count,
            layover_minutes=15,
            notes=notes or "Trip completed according to corridor schedule.",
            data_origin=DataOrigin.SIMULATED
        )

conductor_service = ConductorService()
