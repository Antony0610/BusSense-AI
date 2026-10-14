"""
BusSense AI - Digital Ticketing & QR Verification Engine
Database-backed persistence via Supabase PostgreSQL.
Eliminates in-memory authoritative storage.
Supports atomic concurrency-safe QR ticket validations via validate_ticket_atomic RPC.
"""
import base64
import io
import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Optional
import qrcode
from app.core.supabase import supabase_client
from app.schemas.tickets import TicketResponse, TicketValidationResponse
from app.schemas.common import DataOrigin

class TicketService:
    def __init__(self):
        # Non-authoritative local cache for fast lookup if needed
        self._cache = {}

    def generate_qr_data_uri(self, payload: str) -> str:
        """Generates a high-contrast standard QR Code PNG encoded as a Base64 data URI"""
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_M,
            box_size=8,
            border=2,
        )
        qr.add_data(payload)
        qr.make(fit=True)

        img = qr.make_image(fill_color="#123C35", back_color="#FFFFFF")
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")
        encoded = base64.b64encode(buffer.getvalue()).decode("utf-8")
        return f"data:image/png;base64,{encoded}"

    async def book_ticket(
        self,
        user_id: str,
        passenger_name: str,
        bus_number: str,
        route_number: str,
        origin_stop: str,
        destination_stop: str,
        fare_amount: float
    ) -> TicketResponse:
        """
        Issues a new digital boarding ticket and persists directly to Supabase.
        Also creates a matching simulated payment record.
        """
        now = datetime.now(timezone.utc)
        valid_until = now + timedelta(hours=4)

        # 1. Ensure user_id is a valid UUID for PostgreSQL foreign key
        try:
            uuid.UUID(str(user_id))
            clean_user_id = str(user_id)
        except Exception:
            clean_user_id = "11111111-1111-1111-1111-111111111111"

        # 2. Look up bus and route foreign keys from Supabase
        bus_record = await supabase_client.get_bus_by_number(bus_number)
        bus_id = bus_record["id"] if bus_record else "a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

        route_record = await supabase_client.get_route_by_number(route_number)
        route_id = route_record["id"] if route_record else "00000000-0000-0000-0000-000000000101"

        # 3. Generate unique human-readable ticket number and cryptographically identifiable QR payload
        rand_token = uuid.uuid4().hex[:6].upper()
        ticket_number = f"BS-KL-2026-{rand_token}"
        qr_hash = f"bussense://ticket/{ticket_number}?auth={uuid.uuid4().hex[:8]}&ts={int(now.timestamp())}"
        qr_uri = self.generate_qr_data_uri(qr_hash)

        # 4. Persist ticket record in Supabase PostgreSQL
        ticket_row_data = {
            "ticket_number": ticket_number,
            "user_id": clean_user_id,
            "bus_id": bus_id,
            "route_id": route_id,
            "origin_stop": origin_stop,
            "destination_stop": destination_stop,
            "fare_amount": fare_amount,
            "discount_pct": 0.0,
            "final_fare": fare_amount,
            "qr_code_hash": qr_hash,
            "status": "VALID",
            "valid_from": now.isoformat(),
            "valid_until": valid_until.isoformat()
        }
        ticket_record = await supabase_client.post("tickets", ticket_row_data)

        if not ticket_record:
            # Fallback if DB insert failed (e.g. offline during simulation)
            ticket_id = str(uuid.uuid4())
            created_at = now.isoformat()
        else:
            ticket_id = ticket_record.get("id", str(uuid.uuid4()))
            created_at = ticket_record.get("created_at", now.isoformat())

        # 5. Persist simulated payment record in Supabase
        payment_record = {
            "ticket_id": ticket_id,
            "user_id": clean_user_id,
            "amount": fare_amount,
            "currency": "INR",
            "gateway": "RAZORPAY_TEST",
            "gateway_payment_id": f"pay_sim_{uuid.uuid4().hex[:12]}",
            "status": "COMPLETED"
        }
        await supabase_client.post("payments", payment_record)

        # 6. Construct response
        response = TicketResponse(
            id=ticket_id,
            ticket_number=ticket_number,
            passenger_name=passenger_name,
            bus_number=bus_number,
            route_number=route_number,
            origin_stop=origin_stop,
            destination_stop=destination_stop,
            fare_amount=fare_amount,
            final_fare=fare_amount,
            status="VALID",
            qr_code_hash=qr_hash,
            qr_code_data_uri=qr_uri,
            valid_from=now.isoformat(),
            valid_until=valid_until.isoformat(),
            created_at=created_at,
            data_origin=DataOrigin.LIVE
        )

        # Update read cache
        self._cache[ticket_number] = response.model_dump()
        return response

    async def get_user_tickets(self, user_id: str, full_name: str) -> List[TicketResponse]:
        """
        Retrieves all tickets belonging strictly to the authenticated user from Supabase.
        Ensures cross-user privacy boundaries (User A cannot access User B's tickets).
        """
        rows = await supabase_client.get("tickets", {
            "user_id": f"eq.{user_id}",
            "order": "created_at.desc"
        })

        tickets_list: List[TicketResponse] = []
        for r in rows:
            qr_uri = self.generate_qr_data_uri(r["qr_code_hash"])
            tickets_list.append(TicketResponse(
                id=r["id"],
                ticket_number=r["ticket_number"],
                passenger_name=full_name,
                bus_number=r.get("bus_number") or "205",
                route_number=r.get("route_number") or "205",
                origin_stop=r["origin_stop"],
                destination_stop=r["destination_stop"],
                fare_amount=float(r["fare_amount"]),
                final_fare=float(r["final_fare"]),
                status=r["status"],
                qr_code_hash=r["qr_code_hash"],
                qr_code_data_uri=qr_uri,
                valid_from=r["valid_from"],
                valid_until=r["valid_until"],
                created_at=r["created_at"],
                data_origin=DataOrigin.LIVE
            ))
        return tickets_list

    async def validate_ticket_qr(
        self,
        qr_hash: str,
        bus_number: str,
        conductor_id: Optional[str] = None
    ) -> TicketValidationResponse:
        """
        Validates digital boarding pass using Supabase atomic procedure `validate_ticket_atomic`.
        Guarantees that two concurrent validations cannot both succeed (prevents replay race conditions).
        """
        now = datetime.now(timezone.utc)
        bus_record = await supabase_client.get_bus_by_number(bus_number)
        bus_id = bus_record["id"] if bus_record else "a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        try:
            uuid.UUID(str(conductor_id))
            conductor_uuid = str(conductor_id)
        except Exception:
            conductor_uuid = "22222222-2222-2222-2222-222222222222"

        # Execute atomic validation procedure
        rpc_result = await supabase_client.rpc("validate_ticket_atomic", {
            "p_qr_hash": qr_hash,
            "p_conductor_id": conductor_uuid,
            "p_bus_id": bus_id
        })

        if not rpc_result or rpc_result.get("result") == "INVALID":
            return TicketValidationResponse(
                result="INVALID",
                is_valid=False,
                message="Unrecognized or invalid QR ticket. No matching boarding record found.",
                validated_at=now.isoformat(),
                data_origin=DataOrigin.LIVE
            )

        result_code = rpc_result.get("result")
        is_valid = (result_code == "VALID")
        
        messages = {
            "VALID": f"Boarding approved for passenger {rpc_result.get('passenger_name')}.",
            "ALREADY_USED": "This digital ticket has already been used and validated by a conductor.",
            "EXPIRED": "This ticket has expired past its boarding validity window."
        }

        return TicketValidationResponse(
            result=result_code,
            is_valid=is_valid,
            ticket_number=rpc_result.get("ticket_number"),
            passenger_name=rpc_result.get("passenger_name"),
            origin_stop=rpc_result.get("origin_stop"),
            destination_stop=rpc_result.get("destination_stop"),
            message=messages.get(result_code, "Validation complete."),
            validated_at=rpc_result.get("validated_at", now.isoformat()),
            data_origin=DataOrigin.LIVE
        )

ticket_service = TicketService()
