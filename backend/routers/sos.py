"""Emergency SOS alerts and passenger safety endpoints."""
from __future__ import annotations

from fastapi import APIRouter, status

from backend.database import record_sos_alert
from backend.schemas import SOSBroadcastRequest, SOSResponse

router = APIRouter(prefix="/api/sos", tags=["Emergency SOS & Safety Radar"])


@router.post("/broadcast", response_model=SOSResponse, status_code=status.HTTP_201_CREATED)
async def broadcast_sos(payload: SOSBroadcastRequest):
    """Trigger an instant high-priority SOS emergency alert broadcast to the Authority HUD."""
    alert = record_sos_alert(
        latitude=payload.latitude,
        longitude=payload.longitude,
        user_id=payload.user_id,
        bus_id=payload.bus_id,
        route_number=payload.route_number,
        message=payload.message,
    )
    return alert
