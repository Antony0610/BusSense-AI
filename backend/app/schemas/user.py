"""
BusSense AI - User Profile, Preferences, Saved Places & Reporting Schemas
Pydantic v2 schemas for authenticated commuter management.
"""
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from app.schemas.common import UserRole

class UserProfileResponse(BaseModel):
    id: str
    email: str
    full_name: str
    phone_number: Optional[str] = None
    role: UserRole = UserRole.PASSENGER
    preferred_language: str = "en"
    account_status: str = "ACTIVE"
    created_at: Optional[str] = None

class UserProfileUpdateRequest(BaseModel):
    full_name: Optional[str] = Field(None, min_length=2, max_length=100)
    preferred_language: Optional[str] = Field(None, max_length=10)

class UserPreferencesModel(BaseModel):
    master_notifications: bool = True
    bus_arrival: bool = True
    journey_updates: bool = True
    crowd_alerts: bool = True
    service_alerts: bool = True
    ticket_updates: bool = True
    language: str = "en"
    theme_mode: str = "system"

class SavedPlaceModel(BaseModel):
    id: str
    label: str
    item_type: str = "DESTINATION"
    reference_id: str
    address: Optional[str] = None
    created_at: Optional[str] = None

class SavedPlaceCreateRequest(BaseModel):
    label: str = Field(..., min_length=1, max_length=100)
    item_type: str = "DESTINATION"
    reference_id: str = Field(..., min_length=1, max_length=150)
    address: Optional[str] = None

class PassengerReportCreateRequest(BaseModel):
    category: str = Field(..., description="BUS_VEHICLE, ROUTE_DELAY, TICKET_PAYMENT, LOCATION_ETA, CROWD_FORECAST, APP_BUG, OTHER")
    title: str = Field(..., min_length=3, max_length=150)
    description: str = Field(..., min_length=5, max_length=1000)
    bus_number: Optional[str] = None
    route_number: Optional[str] = None

class PassengerReportResponse(BaseModel):
    id: str
    reporter_id: str
    category: str
    title: str
    description: str
    bus_number: Optional[str] = None
    route_number: Optional[str] = None
    status: str = "REPORTED"
    created_at: str

class DeactivateAccountRequest(BaseModel):
    confirm: bool = False

class DataExportResponse(BaseModel):
    user_id: str
    full_name: str
    email: str
    profile: Dict[str, Any]
    saved_places: List[Dict[str, Any]]
    preferences: Dict[str, Any]
    ticket_summary: Dict[str, Any]
    export_format: str = "JSON"
    truth_label: str = "PROTOTYPE DATA EXPORT"
