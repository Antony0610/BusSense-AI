"""
BusSense AI - AI Transit Assistant & RAG Schemas
"""
from enum import Enum
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class AIResponseType(str, Enum):
    KNOWLEDGE = "KNOWLEDGE"
    LIVE_DATA = "LIVE_DATA"
    PREDICTION = "PREDICTION"
    RECOMMENDATION = "RECOMMENDATION"
    TICKET_DATA = "TICKET_DATA"
    ACTIVE_JOURNEY = "ACTIVE_JOURNEY"
    INSUFFICIENT_INFORMATION = "INSUFFICIENT_INFORMATION"

class AISourceItem(BaseModel):
    id: Optional[str] = None
    title: str
    source_type: str # "KNOWLEDGE", "LIVE_DATA", "PREDICTION", "RECOMMENDATION", "TICKET_DATA"
    snippet: Optional[str] = None
    reference: Optional[str] = None

class AIActionItem(BaseModel):
    label: str
    action_type: str # "VIEW_BUS", "SHOW_TICKET", "TRACK_HUD", "EXPLORE_ROUTES", "CROWD_FORECAST", "ASK_QUERY"
    payload: Optional[Dict[str, Any]] = None

class ChatContext(BaseModel):
    bus_number: Optional[str] = None
    route_id: Optional[str] = None
    ticket_id: Optional[str] = None
    destination: Optional[str] = None

class ChatMessage(BaseModel):
    role: str # "user", "assistant", "system"
    content: str
    sources: Optional[List[str]] = Field(default_factory=list)

class ChatQueryRequest(BaseModel):
    question: Optional[str] = None
    message: Optional[str] = None
    user_location: Optional[str] = "Kaloor Metro Station, Kochi"
    active_bus_context: Optional[str] = None
    destination_context: Optional[str] = None
    context: Optional[ChatContext] = None

    def get_query_text(self) -> str:
        return (self.message or self.question or "").strip()

class ChatQueryResponse(BaseModel):
    answer: str
    response_type: str = "KNOWLEDGE"
    sources: List[str] = Field(default_factory=list)
    source_items: List[AISourceItem] = Field(default_factory=list)
    actions: List[AIActionItem] = Field(default_factory=list)
    suggested_actions: List[str] = Field(default_factory=list)
    confidence: Optional[float] = 0.95
    data_origin: str = "DEVELOPMENT FALLBACK"
