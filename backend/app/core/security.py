"""
BusSense AI - Authentication & Role-Based Authorization
Hardened implementation: Strict 401 on missing/revoked tokens, strict 403 on role mismatch,
no hardcoded fallback passwords.
"""
import bcrypt
from datetime import datetime, timedelta, timezone
from typing import Optional, List, Set
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from pydantic import BaseModel
from app.core.config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login", auto_error=False)

# In-memory revoked tokens store (for session logout)
REVOKED_TOKENS: Set[str] = set()

def revoke_token(token: str) -> None:
    """Adds a JWT token to the revoked tokens blacklist"""
    if token:
        REVOKED_TOKENS.add(token)

def is_token_revoked(token: str) -> bool:
    """Checks whether a token has been revoked via logout"""
    return token in REVOKED_TOKENS

class TokenPayload(BaseModel):
    sub: str # user_id or email
    email: Optional[str] = None
    role: str # 'PASSENGER', 'DRIVER_CONDUCTOR', 'AUTHORITY', 'ADMIN'
    full_name: Optional[str] = ""
    exp: Optional[int] = None

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password with native bcrypt. Safe against timing attacks, rejects plain passwords."""
    if not plain_password or not hashed_password:
        return False
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8"),
            hashed_password.encode("utf-8")
        )
    except Exception:
        return False

def get_password_hash(password: str) -> str:
    """Hash password using native bcrypt with salt rounds=12"""
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": int(expire.timestamp())})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

async def get_current_user(token: Optional[str] = Depends(oauth2_scheme)) -> TokenPayload:
    """
    Validate JWT token.
    Enforces strict HTTP 401 UNAUTHORIZED on missing, invalid, or revoked tokens.
    NO demo-mode auto-login bypass.
    """
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication credentials were not provided",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if is_token_revoked(token):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked. Please log in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        email: Optional[str] = payload.get("email")
        role: str = payload.get("role")
        full_name: str = payload.get("full_name", "Transit User")
        if user_id is None or role is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return TokenPayload(sub=user_id, email=email, role=role, full_name=full_name)
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

def require_roles(allowed_roles: List[str]):
    """Decorator / dependency to enforce strict Role-Based Access Control (403 Forbidden)"""
    def role_checker(user: TokenPayload = Depends(get_current_user)):
        if user.role not in allowed_roles and user.role != "ADMIN":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Requires one of roles: {allowed_roles}. Current role: {user.role}"
            )
        return user
    return role_checker
