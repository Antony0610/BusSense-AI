"""
BusSense AI - Phase H5 Batch 3: AI Assistant & Grounded RAG Tests
Tests:
  - Authentication & Authorization
  - Response type classification (KNOWLEDGE, LIVE_DATA, PREDICTION, RECOMMENDATION, TICKET_DATA, ACTIVE_JOURNEY, INSUFFICIENT_INFORMATION)
  - Grounded source citations with snippet references
  - User ticket retrieval & isolation
  - Anti-hallucination guardrail fallback
"""
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token

client = TestClient(app)

def get_auth_headers(role: str = "PASSENGER", sub: str = "test-user-p1", email: str = "commuter@bussense.ai"):
    token = create_access_token({"sub": sub, "role": role, "email": email})
    return {"Authorization": f"Bearer {token}"}

def test_ai_chat_requires_auth():
    """Unauthenticated requests must be rejected with 401."""
    resp = client.post("/api/ai/chat", json={"question": "Where is Bus 205?"})
    assert resp.status_code == 401

def test_ai_live_data_response():
    """Asking for bus arrival returns LIVE_DATA with telemetry source."""
    headers = get_auth_headers()
    resp = client.post("/api/ai/chat", headers=headers, json={"question": "When will Bus 205 arrive?"})
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["response_type"] == "LIVE_DATA"
    assert "205" in data["answer"]
    assert any("GPS" in s for s in data["sources"])
    assert len(data["source_items"]) > 0
    assert any(a["action_type"] in ["VIEW_BUS", "EXPLORE_ROUTES"] for a in data["actions"])

def test_ai_crowd_prediction_response():
    """Asking for future crowd returns PREDICTION with 4-horizon forecaster source."""
    headers = get_auth_headers()
    resp = client.post("/api/ai/chat", headers=headers, json={"question": "Will Bus 205 get crowded in future forecast?"})
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["response_type"] == "PREDICTION"
    assert "Crowd Forecast" in data["answer"]
    assert any("Forecaster" in s or "Prediction" in s for s in data["sources"])
    assert data["data_origin"] == "MACHINE LEARNING PREDICTION"

def test_ai_recommendation_response():
    """Asking for recommendation explains 3 factors and returns RECOMMENDATION."""
    headers = get_auth_headers()
    resp = client.post("/api/ai/chat", headers=headers, json={"question": "Which bus is less crowded and why was it recommended?"})
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["response_type"] == "RECOMMENDATION"
    assert "Lower Crowding" in data["answer"]
    assert "Corridor Priority" in data["answer"]
    assert any("Recommendation" in s for s in data["sources"])

def test_ai_knowledge_response():
    """Asking for privacy/occupancy rules returns KNOWLEDGE from approved docs."""
    headers = get_auth_headers()
    resp = client.post("/api/ai/chat", headers=headers, json={"question": "How do you estimate crowd and camera privacy?"})
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["response_type"] == "KNOWLEDGE"
    assert "YOLOv8" in data["answer"]
    assert "NOT perform facial recognition" in data["answer"]

def test_ai_active_journey_context():
    """Contextual question with active bus returns ACTIVE_JOURNEY next stop and ETA."""
    headers = get_auth_headers()
    resp = client.post("/api/ai/chat", headers=headers, json={
        "question": "What is my next stop?",
        "context": {
            "bus_number": "205",
            "destination": "Vyttila Mobility Hub"
        }
    })
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["response_type"] == "ACTIVE_JOURNEY"
    assert "stop" in data["answer"].lower() or "kaloor" in data["answer"].lower()
    assert any(a["action_type"] == "TRACK_HUD" for a in data["actions"])

def test_ai_insufficient_information_fallback():
    """Out-of-domain questions strictly invoke anti-hallucination fallback."""
    headers = get_auth_headers()
    resp = client.post("/api/ai/chat", headers=headers, json={"question": "What is the capital of France?"})
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["response_type"] == "INSUFFICIENT_INFORMATION"
    assert "I don't have enough reliable information to answer that yet" in data["answer"]
    assert any(a["action_type"] in ["ASK_QUERY", "EXPLORE_ROUTES"] for a in data["actions"])

def test_ai_ticket_isolation():
    """Querying ticket for user without active ticket does not leak other users' tickets."""
    headers = get_auth_headers(sub="unique-random-user-no-tickets-999")
    resp = client.post("/api/ai/chat", headers=headers, json={"question": "Show my active ticket"})
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["response_type"] == "TICKET_DATA"
    assert "do not have any active boarding passes" in data["answer"]
