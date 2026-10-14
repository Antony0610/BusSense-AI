# BusSense AI — Phase H5 Batch 3 Verification Report
## Unified Flutter Mobile — Passenger AI / RAG Transit Assistant

**Date:** September 27, 2026  
**Status:** VERIFIED & COMPLETE  
**Application Scope:** `apps/mobile/` (Unified Flutter) & `backend/` (FastAPI + Grounded RAG Tools)  
**Design Reference:** Google Stitch BusSense Design System (Project `14259704318600090723`)  

---

## 1. Executive Summary

Phase H5 Batch 3 successfully integrates the **Passenger AI / RAG Transit Assistant** into the unified Flutter mobile application (`apps/mobile`), replacing the previous placeholder tab with a production-grade, context-aware journey companion.

The experience adheres strictly to the core commuter flow:
$$\text{ASK} \longrightarrow \text{RETRIEVE} \longrightarrow \text{UNDERSTAND} \longrightarrow \text{ANSWER} \longrightarrow \text{SHOW SOURCES} \longrightarrow \text{OFFER ACTION}$$

The assistant strictly discriminates between:
- **`LIVE DATA`**: Current GPS telemetry, vehicle positions, active boarding stops.
- **`PREDICTION`**: 4-horizon demand forecasting model ($T+0, T+15, T+30, T+60$).
- **`RECOMMENDATION`**: Multi-factor scoring engine (crowd delta 40%, duration 35%, reliability 15%, fare 10%).
- **`TICKET DATA`**: Authenticated commuter boarding passes from persistent Supabase PostgreSQL.
- **`ACTIVE JOURNEY`**: Live transit HUD telemetry, next stop estimations, corridor progression.
- **`KNOWLEDGE`**: Approved BusSense technical and transit documentation.
- **`INSUFFICIENT INFORMATION`**: Strict safe fallback for out-of-domain queries preventing AI hallucinations.

---

## 2. Views & Screens Implemented

The implementation introduces 6 focused, high-fidelity transit experiences matching Google Stitch aesthetics:

1. **`PassengerAssistantView` (Primary Screen):**
   - File: [passenger_assistant_view.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/passenger_assistant_view.dart)
   - Replaces the shell Tab 3 placeholder (`PassengerShell`).
   - Clean Deep Forest Green (`#002620`) header: *"BusSense AI"* and subtitle *"Your journey assistant"*.
   - Status badge indicating `RAG GROUNDED`.
   - Responsive quick-reset conversation action.
   - Text input bar with send button, auto-scroll synchronization, and accessible touch targets.

2. **Context-Aware Active Journey Banner:**
   - Dynamically appears when the commuter holds a valid boarding pass.
   - Displays current bus number and destination corridor with quick-tap queries (*"Ask ETA"*, *"Next Stop"*).

3. **Conversation & Answer Hierarchy Cards:**
   - Distinguishes commuter message bubbles (Forest Green, right-aligned) from structured AI responses.
   - Header with classification badge (`LIVE DATA`, `PREDICTION`, `RECOMMENDATION`, `KNOWLEDGE`, etc.) and provenance badge (`LIVE SENSOR TELEMETRY`, `MACHINE LEARNING PREDICTION`, `VERIFIED KNOWLEDGE BASE`, etc.).
   - Crisp typography, no decorative or cyberpunk elements.

4. **`AISourceDetailsSheet` (Source Citations & Provenance Modal):**
   - File: [ai_source_details_sheet.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/ai_source_details_sheet.dart)
   - Bottom sheet presenting all verified sources backing the response.
   - Shows source title, classification type, textual snippet / citation evidence, and platform reference.

5. **Suggested Starters & Action Deep-Links:**
   - Starter prompts: *"Which bus is less crowded?"*, *"When will my bus arrive?"*, *"Show my active ticket"*, *"Why was this bus recommended?"*, etc.
   - Action buttons deep-linking into existing Flutter views:
     - `SHOW_TICKET` $\rightarrow$ [DigitalQrTicketScreen](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/digital_qr_ticket_screen.dart)
     - `TRACK_HUD` $\rightarrow$ [ActiveJourneyScreen](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/active_journey_screen.dart)
     - `VIEW_BUS` $\rightarrow$ [BusDetailsScreen](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/bus_details_screen.dart)
     - `EXPLORE_ROUTES` $\rightarrow$ Switches to [ExploreCorridorsView](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/explore_corridors_view.dart)

