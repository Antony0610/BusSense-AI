"""
BusSense AI - Transit Data Ingestion Schemas
Defines structured input validation models for external transit feeds:
- AVL / GPS vehicle location feeds
- CCTV-derived aggregate passenger headcounts (strictly zero-biometric)
- Route schedules, stops, and timetables
- Incidents and service disruptions
"""
from typing import List, Optional
from datetime import datetime, timezone
from pydantic import BaseModel, Field, field_validator
from app.schemas.common import DataOrigin, CrowdLevel

# Greater Kochi Bounding Box Coordinates
KOCHI_MIN_LAT = 9.8000
KOCHI_MAX_LAT = 10.3500
KOCHI_MIN_LNG = 76.1500
KOCHI_MAX_LNG = 76.5500
MAX_PHYSICAL_SPEED_KMH = 120.0

class GpsTelemetryRecord(BaseModel):
    bus_id: Optional[str] = None
    bus_number: str = Field(..., min_length=1, max_length=16, description="Bus route or fleet number, e.g. '205'")
    latitude: float = Field(..., description="Latitude in decimal degrees within Greater Kochi")
    longitude: float = Field(..., description="Longitude in decimal degrees within Greater Kochi")
    speed_kmh: float = Field(default=0.0, ge=0.0, le=MAX_PHYSICAL_SPEED_KMH, description="Vehicle speed in km/h")
    heading_deg: float = Field(default=0.0, ge=0.0, lt=360.0, description="Vehicle heading in degrees (0-359.9)")
    timestamp: str = Field(..., description="ISO 8601 UTC timestamp of GPS fix")
    sequence_number: Optional[int] = Field(default=None, ge=0, description="Monotonically increasing packet sequence")
    feed_id: Optional[str] = Field(default="AVL_FEED_01", description="Identifier of the ingestion provider")
    is_historical: bool = Field(default=False, description="Flag indicating retrospective batch replay")
    data_origin: DataOrigin = Field(default=DataOrigin.LIVE, description="Origin truth label")

    @field_validator("latitude")
    @classmethod
    def validate_latitude(cls, v: float) -> float:
        if not (KOCHI_MIN_LAT <= v <= KOCHI_MAX_LAT):
            raise ValueError(
                f"Latitude {v:.5f} is outside Greater Kochi operational corridor "
                f"[{KOCHI_MIN_LAT}, {KOCHI_MAX_LAT}]"
            )
        return round(v, 6)

    @field_validator("longitude")
    @classmethod
    def validate_longitude(cls, v: float) -> float:
        if not (KOCHI_MIN_LNG <= v <= KOCHI_MAX_LNG):
            raise ValueError(
                f"Longitude {v:.5f} is outside Greater Kochi operational corridor "
                f"[{KOCHI_MIN_LNG}, {KOCHI_MAX_LNG}]"
            )
        return round(v, 6)

class GpsTelemetryBatchRequest(BaseModel):
    feed_id: str = Field(..., description="AVL provider feed identifier")
    records: List[GpsTelemetryRecord] = Field(..., min_length=1, max_length=500)

class CctvOccupancyIngestRecord(BaseModel):
    bus_number: str = Field(..., min_length=1, max_length=16)
    timestamp: str = Field(...)
    raw_person_count: int = Field(..., ge=0, description="Aggregate body detection count")
    stabilized_person_count: int = Field(..., ge=0, description="Temporal window EMA count")
    capacity: int = Field(..., gt=0, le=120, description="Licensed passenger capacity")
    confidence_score: float = Field(default=0.88, ge=0.0, le=1.0)
    model_version: str = Field(default="yolov8n_coco", description="Detection model version")
    camera_id: str = Field(default="BUS_DOOR_CAM_01")
    privacy_standard: str = Field(
        default="PERSON_COUNTING_ONLY_NO_BIOMETRICS",
        description="Mandatory zero-biometrics privacy guarantee"
    )
    data_origin: DataOrigin = Field(default=DataOrigin.CV_REPLAY)

    @field_validator("privacy_standard")
    @classmethod
    def enforce_zero_biometrics(cls, v: str) -> str:
        if v != "PERSON_COUNTING_ONLY_NO_BIOMETRICS":
            raise ValueError(
                "Biometric facial or demographic tracking is strictly prohibited. "
                "privacy_standard must be 'PERSON_COUNTING_ONLY_NO_BIOMETRICS'."
            )
        return v

