# BusSense AI — Documentation Index

Welcome to the engineering documentation suite for **BusSense AI**, the climate-smart public bus intelligence platform for the Kerala transit network.

This documentation serves as the single source of truth for all architectural decisions, database schemas, REST APIs, UI guidelines, computer vision pipelines, and operational specifications.

---

## Document Index

| Category | File | Description |
|---|---|---|
| **Overview & Identity** | [PROJECT.md](file:///d:/Bus_Sense_Ai/docs/PROJECT.md) | High-level problem statement, solution, target users, and innovation pillars. |
| **System Blueprint** | [ARCHITECTURE.md](file:///d:/Bus_Sense_Ai/docs/ARCHITECTURE.md) | Full-stack end-to-end data pipelines (CV, GPS, Backend, ML, Frontend). |
| **Features & Capabilities** | [FEATURES.md](file:///d:/Bus_Sense_Ai/docs/FEATURES.md) | Status-tracked feature matrix across Passenger, Driver, and Authority roles. |
| **Functional Specification**| [FUNCTIONS.md](file:///d:/Bus_Sense_Ai/docs/FUNCTIONS.md) | Detailed specifications for all 23 core algorithmic and operational functions. |
| **Database Schema** | [DATABASE.md](file:///d:/Bus_Sense_Ai/docs/DATABASE.md) | Comprehensive dictionary of all 26 relational tables, columns, indexes, and RLS. |
| **Entity Relationships** | [DATA_MODEL.md](file:///d:/Bus_Sense_Ai/docs/DATA_MODEL.md) | ER diagrams, data flow lifecycles, and schema design principles. |
| **REST APIs** | [API.md](file:///d:/Bus_Sense_Ai/docs/API.md) | Formal endpoint specifications for authentication, telemetry, tickets, and AI. |
| **Authentication & RBAC** | [AUTH.md](file:///d:/Bus_Sense_Ai/docs/AUTH.md) | JWT token lifecycle, role isolation, and demo credentials. |
| **Permissions Matrix** | [ROLES_AND_PERMISSIONS.md](file:///d:/Bus_Sense_Ai/docs/ROLES_AND_PERMISSIONS.md) | Detailed capability access matrix across Passenger, Driver, and Authority roles. |
| **Artificial Intelligence** | [AI.md](file:///d:/Bus_Sense_Ai/docs/AI.md) | RAG architecture, knowledge embeddings, live tool-calling, and grounding guardrails. |
| **Computer Vision** | [COMPUTER_VISION.md](file:///d:/Bus_Sense_Ai/docs/COMPUTER_VISION.md) | YOLOv8 + OpenCV person detection, crowd counting, and privacy architecture. |
| **GPS & Realtime** | [GPS_AND_REALTIME.md](file:///d:/Bus_Sense_Ai/docs/GPS_AND_REALTIME.md) | Corridor waypoint movement, ETA calculations, and WebSockets telemetry sync. |
| **Ticketing & Payments** | [TICKETING.md](file:///d:/Bus_Sense_Ai/docs/TICKETING.md) | Fare calculation, QR code cryptographic structure, validation, and lifecycle. |
| **UI/UX Design System** | [UI_UX.md](file:///d:/Bus_Sense_Ai/docs/UI_UX.md) | Stitch design tokens, color palette, typography rules, and role ergonomics. |
| **Simulation & Demo** | [DEMO_MODE.md](file:///d:/Bus_Sense_Ai/docs/DEMO_MODE.md) | Offline demo behavior, mock physics generators, and synthetic data badging. |
| **Testing & Quality** | [TESTING.md](file:///d:/Bus_Sense_Ai/docs/TESTING.md) | Pytest test suite, unit tests, integration tests, and build validation commands. |
| **Security & Privacy** | [SECURITY.md](file:///d:/Bus_Sense_Ai/docs/SECURITY.md) | Threat modeling, cryptographic hashing, data minimization, and secret protection. |
| **Environment Config** | [ENVIRONMENT.md](file:///d:/Bus_Sense_Ai/docs/ENVIRONMENT.md) | Complete reference of all configuration variables in `.env`. |
| **Deployment Strategy** | [DEPLOYMENT.md](file:///d:/Bus_Sense_Ai/docs/DEPLOYMENT.md) | Target hosting topologies (Vercel, Render/Railway, Supabase Cloud). |
| **Known Limitations** | [KNOWN_LIMITATIONS.md](file:///d:/Bus_Sense_Ai/docs/KNOWN_LIMITATIONS.md) | Transparent inventory of prototype boundaries and simulated components. |
| **Decisions (ADRs)** | [DECISIONS.md](file:///d:/Bus_Sense_Ai/docs/DECISIONS.md) | Architecture Decision Records for key technical trade-offs. |
| **Changelog** | [CHANGELOG.md](file:///d:/Bus_Sense_Ai/docs/CHANGELOG.md) | Chronological log of versions, migrations, and engineering milestones. |

---

## Root Documentation Links

- [MEMORY.md](file:///d:/Bus_Sense_Ai/MEMORY.md): Permanent AI and developer context.
- [AGENTS.md](file:///d:/Bus_Sense_Ai/AGENTS.md): Instructions for autonomous coding subagents.
- [CONTRIBUTING.md](file:///d:/Bus_Sense_Ai/CONTRIBUTING.md): Git workflows and PR checklists.
