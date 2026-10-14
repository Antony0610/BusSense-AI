"""
BusSense AI - Supabase Database & REST Adapter
"""
import httpx
from typing import Any, Dict, List, Optional
from app.core.config import settings

class SupabaseService:
    def __init__(self):
        self.base_url = settings.SUPABASE_URL.rstrip('/')
        self.anon_key = settings.SUPABASE_ANON_KEY
        self.headers = {
            "apikey": self.anon_key,
            "Authorization": f"Bearer {self.anon_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        }

    async def get(self, table: str, params: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """Query rows from a Supabase table via PostgREST API"""
        url = f"{self.base_url}/rest/v1/{table}"
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(url, headers=self.headers, params=params or {})
            if response.status_code >= 400:
                print(f"[Supabase Error] GET {table} failed: {response.text}")
                return []
            return response.json()

    async def post(self, table: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Insert a row into a Supabase table"""
        url = f"{self.base_url}/rest/v1/{table}"
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(url, headers=self.headers, json=data)
            if response.status_code >= 400:
                print(f"[Supabase Error] POST {table} failed: {response.text}")
                return None
            res = response.json()
            return res[0] if isinstance(res, list) and len(res) > 0 else res

    async def patch(self, table: str, filter_col: str, filter_val: Any, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update rows in a Supabase table using parameterized query parameters (safe from injection)"""
        url = f"{self.base_url}/rest/v1/{table}"
        params = {filter_col: f"eq.{filter_val}"}
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.patch(url, headers=self.headers, params=params, json=data)
            if response.status_code >= 400:
                print(f"[Supabase Error] PATCH {table} failed: {response.text}")
                return None
            res = response.json()
            return res[0] if isinstance(res, list) and len(res) > 0 else res

    async def delete(self, table: str, filter_col: str, filter_val: Any) -> bool:
        """Delete rows in a Supabase table using parameterized query parameters (safe from injection)"""
        url = f"{self.base_url}/rest/v1/{table}"
        params = {filter_col: f"eq.{filter_val}"}
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.delete(url, headers=self.headers, params=params)
            if response.status_code >= 400:
                print(f"[Supabase Error] DELETE {table} failed: {response.text}")
                return False
            return True

    async def rpc(self, function_name: str, payload: Dict[str, Any]) -> Optional[Any]:
        """Execute a stored procedure or function via PostgREST RPC"""
        url = f"{self.base_url}/rest/v1/rpc/{function_name}"
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(url, headers=self.headers, json=payload)
            if response.status_code >= 400:
                print(f"[Supabase RPC Error] {function_name} failed: {response.text}")
                return None
            return response.json()

    async def get_bus_by_number(self, bus_number: str) -> Optional[Dict[str, Any]]:
        """Look up bus record by bus_number with default fallback"""
        rows = await self.get("buses", {"bus_number": f"eq.{bus_number}"})
        if rows:
            return rows[0]
        # Fallback to primary corridor bus
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
        # Fallback to primary corridor route
        fallback = await self.get("routes", {"route_number": "eq.205"})
        return fallback[0] if fallback else None

    async def ping(self) -> bool:
        """Verify active connection to Supabase PostgreSQL database"""
        url = f"{self.base_url}/rest/v1/routes"
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                res = await client.get(url, headers=self.headers, params={"select": "id", "limit": "1"})
                return res.status_code == 200
        except Exception as e:
            print(f"[Supabase Ping Failed] {e}")
            return False

supabase_client = SupabaseService()