class RouteStopIngestRecord(BaseModel):
    stop_id: str = Field(..., description="Unique stop identifier")
    stop_name: str = Field(..., min_length=2)
    stop_sequence: int = Field(..., ge=1)
    latitude: float = Field(...)
    longitude: float = Field(...)
    scheduled_arrival_time: Optional[str] = Field(default=None, description="HH:MM:SS format")
    scheduled_departure_time: Optional[str] = Field(default=None, description="HH:MM:SS format")

    @field_validator("latitude")
    @classmethod
    def validate_stop_lat(cls, v: float) -> float:
        if not (KOCHI_MIN_LAT <= v <= KOCHI_MAX_LAT):
            raise ValueError(f"Stop latitude {v} outside Greater Kochi [{KOCHI_MIN_LAT}, {KOCHI_MAX_LAT}]")
        return round(v, 6)

    @field_validator("longitude")
    @classmethod
    def validate_stop_lng(cls, v: float) -> float:
        if not (KOCHI_MIN_LNG <= v <= KOCHI_MAX_LNG):
            raise ValueError(f"Stop longitude {v} outside Greater Kochi [{KOCHI_MIN_LNG}, {KOCHI_MAX_LNG}]")
        return round(v, 6)

class RouteScheduleIngestRequest(BaseModel):
    route_number: str = Field(..., min_length=1)
    route_name: str = Field(..., min_length=3)
    origin: str = Field(..., min_length=2)
    destination: str = Field(..., min_length=2)
    corridor_key: Optional[str] = None
    stops: List[RouteStopIngestRecord] = Field(..., min_length=2)
    frequency_mins: int = Field(default=15, ge=3, le=180)
    operator_type: str = Field(default="KSRTC")
    is_active: bool = Field(default=True)

class DisruptionIngestRecord(BaseModel):
    route_number: str = Field(...)
    cause: str = Field(..., description="TRAFFIC_CONGESTION, ROAD_MAINTENANCE, WEATHER, VEHICLE_BREAKDOWN, ACCIDENT")
    severity: str = Field(..., description="LOW, MEDIUM, HIGH, CRITICAL")
    description: str = Field(..., min_length=5)
    affected_stops: List[str] = Field(default_factory=list)
    reported_at: Optional[str] = None
    estimated_duration_mins: int = Field(default=30, ge=5, le=1440)
    is_active: bool = Field(default=True)

class IngestRecordResult(BaseModel):
    identifier: str
    status: str # "ACCEPTED", "REJECTED"
    reason: Optional[str] = None

class IngestSummaryResponse(BaseModel):
    feed_id: Optional[str] = None
    feed_type: str
    total_received: int
    accepted: int
    rejected: int
    results: List[IngestRecordResult]
    freshness_status: str # "FRESH", "STALE", "HISTORICAL"
    data_origin: DataOrigin
    processed_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())

# =========================================================================
# Phase H17: External Provider Integration, Map-Matching & Pilot Monitoring
# =========================================================================

class ExternalProviderRegisterRequest(BaseModel):
    provider_id: str = Field(..., min_length=3, max_length=64, description="Unique provider ID, e.g. 'KSRTC_AVL_GATEWAY'")
    provider_name: str = Field(..., min_length=3, max_length=128, description="Descriptive organization or system name")
    allowed_feed_types: List[str] = Field(default_factory=lambda: ["AVL_GPS"], description="Allowed feeds: AVL_GPS, CCTV_OCCUPANCY, ROUTE_SCHEDULE, DISRUPTION")
    contact_email: str = Field(..., description="Technical point of contact email")

class ExternalProviderResponse(BaseModel):
    provider_id: str
    provider_name: str
    api_key: Optional[str] = None # Only returned upon registration
    api_key_masked: str
    allowed_feed_types: List[str]
    is_active: bool
    created_at: str
    revoked_at: Optional[str] = None
    revocation_reason: Optional[str] = None
    ingested_records_count: int = 0

class ProviderRevocationRequest(BaseModel):
    reason: str = Field(..., min_length=5, max_length=256, description="Audit reason for revoking provider integration")

class MapMatchingResult(BaseModel):
    bus_number: str
    matched_corridor: Optional[str] = None
    nearest_stop: Optional[str] = None
    distance_to_corridor_meters: float
    is_off_route: bool
    off_route_threshold_meters: float = 500.0
    telemetry_latitude: float
    telemetry_longitude: float
    evaluated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())

class PilotMonitoringDashboardResponse(BaseModel):
    total_active_vehicles: int
    connected_vehicles_count: int
    fresh_telemetry_count: int
    stale_telemetry_count: int
    unavailable_telemetry_count: int
    freshness_ratio_pct: float
    live_vs_simulated_breakdown: dict
    occupancy_tier_distribution: dict
    prediction_status: str
    ingestion_stats: dict
    cv_processing_status: str
    active_providers_count: int
    revoked_providers_count: int
    data_origins: dict
    privacy_standard: str
    greater_kochi_bbox: dict
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())

