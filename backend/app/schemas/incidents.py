"""
BusSense AI - Incidents & Service Alerts Schemas
"""
from typing import Optional
from pydantic import BaseModel, Field

class IncidentCreateRequest(BaseModel):
    bus_number: str
    route_number: Optional[str] = None
    category: str # 'VEHICLE_ISSUE', 'ROUTE_OBSTRUCTION', 'OVERCROWDING', 'DELAY', 'SAFETY_MEDICAL', 'OTHER'
    severity: str = "WARNING" # 'INFO', 'LOW', 'WARNING', 'CRITICAL'
    title: str
    description: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class IncidentResponse(BaseModel):
    id: str
    category: str
    severity: str
    title: str
    description: str
    bus_number: Optional[str] = None
    status: str
    created_at: str
    resolved_at: Optional[str] = None
    reporter_id: Optional[str] = None

class AlertResponse(BaseModel):
    id: str
    title: str
    message: str
    severity: str
    affected_route: Optional[str] = None
    is_active: bool
    created_at: str
