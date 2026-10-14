# BusSense AI — Artificial Intelligence & RAG Architecture

This document details the Artificial Intelligence subsystem of BusSense AI, comprising Retrieval-Augmented Generation (RAG), live database telemetry tool-calling, hallucination guardrails, and role-bounded assistant personas.

---

## 1. System Overview

The AI architecture ensures that commuter questions and authority operational inquiries receive **accurate, verified, and strictly grounded** answers.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        USER INPUT & INTENT ROUTER                      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
         ┌──────────────────────────┴──────────────────────────┐
         ▼                                                     ▼
┌─────────────────────────────────┐           ┌─────────────────────────────────┐
│       POLICY / STATIC QA        │           │     LIVE TELEMETRY INQUIRY      │
│  (e.g., student bus pass rules) │           │   (e.g., "Is Bus 205 crowded?") │
└────────────────┬────────────────┘           └────────────────┬────────────────┘
                 │                                             │
                 ▼ Vector Search                               ▼ SQL Tool Query
┌─────────────────────────────────┐           ┌─────────────────────────────────┐
│     `knowledge_chunks` TABLE    │           │    `buses`, `occupancy`, `trips`│
│  (Fares, Concessions, Policies) │           │    (Live GPS, Occupancy, ETA)   │
└────────────────┬────────────────┘           └────────────────┬────────────────┘
                 │                                             │
                 └──────────────────────┬──────────────────────┘
                                        │ Merged Context Window
                                        ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        PROMPT ASSEMBLY & GUARDRAILS                    │
├────────────────────────────────────────────────────────────────────────┤
│ • System Role: Kerala Transit Authority Intelligence Engine            │
│ • Injected Knowledge: Retrieved policy chunks & real-time telemetry   │
│ • Immutable Rule: Never invent timings, fares, or routes               │
│ • Fallback Mandate: Emit standard fallback if uncertain                │
└───────────────────────────────────────┬────────────────────────────────┘
                                        │
                                        ▼
┌────────────────────────────────────────────────────────────────────────┐
│                             GROUNDED ANSWER                            │
│           (Answer Text + Cited Sources + Live Bus Context Chip)        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Distinction of Data Types

To prevent model hallucinations and ambiguous claims, the assistant explicitly categorizes every factual statement:

| Data Type | Description | Attribution Badge | Example |
|---|---|---|---|
| **Live Telemetry** | Active sensor/camera readings from database | `LIVE DATA` | *"Bus 205 has 23 passengers onboard right now."* |
| **Prediction** | Machine learning forecast outputs | `PREDICTION` | *"Crowding is projected to reach 82% at 17:30."* |
| **Recommendation** | Multi-factor algorithmic ranking | `RECOMMENDATION` | *"Bus 14A is recommended for a 40% shorter wait."* |
| **Static Knowledge** | Gazette rules, fares, transit policies | `KNOWLEDGE BASE` | *"Minimum Kerala ordinary stage carriage fare is ₹10."* |
| **Human Decision** | Actions requiring supervisor sign-off | `HUMAN DECISION` | *"Tripper dispatch pending clearance from Officer #42."* |

**Cardinal Rule:** The model must NEVER silently convert a `PREDICTION` into a `LIVE DATA` fact.

---

## 3. Fallback Protocol & Anti-Hallucination Guardrails

If a commuter inquires about a non-existent route, an unsupported bus number, or an unverified schedule, the model is strictly forbidden from improvising.

### Mandatory Fallback Response:
> *"I don't have enough reliable information to answer that based on current Kerala transit schedules. Please verify with the terminal inquiry desk or check the active corridor list."*

### Prohibited Behaviors:
- Inventing bus departure times.
- Guessing student concession discounts without gazette reference.
- Estimating traffic delays without active corridor incident reports.
- Offering medical or mechanical advice during an onboard emergency.

---

## 4. Knowledge Base & Vector Embeddings

### Seed Documents (`knowledge_documents`):
1. **Kerala Motor Vehicles Department Stage Carriage Fare Notification:**
   Base fare ₹10.00 for initial 2.5 km; ₹1.50 per subsequent km. Fast Passenger surcharge structure.
2. **Student & Senior Citizen Concession Regulations:**
   Procedures for KSRTC student concession smartcards, validity terms, and peak hour travel conditions.
3. **Safety & Zero-Biometrics Privacy Policy:**
   Verification that onboard cameras only detect bodies and heads for crowd estimation, retaining zero facial biometric templates.

---

## 5. Implementation Reference

The RAG service is implemented in `backend/app/services/rag_service.py:query_rag`.

It exposes:
- **Corpus Context Fetcher:** `retrieve_context(query)`
- **Telemetry Injector:** `inject_live_bus_telemetry(bus_code)`
- **Query Handler:** `POST /api/ai/query` returning `AIQueryResponse` with structured source links.
