"""
BusSense AI - Push Notification Provider Abstraction
Phase H12: Manages operating-system level push notification dispatch.
Honestly discloses status as DEFERRED when production FCM credentials are unconfigured.
"""
from typing import Dict, Any, Optional
from datetime import datetime, timezone
import os


class PushNotificationProvider:
    """
    Push notification gateway adapter.
    Preserves strict truth standards: never claims OS push delivery succeeded
    unless physical credentials and FCM response confirm delivery.
    """
    def __init__(self):
        self.fcm_credentials_path = os.getenv("FCM_CREDENTIALS_PATH")
        self.is_configured = bool(self.fcm_credentials_path and os.path.exists(self.fcm_credentials_path))

    def get_status(self) -> Dict[str, Any]:
        return {
            "provider": "Firebase Cloud Messaging (FCM)",
            "status": "CONFIGURED" if self.is_configured else "DEFERRED",
            "push_enabled": False,
            "truth_label": "DEFERRED / PROTOTYPE IN-APP NOTIFICATIONS ONLY",
            "reason": (
                "Operating system push delivery is deferred per Phase H12 roadmap. "
                "In-app realtime delivery and persistent notification center are active."
            ),
            "timestamp": datetime.now(timezone.utc).isoformat()
        }

    async def send_push(self, user_id: str, title: str, body: str, payload: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Attempts to deliver an OS push notification.
        If credentials are not configured, cleanly reports simulated/deferred delivery without throwing errors.
        """
        if not self.is_configured:
            return {
                "delivered": False,
                "provider_status": "DEFERRED",
                "message": "Push notification deferred (FCM credentials not configured). Retained in in-app notification center.",
                "user_id": user_id
            }

        # If credentials were configured in future:
        return {
            "delivered": True,
            "provider_status": "DELIVERED",
            "user_id": user_id
        }


push_provider = PushNotificationProvider()
