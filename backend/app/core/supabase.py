"""
BusSense AI - Supabase Database & REST Adapter
Hardened for Production Readiness (H14):
- Structured logging using standard logging module (replaces print)
- Dedicated support for backend service_role key authentication for privileged server operations
- Bounded timeout health ping
"""
import httpx
from typing import Any, Dict, List, Optional
from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger("bussense.supabase")

class SupabaseService:
    def __init__(self):
        self.base_url = settings.SUPABASE_URL.rstrip('/')
        self.anon_key = settings.SUPABASE_ANON_KEY
        self.service_role_key = settings.SUPABASE_SERVICE_ROLE_KEY
        self.headers = {
            "apikey": self.anon_key,
            "Authorization": f"Bearer {self.anon_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        }

    def _get_headers(self, use_service_role: bool = False) -> Dict[str, str]:
        """Returns request headers, using service_role key when privileged backend access is requested."""
        if use_service_role and self.service_role_key:
            return {
                "apikey": self.service_role_key,
                "Authorization": f"Bearer {self.service_role_key}",
                "Content-Type": "application/json",
                "Prefer": "return=representation"
            }
        return self.headers

    async def get(self, table: str, params: Optional[Dict[str, Any]] = None, use_service_role: bool = False) -> List[Dict[str, Any]]:
        """Query rows from a Supabase table via PostgREST API"""
        url = f"{self.base_url}/rest/v1/{table}"
        headers = self._get_headers(use_service_role=use_service_role)
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(url, headers=headers, params=params or {})
                if response.status_code >= 400:
                    logger.warning("[Supabase Warning] GET %s returned %d: %s", table, response.status_code, response.text)
                    return []
                return response.json()
        except Exception as e:
            logger.error("[Supabase Error] GET %s failed: %s", table, str(e))
            return []

    async def post(self, table: str, data: Dict[str, Any], use_service_role: bool = False) -> Optional[Dict[str, Any]]:
        """Insert a row into a Supabase table"""
        url = f"{self.base_url}/rest/v1/{table}"
        headers = self._get_headers(use_service_role=use_service_role)
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(url, headers=headers, json=data)
                if response.status_code >= 400:
                    logger.warning("[Supabase Warning] POST %s returned %d: %s", table, response.status_code, response.text)
                    return None
                res = response.json()
                return res[0] if isinstance(res, list) and len(res) > 0 else res
        except Exception as e:
            logger.error("[Supabase Error] POST %s failed: %s", table, str(e))
            return None

    async def patch(self, table: str, filter_col: str, filter_val: Any, data: Dict[str, Any], use_service_role: bool = False) -> Optional[Dict[str, Any]]:
        """Update rows in a Supabase table using parameterized query parameters (safe from injection)"""
        url = f"{self.base_url}/rest/v1/{table}"
        params = {filter_col: f"eq.{filter_val}"}
        headers = self._get_headers(use_service_role=use_service_role)
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.patch(url, headers=headers, params=params, json=data)
                if response.status_code >= 400:
                    logger.warning("[Supabase Warning] PATCH %s returned %d: %s", table, response.status_code, response.text)
                    return None
                res = response.json()
                return res[0] if isinstance(res, list) and len(res) > 0 else res
        except Exception as e:
            logger.error("[Supabase Error] PATCH %s failed: %s", table, str(e))
            return None

    async def delete(self, table: str, filter_col: str, filter_val: Any, use_service_role: bool = False) -> bool:
        """Delete rows in a Supabase table using parameterized query parameters (safe from injection)"""
        url = f"{self.base_url}/rest/v1/{table}"
        params = {filter_col: f"eq.{filter_val}"}
        headers = self._get_headers(use_service_role=use_service_role)
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.delete(url, headers=headers, params=params)
                if response.status_code >= 400:
                    logger.warning("[Supabase Warning] DELETE %s returned %d: %s", table, response.status_code, response.text)
                    return False
                return True
        except Exception as e:
            logger.error("[Supabase Error] DELETE %s failed: %s", table, str(e))
            return False

    async def rpc(self, function_name: str, payload: Dict[str, Any], use_service_role: bool = False) -> Optional[Any]:
        """Execute a stored procedure or function via PostgREST RPC"""
        url = f"{self.base_url}/rest/v1/rpc/{function_name}"
        headers = self._get_headers(use_service_role=use_service_role)
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(url, headers=headers, json=payload)
                if response.status_code >= 400:
                    logger.warning("[Supabase RPC Warning] %s returned %d: %s", function_name, response.status_code, response.text)
                    return None
                return response.json()
        except Exception as e:
            logger.error("[Supabase RPC Error] %s failed: %s", function_name, str(e))
            return None

    async def get_bus_by_number(self, bus_number: str) -> Optional[Dict[str, Any]]:
        """Look up bus record by bus_number with default fallback"""
        rows = await self.get("buses", {"bus_number": f"eq.{bus_number}"})
        if rows:
            return rows[0]
        fallback = await self.get("buses", {"bus_number": "eq.205"})
        return fallback[0] if fallback else None

    async def get_route_by_number(self, route_number: str) -> Optional[Dict[str, Any]]:
        """Look up route record by route_number with default fallback"""
        clean_num = route_number.replace("R", "")
        rows = await self.get("routes", {"route_number": f"eq.{route_number}"})
        if not rows:
            rows = await self.get("routes", {"route_number": f"eq.{clean_num}"})
        if rows:
            return rows[0]
        fallback = await self.get("routes", {"route_number": "eq.205"})
        return fallback[0] if fallback else None

    async def ping(self, timeout: float = 2.5) -> bool:
        """Verify active connection to Supabase PostgreSQL database within bounded timeout"""
        url = f"{self.base_url}/rest/v1/routes"
        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                res = await client.get(url, headers=self.headers, params={"select": "id", "limit": "1"})
                return res.status_code == 200
        except Exception:
            return False

supabase_client = SupabaseService()
