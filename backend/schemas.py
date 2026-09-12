"""Pydantic schemas for request and response validation."""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Literal, Optional
from pydantic import BaseModel, Field


# --- Bus Fleet Schemas ---
class BusResponse(BaseModel):
    id: Optional[str] = None
    bus_id: str
    operator_type: Literal["KSRTC", "PRIVATE"]
    route_number: str
    capacity: int = 50
    registration_number: str
    status: str = "active"
    safety_score: float = 9.4
    sprite_type: str = "ksrtc_standard"
    passenger_count: int = 0
    occupancy_percentage: float = 0.0
    seat_availability: int = 50
    crowd_tier: Literal["GREEN", "YELLOW", "RED"] = "GREEN"
    latitude: float = 8.5241
    longitude: float = 76.9366
    speed_kmh: float = 35.0
    heading_deg: float = 0.0
    eta_minutes: int = 5
    comfort_index: float = 100.0


# --- Telemetry Ingestion Schemas ---
class TelemetryIngestRequest(BaseModel):
    bus_id: str
    route_number: str
    latitude: float
    longitude: float
    passenger_count: int
    capacity: int = 50
    speed_kmh: float = 35.0
    heading_deg: float = 0.0
    source: str = "edge_yolo"
    timestamp: Optional[str] = None


class TelemetryResponse(BaseModel):
    status: str = "ingested"
    bus_id: str
    passenger_count: int
    occupancy_percentage: float
    seat_availability: int
    crowd_tier: Literal["GREEN", "YELLOW", "RED"]
    timestamp: str


# --- Smart QR Ticketing & Seat Reservation Schemas ---
class TicketBookRequest(BaseModel):
    user_id: str
    bus_id: str
    route_number: str
    origin_stop: str
    destination_stop: str
    seat_number: str
    base_fare: float = 40.00


class TicketResponse(BaseModel):
    ticket_id: str
    user_id: str
    bus_id: str
    route_number: str
    origin_stop: str
    destination_stop: str
    seat_number: str
    base_fare: float
    discount_pct: float
    final_fare: float
    qr_code_hash: str
    valid_until: str
    status: str = "active"
    created_at: str


class TicketValidateRequest(BaseModel):
    qr_code_hash: str
    bus_id: str


class TicketValidateResponse(BaseModel):
    valid: bool
    ticket_id: Optional[str] = None
    seat_number: Optional[str] = None
    status: str
    message: str


# --- Emergency SOS & Passenger Safety Schemas ---
class SOSBroadcastRequest(BaseModel):
    user_id: Optional[str] = None
    bus_id: Optional[str] = None
    route_number: Optional[str] = None
    latitude: float
    longitude: float
    message: str = "Emergency SOS Triggered by Passenger"


class SOSResponse(BaseModel):
    status: str = "active"
    sos_id: str
    bus_id: Optional[str] = None
    route_number: Optional[str] = None
    latitude: float
    longitude: float
    created_at: str


# --- Dispatch & Rebalancing Schemas ---
class DispatchBusRequest(BaseModel):
    route_number: str
    operator_type: Literal["KSRTC", "PRIVATE"] = "KSRTC"
    reason: str = "Surge Relief Dispatch"
    admin_id: Optional[str] = None


class DispatchResponse(BaseModel):
    message: str
    bus_id: str
    route_number: str
    operator_type: str
    dispatched_at: str


class HourlyForecastItem(BaseModel):
    hour: int
    predicted_occupancy: float
    risk_level: Literal["OPTIMAL", "MODERATE", "OVERCROWDED"]


class DemandForecastResponse(BaseModel):
    route_number: str
    current_occupancy: float
    predicted_hourly: list[HourlyForecastItem]
    peak_risk_hours: list[int]
    recommended_action: str
    model_type: str = "RandomForestRegressor"
    inference_time_ms: float


class RebalanceRecommendationResponse(BaseModel):
    id: str
    source_route: str
    target_route: str
    recommended_bus_ids: list[str]
    reason: str
    predicted_congestion_reduction_pct: float
    status: str
    created_at: str


# --- Passenger Reports ---
class PassengerReportRequest(BaseModel):
    user_id: Optional[str] = None
    bus_id: Optional[str] = None
    report_type: Literal["overcrowding", "delay", "comfort_issue", "emergency"] = "overcrowding"
    message: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class PassengerReportResponse(BaseModel):
    id: str
    status: str = "received"
    message: str
    created_at: str
