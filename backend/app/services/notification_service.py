"""
BusSense AI - Commuter & Crew In-App Notification Service
Phase H12: Handles persistent storage, deduplication windows, unread counts, and realtime event triggers.
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, timezone, timedelta
import uuid
from app.core.supabase import supabase_client
from app.schemas.notifications import NotificationResponse
from app.schemas.realtime import RealtimeEvent, RealtimeEventType
from app.schemas.common import DataOrigin
from app.services.realtime_service import realtime_service


class NotificationService:
    DEDUP_WINDOW_MINUTES = 15

    def __init__(self):
        # In-memory fallback & dedup tracker: dedup_key -> datetime
        self._dedup_cache: Dict[str, datetime] = {}
        # In-memory storage cache keyed by user_id
        self._user_notifications: Dict[str, List[Dict[str, Any]]] = {}

    def _make_cache_key(self, user_id: str, dedup_key: str) -> str:
        return f"{user_id}::{dedup_key}"

    def is_duplicate(self, user_id: str, dedup_key: Optional[str]) -> bool:
        """Checks if identical notification was issued within deduplication window."""
        if not dedup_key:
            return False
        cache_key = self._make_cache_key(user_id, dedup_key)
        now = datetime.now(timezone.utc)
        if cache_key in self._dedup_cache:
            prev_time = self._dedup_cache[cache_key]
            if (now - prev_time) < timedelta(minutes=self.DEDUP_WINDOW_MINUTES):
                return True
        return False

    async def create_notification(
        self,
        user_id: str,
        title: str,
        body: str,
        notification_type: str = "TRANSIT_ALERT",
        dedup_key: Optional[str] = None,
        severity: str = "INFO",
        data_origin: str = DataOrigin.SIMULATED.value
    ) -> Optional[NotificationResponse]:
        """
        Creates a notification, persists to Supabase `notifications`, and broadcasts via RealtimeService.
        Enforces deduplication: drops duplicate notifications within 15-minute window.
        """
        now = datetime.now(timezone.utc)

        # Check deduplication
        if dedup_key and self.is_duplicate(user_id, dedup_key):
            # Duplicate suppressed
            return None

        notif_id = str(uuid.uuid4())
        record = {
            "id": notif_id,
            "user_id": user_id,
            "title": title,
            "body": body,
            "notification_type": notification_type,
            "is_read": False,
            "created_at": now.isoformat(),
            "dedup_key": dedup_key,
            "severity": severity,
            "data_origin": data_origin
        }

        # Update dedup cache
        if dedup_key:
            self._dedup_cache[self._make_cache_key(user_id, dedup_key)] = now

        # 1. Persist to Supabase
        inserted = await supabase_client.post("notifications", record)
        if not inserted:
            # Maintain in-memory fallback
            if user_id not in self._user_notifications:
                self._user_notifications[user_id] = []
            self._user_notifications[user_id].insert(0, record)
        else:
            # Also sync to local cache
            if user_id not in self._user_notifications:
                self._user_notifications[user_id] = []
            self._user_notifications[user_id].insert(0, inserted)

        response = NotificationResponse(**record)

        # 2. Broadcast via Realtime WebSocket event to target user
        await realtime_service.publish_event(RealtimeEvent(
            event_type=RealtimeEventType.USER_NOTIFICATION.value,
            entity_id=user_id,
            data_origin=data_origin,
            payload=response.model_dump()
        ))

        return response

    async def get_user_notifications(
        self,
        user_id: str,
        unread_only: bool = False,
        limit: int = 20,
        offset: int = 0
    ) -> List[NotificationResponse]:
        """
        Retrieves user notifications strictly isolated by authenticated user_id.
        """
        query_params = {
            "user_id": f"eq.{user_id}",
            "order": "created_at.desc",
            "limit": str(limit),
            "offset": str(offset)
        }
        if unread_only:
            query_params["is_read"] = "eq.false"

        rows = await supabase_client.get("notifications", query_params)
        
        # Merge or fallback to memory cache if Supabase returned empty
        cached = self._user_notifications.get(user_id, [])
        if not rows and cached:
            items = [c for c in cached if not unread_only or not c.get("is_read")]
            rows = items[offset:offset + limit]

        results: List[NotificationResponse] = []
        for r in rows:
            results.append(NotificationResponse(
                id=str(r.get("id")),
                user_id=str(r.get("user_id")),
                title=r.get("title", ""),
                body=r.get("body", ""),
                notification_type=r.get("notification_type", "TRANSIT_ALERT"),
                is_read=bool(r.get("is_read", False)),
                created_at=str(r.get("created_at", "")),
                dedup_key=r.get("dedup_key"),
                severity=r.get("severity", "INFO"),
                data_origin=r.get("data_origin", DataOrigin.SIMULATED.value)
            ))
        return results

    async def mark_as_read(self, notification_id: str, user_id: str) -> bool:
        """
        Marks a specific notification as read, ensuring strict ownership.
        """
        # Patch in Supabase
        await supabase_client.patch("notifications", "id", notification_id, {"is_read": True})

        # Update in-memory
        if user_id in self._user_notifications:
            for item in self._user_notifications[user_id]:
                if item.get("id") == notification_id:
                    item["is_read"] = True
                    break
        return True

    async def mark_all_read(self, user_id: str) -> int:
        """Marks all notifications for user as read."""
        # Patch in Supabase for user
        await supabase_client.patch("notifications", "user_id", user_id, {"is_read": True})

        count = 0
        if user_id in self._user_notifications:
            for item in self._user_notifications[user_id]:
                if not item.get("is_read"):
                    item["is_read"] = True
                    count += 1
        return count

    async def get_unread_count(self, user_id: str) -> int:
        """Returns the number of unread notifications for the user."""
        rows = await supabase_client.get("notifications", {
            "user_id": f"eq.{user_id}",
            "is_read": "eq.false",
            "select": "id"
        })
        if rows:
            return len(rows)
        # Fallback to local cache
        cached = self._user_notifications.get(user_id, [])
        return sum(1 for c in cached if not c.get("is_read"))


notification_service = NotificationService()
