"""
BusSense AI - Commuter & Crew Notification Endpoints
Phase H12: In-app notification retrieval, mark-as-read mutations, unread counts, and push status disclosures.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from app.core.security import get_current_user, require_roles, TokenPayload
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.notifications import (
    NotificationResponse,
    NotificationCreateRequest,
    UnreadCountResponse,
    MarkAllReadResponse
)
from app.services.notification_service import notification_service
from app.services.push_service import push_provider

router = APIRouter(prefix="/notifications", tags=["In-App Notifications"])


@router.get("", response_model=ApiResponse[List[NotificationResponse]])
async def list_notifications(
    unread_only: bool = Query(False, description="Filter for unread notifications only"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: TokenPayload = Depends(get_current_user)
):
    """
    Retrieves in-app notifications strictly for the authenticated commuter or crew member.
    Enforces user isolation: rejects cross-user queries.
    """
    items = await notification_service.get_user_notifications(
        user_id=current_user.sub,
        unread_only=unread_only,
        limit=limit,
        offset=offset
    )
    return ApiResponse(
        data=items,
        data_origin=DataOrigin.SIMULATED,
        message=f"Retrieved {len(items)} notifications"
    )


@router.get("/unread-count", response_model=ApiResponse[UnreadCountResponse])
async def get_unread_notification_count(
    current_user: TokenPayload = Depends(get_current_user)
):
    """
    Returns unread notification badge count for the authenticated user.
    """
    count = await notification_service.get_unread_count(current_user.sub)
    return ApiResponse(
        data=UnreadCountResponse(user_id=current_user.sub, unread_count=count),
        data_origin=DataOrigin.SIMULATED,
        message=f"{count} unread notifications"
    )


@router.patch("/{notification_id}/read", response_model=ApiResponse[bool])
async def mark_notification_read(
    notification_id: str,
    current_user: TokenPayload = Depends(get_current_user)
):
    """
    Marks a specific notification as read.
    """
    success = await notification_service.mark_as_read(notification_id, current_user.sub)
    return ApiResponse(
        data=success,
        data_origin=DataOrigin.SIMULATED,
        message="Notification marked as read"
    )


@router.post("/mark-all-read", response_model=ApiResponse[MarkAllReadResponse])
async def mark_all_notifications_read(
    current_user: TokenPayload = Depends(get_current_user)
):
    """
    Marks all notifications for the authenticated user as read.
    """
    count = await notification_service.mark_all_read(current_user.sub)
    return ApiResponse(
        data=MarkAllReadResponse(user_id=current_user.sub, marked_count=count),
        data_origin=DataOrigin.SIMULATED,
        message=f"{count} notifications marked as read"
    )


@router.post("", response_model=ApiResponse[NotificationResponse], status_code=status.HTTP_201_CREATED)
async def create_notification(
    req: NotificationCreateRequest,
    current_user: TokenPayload = Depends(require_roles(["AUTHORITY", "ADMIN"]))
):
    """
    Authority / Admin endpoint to issue a targeted notification.
    """
    created = await notification_service.create_notification(
        user_id=req.user_id,
        title=req.title,
        body=req.body,
        notification_type=req.notification_type,
        dedup_key=req.dedup_key,
        severity=req.severity
    )
    if not created:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Duplicate notification suppressed by deduplication policy"
        )
    return ApiResponse(
        data=created,
        data_origin=DataOrigin.SIMULATED,
        message="Notification dispatched successfully"
    )


@router.get("/push-status", response_model=ApiResponse[dict])
async def get_push_status():
    """
    Honestly discloses operating-system push notification status (DEFERRED).
    """
    status_info = push_provider.get_status()
    return ApiResponse(
        data=status_info,
        data_origin=DataOrigin.SIMULATED,
        message="Push notification provider status retrieved"
    )
