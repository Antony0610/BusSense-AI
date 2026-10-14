# Phase H5 Batch 2 — Passenger Ticketing & Active Journey Report

**Phase Status:** `VERIFIED`  
**Date:** September 27, 2026  
**Scope:** Unified Flutter Mobile Application (`apps/mobile/`) — Passenger Role Batch 2: Ticketing, QR Boarding Passes, and Active Journey HUD  

---

## 1. Scope & Objectives

Phase H5 Batch 2 successfully implemented the end-to-end commuter ticketing and active travel journey within the existing unified Flutter application (`apps/mobile/`):

$$\text{DISCOVER} \longrightarrow \text{BOOK} \longrightarrow \text{REVIEW} \longrightarrow \text{PAY} \longrightarrow \text{TICKET} \longrightarrow \text{TRAVEL}$$

### Controlled Boundaries Preserved:
- **Single Flutter App:** Built strictly inside `apps/mobile/`. No separate `apps/passenger/` or parallel projects created.
- **Untouched Conductor & Authority:** The Conductor operational suite (`ConductorShell`) and Next.js Authority portal remained untouched and verified.
- **Truth Transparency:** All simulated payment mechanisms and prototype tickets are honestly disclosed and labeled (`SIMULATED PAYMENT`, `PROTOTYPE TICKET`).
- **Commuter Glanceability:** Zero low-level telemetry, GPS raw coordinates, sensor metrics, or CV bounding boxes exposed to commuter UI.

---

## 2. Screens Implemented

Six functional, transport-tailored screens and views were implemented adhering to Google Stitch design tokens:

| Screen / View | File Path | Core Commuter Functionality |
| :--- | :--- | :--- |
| **1. Booking Entry** | [ticket_booking_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/ticket_booking_screen.dart) | Boarding pass configuration from selected bus: origin stop, destination stop, primary passenger name, tariff breakdown, stage carriage reservation disclaimer, and input validation. |
| **2. Booking Review** | [booking_review_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/booking_review_screen.dart) | High-contrast, minimal summary before payment: route trajectory, vehicle number, boarding stop, passenger identity, and fare breakdown (`tabularNumeral`). Primary "Proceed to Payment" and "Edit Details" actions. |
| **3. Test Payment Gateway** | [test_payment_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/test_payment_screen.dart) | Clearly stamped `SIMULATED PAYMENT` gateway. Selectable prototype methods (UPI, Transit Card, NetBanking), mock processing delay, simulated failure trigger for testing, and backend persistence call to `/api/tickets/book`. |
| **4. Digital QR Ticket** | [digital_qr_ticket_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/digital_qr_ticket_screen.dart) | Transit boarding pass with perforated ticket divider, status badge (`VALID TICKET`), scannable QR code generated from backend cryptographic hash via `qr_flutter` (with base64 fallback), fare, ticket number, and "Track Active Journey HUD" CTA. |
| **5. Active Journey HUD** | [active_journey_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/active_journey_screen.dart) | Real-time transit HUD following strict mandated visual hierarchy: **Current Bus** $\rightarrow$ **Destination** $\rightarrow$ **Next Stop** $\rightarrow$ **ETA** $\rightarrow$ **Route Progress**. Also displays crowd density status, active route advisories, link back to QR pass, and an empty state when no trip is active. |
| **6. Passenger Tickets Landing** | [passenger_tickets_view.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/passenger_tickets_view.dart) | Powers Tab 2 (`Tickets`) of `PassengerShell`. Displays active boarding passes with immediate actions ("Show QR", "Track HUD"), historical trips, pull-to-refresh, and empty state with route exploration link. |

---

## 3. Commuter Journey Flow & Navigation Integration

1. **Discovery to Booking:**
   - On [BusDetailsScreen](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/bus_details_screen.dart), tapping **"Book Digital Boarding Pass"** opens `TicketBookingScreen` pre-populated with the bus's route and operator details.
   - On [PassengerExploreView](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/passenger_explore_view.dart), recommended corridor cards include a direct **"Book Ticket"** action.
2. **Review to Payment:**
   - Validating stops and passenger name updates the Riverpod `currentBookingDraftProvider` and navigates to `BookingReviewScreen`.
   - "Proceed to Payment" transitions to `TestPaymentScreen`.
