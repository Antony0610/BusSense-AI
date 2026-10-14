"""
BusSense AI - Ticketing, Digital Boarding Passes & Conductor QR Validation
Database-backed persistence via Supabase PostgreSQL.
"""
from fastapi import APIRouter, HTTPException, Depends
from typing import List
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.tickets import (
    BookingCreateRequest,
    TicketResponse,
    TicketValidationRequest,
    TicketValidationResponse
)
from app.core.security import get_current_user, require_roles, TokenPayload
from app.services.ticket_service import ticket_service

router = APIRouter(prefix="/tickets", tags=["Digital Ticketing & QR Scanner"])

@router.post("/book", response_model=ApiResponse[TicketResponse])
async def book_ticket(
    req: BookingCreateRequest,
    current_user: TokenPayload = Depends(get_current_user)
):
    """
    Issues a new digital boarding pass with high-contrast QR token.
    Persists ticket and payment record to Supabase.
    Requires authenticated commuter session.
    """
    ticket = await ticket_service.book_ticket(
        user_id=current_user.sub,
        passenger_name=req.passenger_name or current_user.full_name,
        bus_number=req.bus_number,
        route_number=req.route_number,
        origin_stop=req.origin_stop,
        destination_stop=req.destination_stop,
        fare_amount=req.fare_amount
    )
    return ApiResponse(
        data=ticket,
        data_origin=DataOrigin.LIVE,
        message="Ticket booked successfully"
    )

@router.get("/my", response_model=ApiResponse[List[TicketResponse]])
async def get_my_tickets(current_user: TokenPayload = Depends(get_current_user)):
    """
    Returns active and recent digital boarding passes for the authenticated passenger.
    Queries Supabase database filtered strictly by user_id to enforce user privacy.
    """
    tickets_list = await ticket_service.get_user_tickets(
        user_id=current_user.sub,
        full_name=current_user.full_name
    )
    return ApiResponse(
        data=tickets_list,
        data_origin=DataOrigin.LIVE
    )

@router.post("/validate", response_model=ApiResponse[TicketValidationResponse])
async def validate_ticket_qr(
    req: TicketValidationRequest,
    current_user: TokenPayload = Depends(require_roles(["DRIVER_CONDUCTOR", "AUTHORITY"]))
):
    """
    Conductor QR scanner verification endpoint.
    Protected strictly by RBAC: only DRIVER_CONDUCTOR or AUTHORITY may validate boarding passes.
    Executes atomic row-level locked transaction in Supabase to eliminate double-use race conditions.
    """
    validation = await ticket_service.validate_ticket_qr(
        qr_hash=req.qr_code_hash,
        bus_number=req.bus_number,
        conductor_id=current_user.sub
    )
    return ApiResponse(
        data=validation,
        data_origin=DataOrigin.LIVE,
        message=f"Validation result: {validation.result}"
    )
