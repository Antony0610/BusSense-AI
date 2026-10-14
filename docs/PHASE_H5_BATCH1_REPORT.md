# Phase H5 Batch 1 — Core Journey Discovery Report

**Phase Status:** `VERIFIED`  
**Date:** September 27, 2026  
**Scope:** Unified Flutter Mobile Application (`apps/mobile/`) — Passenger Role Batch 1: Core Journey Discovery  

---

## 1. Scope

Phase H5 Batch 1 established the first fully functional commuter journey discovery experience within the existing unified Flutter application (`apps/mobile/`). 

### Strict Boundaries Maintained:
- **No separate projects:** Built strictly inside `apps/mobile/`. No `apps/passenger/` created.
- **Untouched Conductor & Authority:** The existing Conductor shell (`ConductorShell`) and Next.js Authority portal remained untouched and verified.
- **No Early Scope Creep:** Ticketing, payments, digital QR tickets, AI RAG assistant, profile management, WebSockets, CCTV/YOLO, and offline synchronization were strictly deferred to their respective planned phases.

---

## 2. Screens Implemented

Six functional, transport-tailored screens and views were implemented adhering to Google Stitch design tokens:

| Screen / View | File Path | Core Functionality |
| :--- | :--- | :--- |
| **1. Passenger Home** | [passenger_home_view.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/passenger_home_view.dart) | Hero destination search card ("Where are you going?"), active service alerts ticker, quick corridor presets, pull-to-refresh live departures with ETA (`tnum`), crowd density badges, occupancy %, and direct navigation to Live Map and Bus Details. |
| **2. Explore / Route Planning** | [passenger_explore_view.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/passenger_explore_view.dart) | Origin & Destination inputs with stop-swapping, corridor shortcuts, explainable journey recommendations from backend, distance and duration summaries, and corridor alternative cards. |
| **3. Live Map** | [passenger_live_map_view.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/passenger_live_map_view.dart) | Cross-platform interactive OpenStreetMap canvas (`flutter_map`), Kochi transit corridor polyline context (Aluva ➔ Edappally ➔ Kaloor ➔ Vyttila), live bus markers colored by crowd density, recentering & zoom controls, and selected vehicle inspection card. |
| **4. Bus Details** | [bus_details_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/bus_details_screen.dart) | Vehicle profile (bus number, operator, registration, AC indicator), live location, next stop & ETA countdown, cabin occupancy progress bar, safety & privacy standards, active route alert banner, and direct links to Crowd Forecast and Recommendations. |
| **5. Crowd Forecast** | [crowd_forecast_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/crowd_forecast_screen.dart) | Visual 4-horizon predictive trajectory (**NOW**, **+15 MIN**, **+30 MIN**, **+60 MIN**) with individual progress bars, crowd level badges, model confidence score, and prototype prediction disclosure note. |
| **6. Smart Recommendation** | [smart_recommendation_screen.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/smart_recommendation_screen.dart) | Explainable "Recommended for you" hero card presenting factors returned by backend (lower crowd delta %, priority corridor time savings, fare in INR, overall journey score) and side-by-side alternative bus comparison. |

---

## 3. API Endpoints Consumed

All screens interact through the strongly-typed `PassengerRepository` and `ApiClient`:

| Method | Endpoint | Consumer View / Provider | Purpose |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/buses` | `liveBusesProvider` | Live departures list and fleet locations for map pins |
| `GET` | `/api/buses/{bus_number}` | `getBusDetails` | Detailed vehicle telemetry profile |
| `GET` | `/api/locations` | `liveLocationsProvider` | Fleet GPS telemetry coordinates |
| `GET` | `/api/crowd` | `fleetCrowdProvider` | Fleet-wide cabin load density |
| `GET` | `/api/predictions/{bus_number}` | `busPredictionProvider(busNumber)` | 4-horizon demand prediction trajectory |
| `GET` | `/api/recommendations/plan` | `journeyPlanProvider` | Explainable journey planning with origin & destination query |
| `GET` | `/api/alerts/active` | `activeAlertsProvider` | Active corridor service advisories and incident alerts |
| `GET` | `/api/trips` | `activeTripsProvider` | Active corridor scheduled trips |

---

## 4. Riverpod Providers Architecture

Created in [passenger_providers.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/providers/passenger_providers.dart):

```
passengerRepositoryProvider (IPassengerRepository)
  ├── liveBusesProvider (FutureProvider<List<BusModel>>)
  ├── liveLocationsProvider (FutureProvider<List<LocationModel>>)
  ├── fleetCrowdProvider (FutureProvider<List<CrowdModel>>)
  ├── activeAlertsProvider (FutureProvider<List<AlertModel>>)
  ├── activeTripsProvider (FutureProvider<List<TripModel>>)
  ├── selectedBusProvider (StateProvider<BusModel?>)
  ├── journeyQueryProvider (StateProvider<JourneyQuery>)
  ├── journeyPlanProvider (FutureProvider<JourneyPlanModel>)
  └── busPredictionProvider.family<PredictionModel, String>