3. **Payment to Boarding Pass:**
   - Successful payment posts the booking to `POST /api/tickets/book`, persists the ticket in Supabase PostgreSQL, invalidates `myTicketsProvider`, and replaces the navigation stack with `DigitalQrTicketScreen`.
4. **Boarding Pass to Active HUD:**
   - Tapping "Track Active Journey HUD" opens `ActiveJourneyScreen` pre-bound to the active ticket, updating `activeJourneyTicketProvider`.
5. **Passenger Shell Tab 2 (Tickets):**
   - Replaced placeholder on Tab 2 of [passenger_shell.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/passenger_shell.dart) with `PassengerTicketsView`. Commuters can view active tickets or past journeys anytime.

---

## 4. Backend Endpoints Consumed

All requests strictly adhere to the H2/H3 contracts through `PassengerRepository` and `ApiClient`:

| Method | Endpoint | Consumer View / Provider | Purpose & Behavior |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/tickets/book` | `PassengerRepository.bookTicket` | Books ticket with `BookingCreateRequest`, creates matching payment record (`RAZORPAY_TEST`), and persists in Supabase. |
| `GET` | `/api/tickets/my` | `myTicketsProvider` | Retrieves persistent tickets for current commuter filtered by `user_id`. |
| `GET` | `/api/buses/{bus_number}` | `PassengerRepository.getBusDetails` | Fetches live vehicle details, route information, and occupancy status. |
| `GET` | `/api/locations` | `liveLocationsProvider` | Fetches corridor GPS coordinates to verify vehicle movement. |
| `GET` | `/api/crowd` | `fleetCrowdProvider` | Fetches live crowd density metrics for current bus. |
| `GET` | `/api/alerts/active` | `activeAlertsProvider` | Fetches corridor operational advisories and displays them on the Active Journey HUD. |

*Note: Zero backend endpoints were modified or added. Existing contracts from Phase H2 and H3 were 100% sufficient.*

---

## 5. Riverpod Providers Architecture

Updated in [passenger_providers.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/providers/passenger_providers.dart):

```
passengerRepositoryProvider (IPassengerRepository)
  ├── myTicketsProvider (FutureProvider<List<TicketModel>>)
  ├── activeTicketProvider (Provider<TicketModel?>)
  ├── currentBookingDraftProvider (StateProvider<BookingDraft?>)
  ├── activeJourneyTicketProvider (StateProvider<TicketModel?>)
  ├── liveBusesProvider (FutureProvider<List<BusModel>>)
  ├── liveLocationsProvider (FutureProvider<List<LocationModel>>)
  ├── fleetCrowdProvider (FutureProvider<List<CrowdModel>>)
  └── activeAlertsProvider (FutureProvider<List<AlertModel>>)
```

---

## 6. Ticket Lifecycle Implementation

The Flutter application strictly respects the backend persistent lifecycle:

$$\text{BOOKED} \longrightarrow \text{VALID} \longrightarrow \text{USED} \longrightarrow \text{EXPIRED / CANCELLED}$$

- **Booked & Valid:** Tickets with status `VALID` or `BOOKED` are categorized as **Active Boarding Passes** and highlighted with high-contrast borders and quick actions ("Show QR", "Track HUD").
- **Used & Expired:** Validated or expired tickets appear under **Past Tickets** with validation timestamps and read-only status pills.
- **Persistence Across Restarts:** Because tickets are fetched from `/api/tickets/my` (persisted in PostgreSQL), tickets survive application restarts.

---

## 7. Payment Safety & Simulation Transparency

- **Security Guarantee:** Zero credit card numbers, CVVs, UPI PINs, Razorpay secrets, or Supabase service-role keys are accepted or stored in Flutter.
- **Transparent Stamping:** The payment view prominently displays:
  - `SIMULATED PAYMENT`
  - `PROTOTYPE TEST ENVIRONMENT`
  - Explicit notification that no real currency is deducted.
- **Interactive Failure Testing:** A dedicated "Simulate Payment Failure" action allows developers and reviewers to test failure states, retry mechanics, and network abort handling.

---

## 8. QR Code Implementation

- Added pure Dart dependency `qr_flutter: ^4.1.0` to [pubspec.yaml](file:///d:/Bus_Sense_Ai/apps/mobile/pubspec.yaml).
- `DigitalQrTicketScreen` renders `QrImageView` using the cryptographic `qrCodeHash` generated by backend (`bussense://ticket/{ticket_number}`).
- Supports automatic fallback to backend base64 image data URI (`ticket.qrCodeDataUri`) if present.
- High-contrast colors: Primary deep green (`#002620`) on clean white surface.
- Conductor validation compatibility: The QR hash contains the exact ticket identifier consumable by the Conductor terminal validator endpoint (`POST /api/tickets/validate`).

