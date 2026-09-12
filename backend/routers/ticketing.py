"""Dynamic Smart QR Ticketing and Seat Map endpoints."""
from __future__ import annotations

from fastapi import APIRouter, HTTPException, status

from backend.database import book_ticket, validate_ticket
from backend.schemas import (
    TicketBookRequest,
    TicketResponse,
    TicketValidateRequest,
    TicketValidateResponse,
)

router = APIRouter(prefix="/api/tickets", tags=["Smart QR Ticketing & Seat Map"])


@router.post("/book", response_model=TicketResponse, status_code=status.HTTP_201_CREATED)
async def create_ticket(payload: TicketBookRequest):
    """Book a digital ticket with dynamic green discount and reserve a visual seat."""
    ticket = book_ticket(
        user_id=payload.user_id,
        bus_id=payload.bus_id,
        route_number=payload.route_number,
        origin_stop=payload.origin_stop,
        destination_stop=payload.destination_stop,
        seat_number=payload.seat_number,
        base_fare=payload.base_fare,
    )
    return ticket


@router.post("/validate", response_model=TicketValidateResponse)
async def verify_conductor_ticket(payload: TicketValidateRequest):
    """Conductor validation endpoint for cryptographically signed QR tickets."""
    result = validate_ticket(qr_code_hash=payload.qr_code_hash, bus_id=payload.bus_id)
    if not result.get("valid"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result.get("message", "Invalid ticket"),
        )
    return result
