"""
BusSense AI - Passenger AI Transit Assistant Endpoints
"""
from fastapi import APIRouter, Depends
from app.schemas.common import ApiResponse, DataOrigin
from app.schemas.ai import ChatQueryRequest, ChatQueryResponse
from app.services.ai_provider import get_ai_provider
from app.core.security import get_current_user, TokenPayload

router = APIRouter(prefix="/ai", tags=["Passenger AI Assistant"])

@router.post("/chat", response_model=ApiResponse[ChatQueryResponse])
async def chat_with_assistant(
    req: ChatQueryRequest,
    current_user: TokenPayload = Depends(get_current_user)
):
    """
    RAG-grounded response combining static transport rules, live bus data tools,
    ticket store, and journey context.
    Requires authenticated commuter session.
    """
    provider = get_ai_provider()
    
    # Extract query text and context
    query_text = req.get_query_text()
    active_bus = req.active_bus_context
    dest = req.destination_context
    ticket_id = None

    if req.context:
        if req.context.bus_number:
            active_bus = req.context.bus_number
        if req.context.destination:
            dest = req.context.destination
        if req.context.ticket_id:
            ticket_id = req.context.ticket_id

    response = provider.generate_structured_response(
        question=query_text,
        user_location=req.user_location or "Kaloor Metro Station, Kochi",
        active_bus=active_bus,
        destination=dest,
        ticket_id=ticket_id,
        user_id=current_user.sub,
    )

    return ApiResponse(
        data=response,
        data_origin=DataOrigin.RECOMMENDATION,
        message="Assistant response generated"
    )

@router.get("/knowledge-sources", response_model=ApiResponse[list])
async def list_knowledge_sources():
    from app.services.rag_service import rag_assistant
    sources = [{"id": doc["id"], "title": doc["title"], "source": doc["source"]} for doc in rag_assistant.knowledge]
    return ApiResponse(data=sources, data_origin=DataOrigin.LIVE)
