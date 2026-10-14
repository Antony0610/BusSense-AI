"""
BusSense AI - Conductor / Driver Operational Schemas
Pydantic v2 schemas for shift management, bus pairing, and trip execution.
"""
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field
from app.schemas.common import DataOrigin, CrowdLevel

class ConductorShiftResponse(BaseModel):
    duty_id: str
    staff_name: str
    staff_id: str
    role: str = "DRIVER_CONDUCTOR"
    status: str = "CHECKED_IN"  # "CHECKED_IN", "NOT_CHECKED_IN"
    pairing_status: str = "PAIRED"  # "PAIRED", "UNPAIRED"
    bus_number: Optional[str] = "205"
    route_number: Optional[str] = "12"
    shift_name: str = "Morning Peak Corridor Shift"
    shift_hours: str = "06:00 – 14:00"
    active_trip: Optional[Dict[str, Any]] = None
    check_in_time: Optional[str] = None
    data_origin: DataOrigin = DataOrigin.SIMULATED

class ConductorCheckInRequest(BaseModel):
    duty_id: Optional[str] = "DUTY-KL-402"

class ConductorPairRequest(BaseModel):
    bus_number: str
    route_number: str
    trip_code: Optional[str] = None

class ConductorTripActionRequest(BaseModel):
    trip_id: Optional[str] = None
    bus_number: Optional[str] = None

class ConductorTripCompletionResponse(BaseModel):
    trip_id: str
    bus_number: str
    route_number: str
    status: str = "COMPLETED"
    completed_at: str
    trip_duration_minutes: int = 42
    final_occupancy_pct: float = 45.0
    tickets_validated_count: int = 18
    layover_minutes: int = 15
    notes: Optional[str] = None
    data_origin: DataOrigin = DataOrigin.SIMULATED
