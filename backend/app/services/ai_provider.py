"""
BusSense AI - AI Provider Interface & Pluggable LLM Provider Adapters (Phase H11)
Supports:
  - BaseAIProvider abstraction
  - DevelopmentFallbackAIProvider grounded in KnowledgeIndexer and controlled live tools
  - ExternalLLMProvider with bounded timeouts, structured parsing, and graceful fallback
  - Strict classification: Never claims to be external cloud LLM when unconfigured
"""
import os
import json
import logging
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
import httpx
from app.schemas.ai import ChatQueryResponse, AIResponseType
from app.core.config import settings

logger = logging.getLogger("bussense.ai_provider")

class BaseAIProvider(ABC):
    """
    Abstract AI Provider Interface for BusSense AI Transit Assistant.
    """
    @abstractmethod
    def generate_answer(self, prompt: str) -> str:
        """Generates raw text answer."""
        pass

    @abstractmethod
    def generate_structured_response(
        self,
        question: str,
        user_location: str = "Kaloor Metro Station, Kochi",
        active_bus: Optional[str] = None,
        destination: Optional[str] = None,
        ticket_id: Optional[str] = None,
        user_id: Optional[str] = None,
    ) -> ChatQueryResponse:
        """Generates a structured transit assistant response with provenance, sources, and actions."""
        pass


class DevelopmentFallbackAIProvider(BaseAIProvider):
    """
    Development & Offline-capable Fallback AI Provider.
    Explicitly labeled as DEVELOPMENT FALLBACK.
    Executes grounded RAG retrieval from KnowledgeIndexer,
    invokes controlled transport tools, and enforces anti-hallucination guardrails.
    """
    def __init__(self, rag_service=None):
        self.rag_service = rag_service

    def generate_answer(self, prompt: str) -> str:
        res = self.generate_structured_response(question=prompt)
        return res.answer

    def generate_structured_response(
        self,
        question: str,
        user_location: str = "Kaloor Metro Station, Kochi",
        active_bus: Optional[str] = None,
        destination: Optional[str] = None,
        ticket_id: Optional[str] = None,
        user_id: Optional[str] = None,
    ) -> ChatQueryResponse:
        if self.rag_service is None:
            from app.services.rag_service import rag_assistant
            self.rag_service = rag_assistant

        return self.rag_service.answer_query(
            question=question,
            user_location=user_location,
            active_bus=active_bus,
            destination=destination,
            ticket_id=ticket_id,
            user_id=user_id,
        )


class ExternalLLMProvider(BaseAIProvider):
    """
    Server-side Pluggable LLM Provider (e.g. Gemini / OpenAI / Custom Endpoint).
    Requirements:
      - Bounded request timeouts (5.0s max)
      - Graceful fallback to DevelopmentFallbackAIProvider upon timeout or failure
      - Strict structured schema conformance
      - Never leaks credentials or system prompts
    """
    def __init__(
        self,
        api_key: Optional[str] = None,
        endpoint_url: Optional[str] = None,
        model_name: str = "gemini-1.5-flash",
        timeout_seconds: float = 5.0,
        fallback_provider: Optional[BaseAIProvider] = None,
    ):
        self.api_key = api_key or getattr(settings, "GEMINI_API_KEY", None)
        self.endpoint_url = endpoint_url
        self.model_name = model_name
        self.timeout_seconds = timeout_seconds
        self.fallback = fallback_provider or DevelopmentFallbackAIProvider()

    def generate_answer(self, prompt: str) -> str:
        res = self.generate_structured_response(question=prompt)
        return res.answer

    def generate_structured_response(
        self,
        question: str,
        user_location: str = "Kaloor Metro Station, Kochi",
        active_bus: Optional[str] = None,
        destination: Optional[str] = None,
        ticket_id: Optional[str] = None,
        user_id: Optional[str] = None,
    ) -> ChatQueryResponse:
        if not self.api_key:
            return self.fallback.generate_structured_response(
                question=question,
                user_location=user_location,
                active_bus=active_bus,
                destination=destination,
                ticket_id=ticket_id,
                user_id=user_id,
            )

        # Attempt structured invocation with bounded timeout
        try:
            # When external API is configured, request is sent here via httpx with bounded timeout
            httpx_timeout = httpx.Timeout(self.timeout_seconds, connect=min(1.0, self.timeout_seconds))
            with httpx.Client(timeout=httpx_timeout) as client:
                if self.endpoint_url:
                    resp = client.post(
                        self.endpoint_url,
                        headers={"Authorization": f"Bearer {self.api_key}"},
                        json={"query": question, "context": {"location": user_location}}
                    )
                    if resp.status_code == 200:
                        payload = resp.json()
                        return ChatQueryResponse(**payload)
                    else:
                        logger.warning(f"External LLM returned status {resp.status_code}; falling back.")
                else:
                    # In absence of active production endpoint, safely fall back
                    pass
        except Exception as e:
            logger.warning(f"External LLM call failed or timed out ({e}); falling back to verified RAG.")

        # Graceful fallback to verified grounded RAG
        return self.fallback.generate_structured_response(
            question=question,
            user_location=user_location,
            active_bus=active_bus,
            destination=destination,
            ticket_id=ticket_id,
            user_id=user_id,
        )


def get_ai_provider() -> BaseAIProvider:
    """
    Provider factory. Inspects environment configuration and returns the active provider.
    Defaults to DevelopmentFallbackAIProvider when no external credentials are configured.
    """
    gemini_key = getattr(settings, "GEMINI_API_KEY", None) or os.getenv("GEMINI_API_KEY")
    openai_key = getattr(settings, "OPENAI_API_KEY", None) or os.getenv("OPENAI_API_KEY")

    if gemini_key or openai_key:
        return ExternalLLMProvider(api_key=gemini_key or openai_key)
    return DevelopmentFallbackAIProvider()
