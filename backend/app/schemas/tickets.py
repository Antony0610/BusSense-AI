"""
BusSense AI - Ticketing & QR Validation Schemas
"""
from typing import Optional
from pydantic import BaseModel, Field
from app.schemas.common import DataOrigin

class BookingCreateRequest(BaseModel):
    trip_id: Optional[str] = None
    bus_number: str
    route_number: str
    origin_stop: str
    destination_stop: str
    passenger_name: str
    passenger_count: int = 1
    fare_amount: float
    payment_method: str = "SIMULATED_UPI"

class TicketResponse(BaseModel):
    id: str
    ticket_number: str
    passenger_name: str
    bus_number: str
    route_number: str
    origin_stop: str
    destination_stop: str
    fare_amount: float
    final_fare: float
    status: str # "BOOKED", "VALID", "USED", "EXPIRED", "CANCELLED"
    qr_code_hash: str
    qr_code_data_uri: str
    valid_from: str
    valid_until: str
    created_at: str
    data_origin: DataOrigin = DataOrigin.LIVE

class TicketValidationRequest(BaseModel):
    qr_code_hash: str
    bus_number: str
    conductor_id: Optional[str] = None

class TicketValidationResponse(BaseModel):
    result: str # "VALID", "INVALID", "ALREADY_USED", "EXPIRED"
    is_valid: bool
    ticket_number: Optional[str] = None
    passenger_name: Optional[str] = None
    origin_stop: Optional[str] = None
    destination_stop: Optional[str] = None
    message: str
    validated_at: str
    data_origin: DataOrigin = DataOrigin.LIVE

class PaymentResponse(BaseModel):
    id: str
    ticket_id: str
    amount: float
    currency: str
    provider: str
    status: str
    transaction_reference: Optional[str] = None
    created_at: str
    data_origin: DataOrigin = DataOrigin.SIMULATED

