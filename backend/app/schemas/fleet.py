"""
BusSense AI - Fleet, Corridors, Stops & Telemetry Schemas
"""
from typing import Optional, List
from pydantic import BaseModel, Field
from app.schemas.common import CrowdLevel, DataOrigin

class StopModel(BaseModel):
    id: str
    stop_code: str
    stop_name: str
    locality: str
    latitude: float
    longitude: float
    landmark: Optional[str] = None

class RouteStopModel(BaseModel):
    stop_id: str
    stop_code: str
    stop_name: str
    stop_order: int
    distance_from_start_km: float
    scheduled_travel_mins: int

class RouteModel(BaseModel):
    id: str
    route_number: str
    route_name: str
    corridor_type: str
    start_stop: str
    end_stop: str
    distance_km: float
    estimated_duration_mins: int
    color_code: str
    stops: Optional[List[RouteStopModel]] = None

class BusTelemetry(BaseModel):
    bus_id: str
    bus_number: str
    registration_number: str
    operator_type: str
    route_number: str
    route_name: str
    capacity: int
    passenger_count: int
    occupancy_pct: float
    crowd_level: CrowdLevel
    speed_kmh: float
    heading_deg: float
    latitude: float
    longitude: float
    current_stop: str
    next_stop: str
    eta_next_stop_mins: int
    is_ac: bool = False
    safety_score: float = 98.5
    data_origin: DataOrigin = DataOrigin.SIMULATED

class ActiveTripModel(BaseModel):
    trip_id: str
    trip_code: str
    bus: BusTelemetry
    route: RouteModel
    status: str
    scheduled_departure: str
    scheduled_arrival: str

class TripResponse(BaseModel):
    trip_id: str
    trip_code: str
    bus_id: str
    bus_number: str
    route_id: str
    route_number: str
    current_status: str
    current_stop: str
    next_stop: str
    started_at: str
    estimated_arrival: str
    occupancy_pct: float
    crowd_level: CrowdLevel
    data_origin: DataOrigin = DataOrigin.SIMULATED

class LocationResponse(BaseModel):
    bus_id: str
    bus_number: str
    registration_number: str
    latitude: float
    longitude: float
    speed_kmh: float
    heading_deg: float
    current_stop: str
    next_stop: str
    eta_next_stop_mins: int
    timestamp: str
    data_origin: DataOrigin = DataOrigin.SIMULATED

class CrowdResponse(BaseModel):
    bus_id: str
    bus_number: str
    occupancy_pct: float
    passenger_count: int
    capacity: int
    crowd_level: CrowdLevel
    detection_source: str = "YOLOv8_CCTV_Camera_SIMULATED"
    privacy_standard: str = "PERSON_COUNTING_ONLY_NO_FACIAL_RECOGNITION"
    timestamp: str
    data_origin: DataOrigin = DataOrigin.SIMULATED

