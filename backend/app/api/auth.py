"""
BusSense AI - Authentication & Role Selection Endpoints
Hardened implementation: Controlled development credentials with verified bcrypt hashes,
no plaintext password fallback, strict logout session revocation.
"""
from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel
from typing import Optional
from app.core.config import settings, DEV_ACCOUNTS
from app.core.security import (
    create_access_token,
    verify_password,
    get_current_user,
    revoke_token,
    oauth2_scheme,
    TokenPayload
)
from app.core.supabase import supabase_client
from app.schemas.common import ApiResponse, DataOrigin

router = APIRouter(prefix="/auth", tags=["Authentication"])

class LoginRequest(BaseModel):
    email: str
    password: str

class SwitchRoleRequest(BaseModel):
    role: str # 'PASSENGER', 'DRIVER_CONDUCTOR', 'AUTHORITY'

@router.post("/login", response_model=ApiResponse[dict])
async def login(credentials: LoginRequest):
    """
    Authenticate user and return JWT access token with role routing metadata.
    Accepts verified development demo accounts or queries Supabase users.
    Validates strictly with bcrypt. No plain text fallbacks.
    """
    matched = None
    
    # 1. In development / demo mode, check controlled development credentials.
    # Strictly disabled in production or when DEMO_MODE is False.
    if settings.ENVIRONMENT != "production" and settings.DEMO_MODE:
        for acc in DEV_ACCOUNTS.values():
            if acc["email"].lower() == credentials.email.lower():
                matched = acc
                break

    # 2. Query Supabase database if not matched in controlled dev accounts
    if not matched:
        users = await supabase_client.get("users", {"email": f"eq.{credentials.email}"})
        if users:
            matched = users[0]

    # 3. Verify credentials strictly with bcrypt
    if not matched:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials. Account not found."
        )

    stored_hash = matched.get("hashed_password")
    if not stored_hash or not verify_password(credentials.password, stored_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password."
        )

    token_data = {
        "sub": matched["id"],
        "email": matched["email"],
        "role": matched["role"],
        "full_name": matched["full_name"]
    }
    access_token = create_access_token(token_data)

    # Route navigation destination based on role
    route_target = {
        "PASSENGER": "/passenger/home",
        "DRIVER_CONDUCTOR": "/driver/cockpit",
        "AUTHORITY": "/authority/command"
    }.get(matched["role"], "/passenger/home")

    return ApiResponse(
        data={
            "access_token": access_token,
            "token_type": "bearer",
            "user": {
                "id": matched["id"],
                "email": matched["email"],
                "role": matched["role"],
                "full_name": matched["full_name"]
            },
            "redirect_route": route_target
        },
        data_origin=DataOrigin.LIVE,
        message="Authentication successful"
    )

@router.post("/logout", response_model=ApiResponse[dict])
async def logout(
    token: str = Depends(oauth2_scheme),
    user: TokenPayload = Depends(get_current_user)
):
    """
    Revokes the current JWT session token and invalidates active session.
    Subsequent requests with this token will return 401 Unauthorized.
    """
    revoke_token(token)
    return ApiResponse(
        data={"revoked": True, "user_id": user.sub},
        data_origin=DataOrigin.LIVE,
        message="Successfully logged out and session revoked"
    )

@router.get("/me", response_model=ApiResponse[dict])
async def get_current_user_profile(user: TokenPayload = Depends(get_current_user)):
    """Protected profile endpoint returning current token identity"""
    return ApiResponse(
        data={
            "id": user.sub,
            "email": user.email,
            "role": user.role,
            "full_name": user.full_name
        },
        data_origin=DataOrigin.LIVE
    )

@router.post("/switch-demo-role", response_model=ApiResponse[dict])
async def switch_demo_role(req: SwitchRoleRequest):
    """Convenience endpoint for testing role transitions in development mode"""
    if not settings.DEMO_MODE:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Demo role switching is disabled outside development/demo mode."
        )

    role_key = req.role.lower().split('_')[0]
    matched = DEV_ACCOUNTS.get(role_key, DEV_ACCOUNTS["passenger"])
    
    token = create_access_token({
        "sub": matched["id"],
        "email": matched["email"],
        "role": matched["role"],
        "full_name": matched["full_name"]
    })

    redirect_route = {
        "PASSENGER": "/passenger/home",
        "DRIVER_CONDUCTOR": "/driver/cockpit",
        "AUTHORITY": "/authority/command"
    }.get(matched["role"], "/passenger/home")

    return ApiResponse(
        data={
            "access_token": token,
            "user": {
                "id": matched["id"],
                "email": matched["email"],
                "role": matched["role"],
                "full_name": matched["full_name"]
            },
            "redirect_route": redirect_route
        },
        data_origin=DataOrigin.SIMULATED,
        message=f"Switched role to {matched['role']}"
    )
