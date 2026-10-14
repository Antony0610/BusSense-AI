"""
BusSense AI - Payment Transaction Audit & Ledger Endpoints
Accesses persistent Supabase PostgreSQL `payments` table.
Guarded by strict RBAC:
- PASSENGER: Access only own payments
- AUTHORITY: Full audit access
- DRIVER: 403 Forbidden
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.tickets import PaymentResponse
from app.core.security import require_roles, get_current_user, TokenPayload
from app.core.supabase import supabase_client

router = APIRouter(prefix="/payments", tags=["Payments & Ledger"])

def _to_payment_response(p: dict) -> PaymentResponse:
    return PaymentResponse(
        id=str(p.get("id")),
        ticket_id=str(p.get("ticket_id")),
        amount=float(p.get("amount", 20.0)),
        currency=p.get("currency", "INR"),
        provider=p.get("provider", "SANDBOX"),
        status=p.get("status", "SUCCESS"),
        transaction_reference=p.get("transaction_reference"),
        created_at=str(p.get("created_at", "")),
        data_origin=DataOrigin.SIMULATED
    )

@router.get("/my", response_model=ApiResponse[List[PaymentResponse]])
async def get_my_payments(current_user: TokenPayload = Depends(require_roles(["PASSENGER", "AUTHORITY"]))):
    """
    Returns payment transaction history for the authenticated passenger.
    Multi-tenant isolation: Only returns payments belonging to the user's tickets.
    """
    # 1. Fetch user's tickets from Supabase
    user_tickets = await supabase_client.get("tickets", {"user_id": f"eq.{current_user.sub}"})
    if not user_tickets:
        return ApiResponse(
            data=[],
            data_origin=DataOrigin.SIMULATED,
            message="No payments found for current user"
        )

    ticket_ids = [str(t["id"]) for t in user_tickets]
    
    # 2. Fetch payments for those tickets
    all_payments = await supabase_client.get("payments", {"order": "created_at.desc", "limit": "50"})
    user_payments = [p for p in all_payments if str(p.get("ticket_id")) in ticket_ids]
    
    results = [_to_payment_response(p) for p in user_payments]
    return ApiResponse(
        data=results,
        data_origin=DataOrigin.SIMULATED,
        message=f"Retrieved {len(results)} payment records"
    )

@router.get("", response_model=ApiResponse[List[PaymentResponse]])
async def get_all_payments_audit(current_user: TokenPayload = Depends(require_roles(["AUTHORITY"]))):
    """
    Authority-only payment audit ledger endpoint.
    Returns all recent payment settlements.
    Rejects passengers and drivers with 403 Forbidden.
    """
    all_payments = await supabase_client.get("payments", {"order": "created_at.desc", "limit": "50"})
    results = [_to_payment_response(p) for p in all_payments]
    return ApiResponse(
        data=results,
        data_origin=DataOrigin.SIMULATED,
        message=f"Retrieved {len(results)} settlement records for transport authority audit"
    )
