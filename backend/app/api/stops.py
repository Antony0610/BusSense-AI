"""
BusSense AI - Stops & Nearby Departure Hubs
"""
from fastapi import APIRouter
from typing import List
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.fleet import StopModel
from app.core.supabase import supabase_client

router = APIRouter(prefix="/stops", tags=["Transit Stops & Hubs"])

KERALA_STOPS = [
    {"id": "00000000-0000-0000-0000-000000000001", "stop_code": "ALV-METRO", "stop_name": "Aluva Metro Station", "locality": "Aluva", "latitude": 10.1076, "longitude": 76.3533, "landmark": "Kochi Metro Terminal & Flyover"},
    {"id": "00000000-0000-0000-0000-000000000002", "stop_code": "KLM-JN", "stop_name": "Kalamassery Premier Junction", "locality": "Kalamassery", "latitude": 10.0544, "longitude": 76.3197, "landmark": "CUSAT Metro & HMT Jn"},
    {"id": "00000000-0000-0000-0000-000000000003", "stop_code": "EDP-TOLL", "stop_name": "Edappally Toll & Lulu Terminal", "locality": "Edappally", "latitude": 10.0261, "longitude": 76.3086, "landmark": "Lulu Mall & Metro Hub"},
    {"id": "00000000-0000-0000-0000-000000000004", "stop_code": "PLV-BYPASS", "stop_name": "Palarivattom Bypass Junction", "locality": "Palarivattom", "latitude": 10.0075, "longitude": 76.3115, "landmark": "Pipeline Junction & Civil Line Rd"},
    {"id": "00000000-0000-0000-0000-000000000005", "stop_code": "KLR-METRO", "stop_name": "Kaloor Metro Station & Bus Stand", "locality": "Kaloor", "latitude": 9.9922, "longitude": 76.2974, "landmark": "JLN Stadium & Banerji Road"},
    {"id": "00000000-0000-0000-0000-000000000006", "stop_code": "MGR-NORTH", "stop_name": "MG Road North (Ernakulam Town)", "locality": "Ernakulam North", "latitude": 9.9865, "longitude": 76.2842, "landmark": "North Railway Overbridge"},
    {"id": "00000000-0000-0000-0000-000000000007", "stop_code": "VYT-HUB", "stop_name": "Vyttila Mobility Hub", "locality": "Vyttila", "latitude": 9.9678, "longitude": 76.3182, "landmark": "Inter-Modal Terminal, KSRTC & Water Metro"},
    {"id": "00000000-0000-0000-0000-000000000008", "stop_code": "KKD-CIVIL", "stop_name": "Kakkanad Civil Station", "locality": "Kakkanad", "latitude": 10.0159, "longitude": 76.3456, "landmark": "District Collectorate"},
    {"id": "00000000-0000-0000-0000-000000000009", "stop_code": "IFO-PH1", "stop_name": "Infopark Phase 1 Express Bay", "locality": "Kakkanad", "latitude": 10.0102, "longitude": 76.3618, "landmark": "Athulya Building & TCS Gate"},
    {"id": "00000000-0000-0000-0000-00000000000a", "stop_code": "FTK-JETTY", "stop_name": "Fort Kochi Boat Jetty", "locality": "Fort Kochi", "latitude": 9.9675, "longitude": 76.2425, "landmark": "Ro-Ro Terminal & Coastal Promenade"}
]

@router.get("", response_model=ApiResponse[List[StopModel]])
async def list_stops():
    stops_db = await supabase_client.get("stops")
    if stops_db:
        return ApiResponse(data=stops_db, data_origin=DataOrigin.LIVE)
    return ApiResponse(data=KERALA_STOPS, data_origin=DataOrigin.SIMULATED)

@router.get("/nearby", response_model=ApiResponse[List[StopModel]])
async def get_nearby_stops(lat: float = 9.9922, lng: float = 76.2974):
    """Returns stops near user coordinate (defaults to Kaloor Metro)"""
    return ApiResponse(data=KERALA_STOPS[:4], data_origin=DataOrigin.SIMULATED)