6. **Insufficient Information & Safe Fallback View:**
   - Triggers when a commuter asks out-of-domain questions (e.g. world trivia, general stock advice).
   - Responds: *"I don't have enough reliable information to answer that yet. I am trained specifically on Greater Kochi transit corridors, live bus operations, crowding intelligence, and your tickets."*
   - Avoids plausible-sounding fabrications.

---

## 3. Architecture & Provenance Separation

### 3.1. Knowledge Base (`backend/knowledge/`)
Five versionable, grounded documentation sources were added:
- [routes.md](file:///d:/Bus_Sense_Ai/backend/knowledge/routes.md): Route 205 (Aluva $\rightarrow$ Vyttila), Route 14A, Route 8, stops, dedicated lanes.
- [tickets.md](file:///d:/Bus_Sense_Ai/backend/knowledge/tickets.md): Stage-carriage unassigned seating, QR validation protocol, anti-reuse token lifecycle.
- [crowd.md](file:///d:/Bus_Sense_Ai/backend/knowledge/crowd.md): Privacy-first YOLOv8 person counting (zero biometrics/facial recognition), density thresholds ($<45\%$ Low, $45-75\%$ Moderate, $>75\%$ High).
- [recommendations.md](file:///d:/Bus_Sense_Ai/backend/knowledge/recommendations.md): Mathematical scoring formulation ($40\%$ crowding delta, $35\%$ corridor duration, $15\%$ punctuality, $10\%$ fare).
- [passenger_help.md](file:///d:/Bus_Sense_Ai/backend/knowledge/passenger_help.md): App capabilities, offline fallback guidance, commuter active HUD usage.

### 3.2. Controlled Backend Live Data Tools (`backend/app/services/rag_service.py`)
Direct access to internal databases is restricted. The query orchestrator executes controlled tool functions:
- `tool_get_bus_location(bus_number)`: Queries `gps_simulator` for speed, coordinates, next stop, and ETA.
- `tool_get_crowd_prediction(bus_number)`: Queries `demand_forecaster.forecast_corridor_crowd(...)` for the 4-horizon trajectory.
- `tool_get_recommendation(origin, destination)`: Returns the highest-scoring corridor option with factor breakdowns.
- `tool_get_user_tickets(user_id)`: Queries persistent PostgreSQL for tickets owned strictly by the authenticated user.

### 3.3. Provider Abstraction (`backend/app/services/ai_provider.py`)
- Created `BaseAIProvider` protocol declaring `generate_answer(...)` and `generate_structured_answer(...)`.
- Implemented `DevelopmentFallbackAIProvider` as the local development execution engine.
- Clearly classified in response payloads as `DEVELOPMENT FALLBACK` and `GROUNDED RAG` rather than claiming external paid production LLM integration.

### 3.4. API Endpoint (`POST /api/ai/chat`)
- File: [backend/app/api/ai.py](file:///d:/Bus_Sense_Ai/backend/app/api/ai.py)
- Enforces JWT authentication (`get_current_user`).
- Commuter ticket context is filtered by authenticated `user.id`.
- Returns structured JSON adhering to [ai.py schema](file:///d:/Bus_Sense_Ai/backend/app/schemas/ai.py):
  ```json
  {
    "answer": "Bus 205 is currently approaching Palarivattom Jn...",
    "response_type": "LIVE_DATA",
    "sources": ["Live GPS Corridor Telemetry"],
    "source_items": [
      {
        "id": "SRC-LIVE-1",
        "title": "Live GPS Corridor Telemetry",
        "source_type": "LIVE_DATA",
        "snippet": "Bus 205: Speed 42.5 km/h, next stop Palarivattom Jn in 4 mins.",
        "reference": "Corridor Dispatch Stream"
      }
    ],
    "actions": [
      {"label": "View Bus Details", "action_type": "VIEW_BUS", "payload": {"bus_number": "205"}}
    ],
    "suggested_actions": ["Track Bus", "Check Crowd"],
    "data_origin": "LIVE SENSOR TELEMETRY"
  }
  ```

---

## 4. Implementation Classification Matrix

| Feature / Component | Status | Classification Details |
| :--- | :--- | :--- |
| **Flutter Assistant View** | **IMPLEMENTED** | Full Riverpod-driven UI in `PassengerAssistantView` with Stitch styling |
| **Citation / Source Sheet** | **IMPLEMENTED** | Modal bottom sheet displaying verified sources, snippets, and provenance |
| **Context-Aware Active Journey** | **IMPLEMENTED** | Dynamic injection of commuter's active ticket & vehicle into queries |
| **Grounded Knowledge Sources** | **IMPLEMENTED** | Markdown knowledge files in `backend/knowledge/` |
| **Live Transit Tools** | **IMPLEMENTED** | Controlled tools reading live GPS, predictions, and recommendations |
| **Ticket Isolation Guardrails** | **IMPLEMENTED** | Commuters can only query their own persistent tickets |
| **Anti-Hallucination Safe Fallback** | **IMPLEMENTED** | Refuses out-of-domain questions with transparent boundary declaration |
| **AI Provider Abstraction** | **IMPLEMENTED** | `BaseAIProvider` interface with clean backend pluggability |
| **LLM Inference Engine** | **DEVELOPMENT FALLBACK** | Local deterministic rule & intent matching engine; transparently stamped as `DEVELOPMENT FALLBACK` |
| **External Vector Embeddings (Pgvector/Pinecone)** | **DEFERRED** | Knowledge retrieved via controlled keyword & document loader; vector DB deferred |
| **Voice / Speech-to-Text** | **DEFERRED** | Deferred per project roadmap |
| **Autonomous Operational Rerouting** | **DEFERRED** | Passenger assistant offers suggestions only |

---

## 5. Verification Results

### 5.1. Flutter Static Analysis
```powershell
cmd.exe /c "cd apps\mobile && flutter analyze"
# Result: No issues found! (ran in 74.9s)
```

### 5.2. Flutter Test Suite
```powershell
cmd.exe /c "cd apps\mobile && flutter test"
# Result: 00:22 +67: All tests passed!
```
- **Total Mobile Tests:** 67 tests passing (56 baseline + 11 new AI assistant widget & integration tests).
- **Test file:** [passenger_ai_assistant_test.dart](file:///d:/Bus_Sense_Ai/apps/mobile/test/passenger_ai_assistant_test.dart) covers:
  1. AI screen header, starter prompts, and welcome card.
  2. Context bar renders active ticket info when available.
  3. User message submission and live data response rendering.
  4. Prediction query renders prediction badge and 4-horizon trajectory.
  5. Recommendation query explains 3 factors and renders CTA.
  6. Ticket query renders authenticated ticket data and actions.
  7. Active journey query renders next stop and HUD CTA.
  8. Insufficient information query triggers safe fallback without hallucination.
  9. Tapping source citations button opens `AISourceDetailsSheet`.
  10. Error state renders when network/server fails.
  11. PassengerShell navigation switches to AI tab cleanly.

### 5.3. Backend Test Suite
```powershell
backend\.venv\Scripts\python.exe -m pytest backend/tests/ -v
# Result: ======================= 33 passed, 1 warning in 42.13s ========================
```
- **Total Backend Tests:** 33 tests passing (25 baseline + 8 new AI assistant tests).
- **Test file:** [test_ai_assistant_h5.py](file:///d:/Bus_Sense_Ai/backend/tests/test_ai_assistant_h5.py) covers:
  - Unauthenticated access rejection (401).
  - Live data retrieval and provenance.
  - 4-horizon prediction query.
  - Multi-factor recommendation query.
  - Grounded knowledge base retrieval.
  - Active journey context ingestion.
  - Out-of-domain safe fallback.
  - User ticket privacy isolation.

### 5.4. Authority Next.js Web App Build
```powershell
npm.cmd --prefix frontend run build
# Result: ✓ Generating static pages (22/22)
# Result: 22/22 routes successfully compiled with 0 errors
```

---

## 6. Known Limitations & Next Steps

1. **Development Fallback AI Provider:**
   - The system utilizes `DevelopmentFallbackAIProvider` to ground responses against knowledge sources and live tools.
   - When a cloud LLM provider API key (e.g. Google Gemini, Anthropic, or OpenAI) is configured in backend `.env`, the provider abstraction allows seamless swapping without client changes.
2. **Vector Indexing:**
   - In this batch, documents in `backend/knowledge/` are retrieved deterministically. Embedding vector indexes (e.g. pgvector) will be introduced if the knowledge corpus expands beyond transit operations.
3. **Strict Boundaries Kept:**
   - Conductor workflows, Authority dashboards, Profile/Settings, CCTV/YOLO, and hardware GPS were untouched.
