"""
BusSense AI - Common Enumerations & Schema Wrappers
"""
from enum import Enum
from typing import Generic, TypeVar, Optional, Any, List
from pydantic import BaseModel, Field

T = TypeVar("T")

class DataOrigin(str, Enum):
    LIVE = "LIVE DATA"
    SIMULATED = "SIMULATED DATA"
    PREDICTION = "PREDICTION"
    RECOMMENDATION = "RECOMMENDATION"
    HUMAN_DECISION = "HUMAN DECISION"
    CV_REPLAY = "CV REPLAY"
    ESTIMATE = "ESTIMATE"
    SYNTHETIC = "SYNTHETIC DATA"

class CrowdLevel(str, Enum):
    LOW = "LOW"
    MODERATE = "MODERATE"
    CROWDED = "CROWDED"

class UserRole(str, Enum):
    PASSENGER = "PASSENGER"
    DRIVER_CONDUCTOR = "DRIVER_CONDUCTOR"
    AUTHORITY = "AUTHORITY"
    ADMIN = "ADMIN"

class ApiResponse(BaseModel, Generic[T]):
    success: bool = True
    message: str = "Operation successful"
    data: Optional[T] = None
    data_origin: DataOrigin = DataOrigin.SIMULATED
    timestamp: str = Field(default_factory=lambda: "")