```

---

## 5. Navigation Changes

Updated [passenger_shell.dart](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/passenger_shell.dart):
- **Tab 0 (Home):** Renders [PassengerHomeView](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/passenger_home_view.dart) with quick-navigation callback to Explore.
- **Tab 1 (Explore):** Renders [PassengerExploreView](file:///d:/Bus_Sense_Ai/apps/mobile/lib/features/passenger/views/passenger_explore_view.dart).
- **Tabs 2, 3, 4 (Tickets, AI, Profile):** Retain verified shell foundation placeholders for subsequent phases.
- **Hierarchical Route Transitions:**
  - `Home / Explore / Live Map` $\rightarrow$ `BusDetailsScreen(bus)`
  - `BusDetailsScreen` $\rightarrow$ `CrowdForecastScreen(busNumber)`
  - `BusDetailsScreen` $\rightarrow$ `SmartRecommendationScreen(busNumber, routeName)`

---

## 6. UI & Design Implementation

- **Palette & Contrast:** Deep Forest Green (`#002620`), Primary Container (`#123C35`), Kerala Green (`#006C49`), Electric Mint (`#6CF8BB`), Surface (`#F3FBF7`).
- **Typography:** Plus Jakarta Sans across all headings, body text, and chips.
- **Tabular Numerals:** All ETAs, countdown timers, and occupancy percentages utilize `AppTypography.tabularNumeral` with `FontFeature.tabularFigures()`.
- **Restrained Cards:** Generous whitespace, clean dividers, and rounded surfaces (`roundedMd: 16px`, `roundedLg: 24px`).
- **Transit UX:** No decorative AI glowing halos, no cyberpunk themes, and zero cartoon illustrations.

---

## 7. Simulated-Data Labeling

Every UI element presenting simulated backend data is transparently badged:
- Bus departure cards: `SIMULATED DATA` badge
- Live map header: `SIMULATED GPS TELEMETRY • LIVE REFRESH` pill
- Crowd forecast: Stamped with `PREDICTION` and disclosure card explaining prototype XGBoost simulation
- Smart recommendations: Labeled with `RECOMMENDATION` and explicit disclaimer

---

## 8. Verification & Tests

### Mobile Unit & Widget Tests:
Created 10 comprehensive widget tests in [passenger_journey_test.dart](file:///d:/Bus_Sense_Ai/apps/mobile/test/passenger_journey_test.dart):
1. Passenger Home loading state
2. Passenger Home API success & live departures rendering
3. Passenger Home error state on API failure
4. Passenger Home empty state when no buses active
5. Explore screen origin/destination search & journey recommendations
6. Bus Details screen vehicle profile and occupancy progress
7. Crowd Forecast 4-horizon rendering with prediction badges
8. Smart Recommendation explainability factor rendering
9. PassengerShell navigation switching between Home, Explore, and placeholders
10. Live Map view loads and displays vehicle markers

**Flutter Test Run Result:**
```
00:18 +45: All tests passed!
```
Total mobile test suite: **45 / 45 tests passing**.

---

## 9. Flutter Analyze

Ran `flutter analyze` in `apps/mobile/`:
```
Analyzing mobile...                                             
No issues found! (ran in 3.4s)
```
**0 lint errors, 0 warnings, 0 syntax issues.**

---

## 10. Backend Regression

Ran backend test suite:
```powershell
& "backend/.venv/Scripts/python.exe" -m pytest backend/tests/ -v
```
**Result:** `25 passed, 1 warning in 47.03s` (100% passing). All H1, H2, and H3 persistent API contracts remain intact.

---

## 11. Authority Build

Ran Authority Next.js build:
```powershell
npm.cmd --prefix frontend run build
```
**Result:** Compiled successfully. Generated all 22 static pages without errors.

---

## 12. Remaining Passenger Screens (Deferred to Batch 2)

The following passenger flows were explicitly NOT implemented in Batch 1 and are ready for Batch 2:
- Digital Ticket Booking flow & seat selection
- Razorpay test payment sheet
- Digital QR Ticket display with dynamic anti-screenshot watermarking
- Commuter ticket history & pass management
- Active Journey HUD (live onboard tracking)

---

## 13. Explicit H5 Batch 2 Boundary

Phase H5 Batch 1 is complete. Do NOT automatically proceed to Batch 2 or Conductor operations until instructed.
