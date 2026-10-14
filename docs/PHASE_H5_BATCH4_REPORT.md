# BusSense AI — Phase H5 Batch 4 Verification Report
**Unified Flutter Mobile: Passenger Profile, Preferences, Privacy & Support**

---

## 1. Executive Summary

Phase H5 Batch 4 completes the remaining Passenger commuter lifecycle within the unified Flutter mobile application (`apps/mobile/`). The passenger experience now spans the complete commuter journey:
$$\text{DISCOVER} \rightarrow \text{SENSE} \rightarrow \text{PREDICT} \rightarrow \text{RECOMMEND} \rightarrow \text{BOOK} \rightarrow \text{PAY} \rightarrow \text{TICKET} \rightarrow \text{TRAVEL} \rightarrow \text{ASK} \rightarrow \text{MANAGE}$$

The Profile tab (Tab 4 in `PassengerShell`) has been promoted from a temporary placeholder to a quiet, premium commuter control center adhering strictly to the Google Stitch design system tokens (Deep Forest Green `#002620`, Primary Green `#006C49`, Accent Mint `#A3F2CD`, Ivory surface `#F3FBF7`).

All data interactions are authenticated and enforce strict passenger ownership isolation. Simulated systems and deferred infrastructures are labeled with truth badges.

---

## 2. Implemented Screens & Experiences

| # | Screen / View | File Path | Scope & Stitch Alignment |
|---|---|---|---|
| 1 | **Passenger Profile Hub** | [passenger_profile_view.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/passenger_profile_view.dart) | Replaces Tab 4 placeholder. Displays commuter avatar, name, email, role badge (`PASSENGER`), shortcuts to Saved Places, Favorite Route (`Route 205`), Passes, Preferences, Privacy, Support, and Sign Out. |
| 2 | **Edit Profile** | [edit_profile_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/edit_profile_screen.dart) | Modifies Full Name and Preferred Language. Phone number and email are securely displayed as read-only. Validates input and persists to backend via `PUT /api/user/profile`. |
| 3 | **Saved Places** | [saved_places_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/saved_places_screen.dart) | Commuter destinations (Home, Work, College, Custom) with category badges and Kochi bus stop associations. Supports add (modal bottom sheet), view, delete, and 1-tap deep link to `PassengerExploreView`. |
| 4 | **Notification Preferences** | [notification_preferences_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/notification_preferences_screen.dart) | Master notification toggle and category controls (Arrivals, Delays, Crowd Pressure, Corridor Advisories, QR Pass Expiration). Truth badge: `PREFERENCE MODEL • PUSH DELIVERY DEFERRED`. |
| 5 | **Language & Appearance** | [language_appearance_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/language_appearance_screen.dart) | Selects English (India) or മലയാളം (Malayalam) with truth badge `PARTIAL / PREPARED`. Selects Light Surface (`#F3FBF7` optimized) or Nocturnal Dark mode. |
| 6 | **Privacy & Data Controls** | [privacy_data_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/privacy_data_screen.dart) | Factual disclosures on YOLOv8 computer vision (`ZERO BIOMETRICS`), transponder telemetry (`NO BACKGROUND TRACKING`), RLS ticketing, and RAG grounding. Includes Data Export and Account Deactivation flows. |
| 7 | **Help & FAQ** | [help_support_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/help_support_screen.dart) | Expandable accordion with 6 grounded transit FAQs covering crowd calculation, multi-factor recommendation, QR ticket validation, dynamic ETAs, and simulated data badges. |
| 8 | **Report an Issue** | [report_issue_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/report_issue_screen.dart) | Passenger incident reporting with category selector, optional bus/route metadata, description, and validation. Logs directly to the backend incident queue and renders a generated tracking reference ID. |

---

## 3. Navigation & Architecture Connections

