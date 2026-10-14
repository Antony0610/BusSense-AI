"""
BusSense AI - Authenticated Commuter Profile, Preferences, Favorites & Issue Reporting API
Strictly enforces JWT token authentication and user ownership isolation.
"""
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.security import get_current_user, TokenPayload, require_roles
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.user import (
    UserProfileResponse,
    UserProfileUpdateRequest,
    UserPreferencesModel,
    SavedPlaceModel,
    SavedPlaceCreateRequest,
    PassengerReportCreateRequest,
    PassengerReportResponse,
    DeactivateAccountRequest,
    DataExportResponse,
)
from app.services.user_service import user_service

router = APIRouter(prefix="/user", tags=["Passenger Profile & Account Management"])

@router.get("/profile", response_model=ApiResponse[UserProfileResponse])
async def get_passenger_profile(current_user: TokenPayload = Depends(get_current_user)):
    """Fetch current authenticated commuter profile."""
    profile = await user_service.get_profile(
        user_id=current_user.sub,
        email=current_user.email,
        full_name=current_user.full_name or "Commuter",
        role=current_user.role
    )
    return ApiResponse(
        data=UserProfileResponse(**profile),
        data_origin=DataOrigin.LIVE,
        message="Profile retrieved successfully"
    )

@router.patch("/profile", response_model=ApiResponse[UserProfileResponse])
async def update_passenger_profile(
    req: UserProfileUpdateRequest,
    current_user: TokenPayload = Depends(get_current_user)
):
    """Updates user profile (e.g. full name, preferred language)."""
    updated = await user_service.update_profile(
        user_id=current_user.sub,
        email=current_user.email,
        full_name=req.full_name,
        preferred_language=req.preferred_language
    )
    return ApiResponse(
        data=UserProfileResponse(**updated),
        data_origin=DataOrigin.LIVE,
        message="Profile updated successfully"
    )

@router.get("/favorites", response_model=ApiResponse[List[SavedPlaceModel]])
async def get_saved_places(current_user: TokenPayload = Depends(get_current_user)):
    """Fetches commuter saved favorite destinations."""
    places = await user_service.get_saved_places(current_user.sub)
    return ApiResponse(
        data=[SavedPlaceModel(**p) for p in places],
        data_origin=DataOrigin.LIVE,
        message=f"Retrieved {len(places)} saved places"
    )

@router.post("/favorites", response_model=ApiResponse[SavedPlaceModel], status_code=status.HTTP_201_CREATED)
async def add_saved_place(
    req: SavedPlaceCreateRequest,
    current_user: TokenPayload = Depends(get_current_user)
):
    """Saves a new commuter favorite destination."""
    created = await user_service.add_saved_place(
        user_id=current_user.sub,
        label=req.label,
        item_type=req.item_type,
        reference_id=req.reference_id,
        address=req.address
    )
    return ApiResponse(
        data=SavedPlaceModel(**created),
        data_origin=DataOrigin.LIVE,
        message="Saved place added successfully"
    )

@router.delete("/favorites/{place_id}", response_model=ApiResponse[Dict[str, Any]])
async def delete_saved_place(
    place_id: str,
    current_user: TokenPayload = Depends(get_current_user)
):
    """Deletes a saved place strictly owned by the commuter."""
    await user_service.delete_saved_place(current_user.sub, place_id)
    return ApiResponse(
        data={"deleted": True, "place_id": place_id},
        data_origin=DataOrigin.LIVE,
        message="Saved place deleted successfully"
    )

@router.get("/preferences", response_model=ApiResponse[UserPreferencesModel])
async def get_user_preferences(current_user: TokenPayload = Depends(get_current_user)):
    """Fetches passenger notification, language, and theme preferences."""
    prefs = user_service.get_preferences(current_user.sub)
    return ApiResponse(
        data=UserPreferencesModel(**prefs),
        data_origin=DataOrigin.LIVE,
        message="Preferences retrieved"
    )

@router.put("/preferences", response_model=ApiResponse[UserPreferencesModel])
async def update_user_preferences(
    prefs: UserPreferencesModel,
    current_user: TokenPayload = Depends(get_current_user)
):
    """Updates passenger preferences."""
    updated = user_service.update_preferences(current_user.sub, prefs.model_dump())
    return ApiResponse(
        data=UserPreferencesModel(**updated),
        data_origin=DataOrigin.LIVE,
        message="Preferences updated"
    )

@router.post("/reports", response_model=ApiResponse[PassengerReportResponse], status_code=status.HTTP_201_CREATED)
async def submit_passenger_report(
    req: PassengerReportCreateRequest,
    current_user: TokenPayload = Depends(get_current_user)
):
    """Submits an issue or feedback report from a commuter."""
    report = await user_service.create_passenger_report(
        user_id=current_user.sub,
        category=req.category,
        title=req.title,
        description=req.description,
        bus_number=req.bus_number,
        route_number=req.route_number
    )
    return ApiResponse(
        data=PassengerReportResponse(**report),
        data_origin=DataOrigin.LIVE,
        message="Issue report received and logged"
    )

@router.get("/export-data", response_model=ApiResponse[DataExportResponse])
async def export_passenger_data(current_user: TokenPayload = Depends(get_current_user)):
    """Generates a structured export package of commuter data."""
    export_pkg = await user_service.export_user_data(
        user_id=current_user.sub,
        email=current_user.email,
        full_name=current_user.full_name or "Commuter"
    )
    return ApiResponse(
        data=DataExportResponse(**export_pkg),
        data_origin=DataOrigin.SIMULATED,
        message="Data export generated"
    )

@router.post("/deactivate", response_model=ApiResponse[Dict[str, Any]])
async def deactivate_passenger_account(
    req: DeactivateAccountRequest,
    current_user: TokenPayload = Depends(get_current_user)
):
    """Safely deactivates commuter account upon confirmation."""
    if not req.confirm:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Account deactivation requires explicit confirmation."
        )
    await user_service.deactivate_account(current_user.sub)
    return ApiResponse(
        data={"deactivated": True, "user_id": current_user.sub},
        data_origin=DataOrigin.LIVE,
        message="Account deactivation requested. Prototype mode: credentials flagged."
    )