---

## 9. Active Journey HUD Commuter Hierarchy

The Active Journey HUD strictly adheres to the mandated commuter-focused glanceable hierarchy:

1. **Current Bus:** Prominent pill badge displaying Bus Number (`205`) and Route (`12`).
2. **Your Destination:** Origin $\rightarrow$ Destination with clear destination milestone.
3. **Next Approaching Stop:** High-visibility callout showing the immediate stop.
4. **ETA Countdown:** Tabular numeral countdown (`4 min`) with scheduled arrival time.
5. **Route Progress:** Vertical milestone timeline showing Completed, Current, and Remaining stops.
6. **Contextual Cards:** Live crowd level badge, active corridor safety alerts, and a button to quickly reveal the QR boarding pass for conductor inspection.

---

## 10. Automated Test Results

### Mobile Flutter Suite (`apps/mobile/`)
- **Total Tests:** 56 passing (0 failures, 0 skipped).
- **Static Analysis (`flutter analyze`):** 0 issues found.
- **New Ticketing Suite (`passenger_ticketing_test.dart`):** 11 tests covering:
  1. Booking entry renders selected journey and bus details.
  2. Fare and passenger input fields render and validate required fields.
  3. Booking review renders journey summary before payment.
  4. Test payment screen renders amount and processes simulated success.
  5. Test payment handles simulated failure and error states.
  6. Digital QR Ticket renders ticket ID, status, and QR code.
  7. Active Journey HUD renders glanceable bus, next stop, ETA, and progress.
  8. Active Journey renders empty state when no ticket is active.
  9. PassengerTicketsView renders active ticket and action buttons.
  10. PassengerTicketsView renders empty state when no tickets booked.
  11. PassengerShell navigation switches to Tickets tab cleanly.

### Backend Pytest Suite (`backend/tests/`)
- **Total Tests:** 25 passing (0 failures).
- **Execution Time:** ~29.4s.
- **Coverage:** RBAC, atomic persistence, ticket booking, QR validation, crowd predictions, and corridor alerts.

### Next.js Authority Portal Build (`frontend/`)
- **Total Static Pages:** 22/22 compiled successfully.
- **Zero Type / Lint Errors:** TypeScript compilation passed with zero warnings.

---

## 11. State of Truth: Implemented vs. Simulated vs. Deferred

| Feature Component | Classification | Notes |
| :--- | :--- | :--- |
| Journey to Booking Pre-fill | `IMPLEMENTED` | Real route and bus data transferred from Batch 1 screens. |
| Ticket Form Validation | `IMPLEMENTED` | Stops and passenger name validation with in-app error feedback. |
| Persistent Ticket Booking | `IMPLEMENTED` | Backed by PostgreSQL transactions via `POST /api/tickets/book`. |
| My Tickets Retrieval | `IMPLEMENTED` | Backed by PostgreSQL queries via `GET /api/tickets/my`. |
| Vector QR Code Generation | `IMPLEMENTED` | Renders `qr_flutter` using backend cryptographic hash. |
| Active Journey HUD | `IMPLEMENTED` | Commuter glanceable view with bus, destination, next stop, and ETA. |
| Tickets Shell Tab | `IMPLEMENTED` | Tab 2 in `PassengerShell` is fully functional for pass inspection. |
| Payment Gateway Processing | `SIMULATED` | Transparently labeled `SIMULATED PAYMENT` using mock transit cards/UPI. |
| Live GPS Telemetry Polling | `SIMULATED` | Sourced from simulation engine (`/api/locations`). |
| Dynamic Anti-Screenshot Watermarking | `DEFERRED` | Out of scope for prototype; not claimed in UI. |
| AI / RAG Commuter Assistant | `DEFERRED` | Reserved for planned Phase 14 / future batch. |
| Passenger Profile / Pass History Management | `DEFERRED` | Reserved for planned Profile phase. |
| Conductor Operational UI Changes | `DEFERRED` | Conductor shell remains intact and verified. |