The Profile experience acts as a connected hub:
- **Profile $\rightarrow$ Saved Places $\rightarrow$ Explore:** Tapping any saved destination (e.g. Infopark, Vyttila Mobility Hub, Angamaly) invokes `onNavigateToExplore` with pre-filled destination query.
- **Profile $\rightarrow$ Passes:** Deep-links directly to Passenger Tab 2 (`My Tickets & Passes`).
- **Profile $\rightarrow$ Help $\rightarrow$ Report Issue:** Seamless workflow to log delayed or overcrowded buses.
- **Profile $\rightarrow$ Sign Out:** Calls `ref.read(authControllerProvider.notifier).logout()`, wiping secure in-memory and persistent token storage, transitioning `authControllerProvider` to `Unauthenticated()`.

---

## 4. Backend Endpoints (FastAPI)

All endpoints reside in [backend/app/api/user.py](file:///d:/Bus_Sense_Ai/backend/app/api/user.py) under `/api/user`, requiring an authenticated `Authorization: Bearer <token>` header with strict `current_user` ownership derivation:

| Endpoint | Method | RBAC | Description |
|---|---|---|---|
| `/api/user/profile` | `GET` | Authenticated | Retrieves profile of the authenticated commuter. |
| `/api/user/profile` | `PUT` | Authenticated | Updates full name and preferred language for the authenticated commuter. |
| `/api/user/saved-places` | `GET` | Authenticated | Fetches user's saved places from `user_preferences` / Supabase. |
| `/api/user/saved-places` | `POST` | Authenticated | Inserts a new saved commuter place. |
| `/api/user/saved-places/{place_id}` | `DELETE` | Authenticated | Deletes a saved place owned by the user. |
| `/api/user/preferences` | `GET` | Authenticated | Fetches notification toggles and theme preferences. |
| `/api/user/preferences` | `PUT` | Authenticated | Updates notification and theme preferences. |
| `/api/user/reports` | `POST` | Authenticated | Logs passenger issue report to `incidents` / operational database. |
| `/api/user/export-data` | `POST` | Authenticated | Compiles JSON archive of profile, ticket count, and saved places. |
| `/api/user/deactivate` | `POST` | Authenticated | Deactivates commuter account and revokes session tokens. |

---

## 5. Riverpod Providers & Data Flow

```
Flutter UI (Views)
       ↓
Riverpod Providers (passengerProfileProvider, savedPlacesProvider, userPreferencesProvider, passengerReportsProvider)
       ↓
PassengerRepository (apps/mobile/lib/features/passenger/data/passenger_repository.dart)
       ↓
ApiClient (apps/mobile/lib/core/network/api_client.dart)
       ↓
FastAPI Backend (backend/app/api/user.py)
       ↓
UserService (backend/app/services/user_service.py)
       ↓
PostgreSQL / Supabase (user_preferences, profiles, incidents)
```

---

## 6. Implementation Truth & Classification

| Feature | Classification | Description & Rationale |
|---|---|---|
| Profile Editing | **IMPLEMENTED** | Full name and preferred language persist to authenticated backend. Email and phone number are read-only. |
| Saved Places | **IMPLEMENTED** | Commuter places are stored in the database, displayed in the UI, and link to route planning in Explore. |
| Notification Preferences | **PARTIAL** | UI switches and persistence to backend are fully implemented. Background push delivery (FCM/APNS) is **DEFERRED** per Phase H5 roadmap. Clearly badged `PUSH DELIVERY DEFERRED`. |
| Language Selection | **PARTIAL** | Language switching and model preference persistence are implemented. Malayalam strings are **PREPARED** in key UI components, with full bilingual catalog scheduled for subsequent release. |
| Theme Appearance | **IMPLEMENTED** | Light Surface (Google Stitch Ivory `#F3FBF7`) is optimized. Dark mode is prepared in theme configuration. |
| Privacy Disclosures | **IMPLEMENTED** | Factual statements regarding local YOLOv8 head-counting (`ZERO BIOMETRICS`), transponder-only bus GPS, and isolated ticket records. No false legal guarantees. |
| Data Export | **SIMULATED / PROTOTYPE** | Downloads user records into JSON archive. Clearly labeled `PROTOTYPE EXPORT ARCHIVE`. |
| Account Deactivation | **SIMULATED / PROTOTYPE** | Flags account as deactivated and revokes session. Labeled as prototype deactivation. |
| Issue Reporting | **IMPLEMENTED** | Passenger issue forms validate input, submit to backend `incidents` table, and return a real incident reference identifier. |

---

## 7. Verification Results

### 1. Flutter Static Analysis
```powershell
cd apps/mobile
flutter analyze
```
**Result:** `No issues found! (ran in 3.1s)` — 0 warnings, 0 errors, 0 hints.

### 2. Flutter Test Suite
```powershell
cd apps/mobile
flutter test
```
**Result:** **81/81 passed!**
- 14/14 Phase H5 Batch 4 tests passed in [passenger_profile_test.dart](file:///d:/Bus_Sense_Ai/apps/mobile/test/passenger_profile_test.dart)
- 6/6 Phase H4 authentication & routing tests passed in [auth_routing_test.dart](file:///d:/Bus_Sense_Ai/apps/mobile/test/auth_routing_test.dart)
- 10/10 Phase H5 Batch 1 journey tests passed in [passenger_journey_test.dart](file:///d:/Bus_Sense_Ai/apps/mobile/test/passenger_journey_test.dart)
- 10/10 Phase H5 Batch 2 ticketing tests passed in [passenger_ticketing_test.dart](file:///d:/Bus_Sense_Ai/apps/mobile/test/passenger_ticketing_test.dart)
- 11/11 Phase H5 Batch 3 AI assistant tests passed in [passenger_ai_assistant_test.dart](file:///d:/Bus_Sense_Ai/apps/mobile/test/passenger_ai_assistant_test.dart)
- Core foundation & smoke tests passed.

### 3. Backend Test Suite
```powershell
& "backend/.venv/Scripts/python.exe" -m pytest backend/tests/ -v
```
**Result:** **41/41 passed!** (including 8 new tests in [test_user_profile_h5.py](file:///d:/Bus_Sense_Ai/backend/tests/test_user_profile_h5.py)).

### 4. Next.js Authority Frontend Build
```powershell
npm.cmd --prefix frontend run build
```
**Result:** **Compiled successfully** — 22/22 static routes prerendered without errors or regressions.

---

## 8. Summary of Added Files

- **Backend:**
  - [backend/app/schemas/user.py](file:///d:/Bus_Sense_Ai/backend/app/schemas/user.py): Pydantic v2 schemas for UserProfile, SavedPlace, UserPreferences, and PassengerReport.
  - [backend/app/services/user_service.py](file:///d:/Bus_Sense_Ai/backend/app/services/user_service.py): Service business logic and data persistence.
  - [backend/app/api/user.py](file:///d:/Bus_Sense_Ai/backend/app/api/user.py): Authenticated FastAPI routes under `/api/user`.
  - [backend/tests/test_user_profile_h5.py](file:///d:/Bus_Sense_Ai/backend/tests/test_user_profile_h5.py): Pytest suite covering profile, saved places, preferences, reports, export, and deactivation.
- **Mobile Frontend:**
  - [apps/mobile/lib/shared/models/saved_place_model.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/shared/models/saved_place_model.dart)
  - [apps/mobile/lib/shared/models/user_preferences_model.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/shared/models/user_preferences_model.dart)
  - [apps/mobile/lib/shared/models/passenger_report_model.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/shared/models/passenger_report_model.dart)
  - [apps/mobile/lib/features/passenger/views/passenger_profile_view.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/passenger_profile_view.dart)
  - [apps/mobile/lib/features/passenger/views/edit_profile_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/edit_profile_screen.dart)
  - [apps/mobile/lib/features/passenger/views/saved_places_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/saved_places_screen.dart)
  - [apps/mobile/lib/features/passenger/views/notification_preferences_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/notification_preferences_screen.dart)
  - [apps/mobile/lib/features/passenger/views/language_appearance_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/language_appearance_screen.dart)
  - [apps/mobile/lib/features/passenger/views/privacy_data_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/privacy_data_screen.dart)
  - [apps/mobile/lib/features/passenger/views/help_support_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/help_support_screen.dart)
  - [apps/mobile/lib/features/passenger/views/report_issue_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/report_issue_screen.dart)
  - [apps/mobile/test/passenger_profile_test.dart](file:///d:/Bus_Sense_Ai/apps/mobile/test/passenger_profile_test.dart)
