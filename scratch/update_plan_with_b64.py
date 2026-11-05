import os

artifact_dir = r"C:\Users\Admin\.gemini\antigravity\brain\a60c6a03-0c93-459a-a20c-4a9cbbbce86e"

with open(os.path.join(artifact_dir, "solid_a_256.png.b64")) as f:
    b64_a = f.read().strip()

with open(os.path.join(artifact_dir, "solid_b_256.png.b64")) as f:
    b64_b = f.read().strip()

with open(os.path.join(artifact_dir, "solid_c_256.png.b64")) as f:
    b64_c = f.read().strip()

plan_content = f"""# Implementation Plan: Google Stitch Mobile Overhaul, Solid Aesthetic Icon & Universal Authentication

## Goal Description
Transform the BusSense AI mobile app (`apps/mobile/`) into a production-grade, beautifully polished transit application adhering strictly to the **Google Stitch Design System** (Project `14259704318600090723`).

This upgrade addresses all 4 key user mandates:
1. **Solid Aesthetic Icon Palette:** Replace the default Flutter logo with a bold, minimalist transit icon inspired by world-class transit apps (Citymapper, Transit App, SBB).
2. **Unified Branding ("BusSense AI"):** Rename the app label from `bussense_mobile` / "Passenger" to strictly **"BusSense AI"** across Android launcher, headers, and app manifests.
3. **Rock-Solid Multi-Role Authentication:** Fix the `localhost` release bug in `EnvConfig` and ensure all roles (**Passenger**, **Driver/Conductor**, **Authority**) can log in reliably on physical Android devices.
4. **Google Stitch UI without Mock Dummy Data:** Wire the UI directly to live Supabase Cloud PostgREST endpoints (`routes`, `stops`, `buses`, `alerts`) with Stitch visual hierarchy.

---

## 1. Visual Icon Options (Rendered Inline)

Review the 3 solid aesthetic designs rendered directly below. Each option uses the official solid Stitch palette:
- **Solid Deep Kerala Evergreen (`#002620`)**
- **Chalk White (`#FFFFFF`)**
- **Electric Mint (`#6CF8BB`)**
- **Solid Vibrant Emerald (`#005C3E`)**

---

### Solid Option A: "The City Transit Bus" (Inspired by Citymapper / Chalo)
> A solid deep Kerala Evergreen background featuring a bold, clean, chalk-white geometric minimalist bus face with electric mint circular beacon headlights and panoramic glass. High contrast, friendly, bold, instantly identifiable on any mobile home screen.

<img src="data:image/png;base64,{b64_a}" alt="Solid Option A — City Transit Bus" width="220" style="border-radius: 28px; box-shadow: 0 4px 16px rgba(0,0,0,0.15); margin: 12px 0;" />

---

### Solid Option B: "The Transit Line Curve" (Inspired by Transit App)
> A solid punchy Deep Emerald squircle with a continuous, bold white transit corridor track gracefully curving through an electric mint central station hub node with an active forward arrow. Pure geometric mobility design.

<img src="data:image/png;base64,{b64_b}" alt="Solid Option B — Transit Line Curve" width="220" style="border-radius: 28px; box-shadow: 0 4px 16px rgba(0,0,0,0.15); margin: 12px 0;" />

---

### Solid Option C: "The Nordic Rail / Metro Monogram" (Inspired by SBB / Tokyo Metro)
> A solid Deep Evergreen squircle with an ultra-clean geometric transit monogram forming a stylized **"B"** through a forward mobility wing in solid mint and a return corridor loop in solid white, accented with an emerald station beacon. Editorial, authoritative, and timeless.

<img src="data:image/png;base64,{b64_c}" alt="Solid Option C — Nordic Rail Monogram" width="220" style="border-radius: 28px; box-shadow: 0 4px 16px rgba(0,0,0,0.15); margin: 12px 0;" />

---

## 2. User Review Required

> [!IMPORTANT]
> **Select Your Preferred Solid Aesthetic Icon:**
> Review the 3 images rendered above:
> - **Solid Option A (Recommended):** City Transit Bus (White Bus Face with Mint Headlights on Solid Deep Evergreen)
> - **Solid Option B:** Transit Line Curve (Continuous White Corridor Track on Solid Emerald)
> - **Solid Option C:** Nordic Rail Monogram (Geometric 'B' Mobility Wings on Solid Deep Evergreen)

> [!IMPORTANT]
> **App Name Standardization:**
> The app launcher label in `AndroidManifest.xml` will be set to:
> ```xml
> android:label="BusSense AI"
> ```
> All sub-branding like "Passenger" or "bussense_mobile" will be removed. All user roles log in through this single unified app.

---

## 3. Technical Implementation Details

### Component 1: Launcher Icons & Android Manifest

#### [MODIFY] `apps/mobile/android/app/src/main/AndroidManifest.xml`
- Change `android:label="bussense_mobile"` to `android:label="BusSense AI"`.
- Configure adaptive icon XML links (`@mipmap/ic_launcher` and `@mipmap/ic_launcher_round`).

#### [NEW] Android Adaptive Icon Layers
- `android/app/src/main/res/values/ic_launcher_background.xml` (Solid color `#002620`).
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` and `ic_launcher_round.xml`.
- Replace legacy PNGs across `mipmap-mdpi`, `mipmap-hdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi` with the chosen solid aesthetic design.

#### [NEW] `apps/mobile/lib/shared/widgets/bussense_logo.dart`
- In-app vector emblem mirroring the chosen icon for the splash screen, auth header, and drawer.

---

### Component 2: Rock-Solid Multi-Role Authentication

#### Root Cause of the Release Login Bug
In `apps/mobile/lib/core/config/env_config.dart`, line 22:
```dart
static String apiBaseUrl = const bool.hasEnvironment('API_BASE_URL')
    ? const String.fromEnvironment('API_BASE_URL')
    : _defaultIosBaseUrl; // 'http://localhost:8000/api'
```
Because `_defaultIosBaseUrl` was used as fallback, every HTTP call on physical Android devices targeted `http://localhost:8000`, causing network timeouts and login failures.

#### [MODIFY] `apps/mobile/lib/core/config/env_config.dart`
- Set the default base URL to the live Supabase cloud instance:
  ```dart
  static const String defaultSupabaseUrl = 'https://lqegmqgkymstycpzplld.supabase.co';
  static const String defaultPostgrestUrl = 'https://lqegmqgkymstycpzplld.supabase.co/rest/v1';
  static String apiBaseUrl = const bool.hasEnvironment('API_BASE_URL')
      ? const String.fromEnvironment('API_BASE_URL')
      : defaultPostgrestUrl;
  ```

#### [MODIFY] `apps/mobile/lib/features/auth/controllers/auth_controller.dart`
- Implement resilient authentication for all roles:
  - **Passenger:** `rahul@bussense.ai` / `rahul.nair@bussense.kerala.gov.in` (Password: `demo1234`) ➔ Routes to `PassengerShell`.
  - **Driver/Conductor:** `suresh@bussense.ai` / `suresh.kumar@bussense.kerala.gov.in` (Password: `demo1234`) ➔ Routes to `ConductorShell`.
  - **Authority:** `anjali@bussense.ai` / `anjali.menon@bussense.kerala.gov.in` (Password: `demo1234`) ➔ Routes to `AuthorityOverviewScreen`.
  - Also supports user registration and login directly via Supabase Auth.
- Persist valid JWT session in `FlutterSecureStorage` so login state survives app restarts.

---

### Component 3: Google Stitch UI Transformation (Zero Mock Data)

#### [MODIFY] `apps/mobile/lib/features/passenger/views/passenger_shell.dart`
- Remove the clunky `BusSenseAppBar`.
- Implement Stitch's glassmorphic sticky top navigation bar:
  - Custom minimal logo pill + live green pulse dot.
  - Title: `KOCHI, KERALA • BusSense AI`.
  - Live Sync pill with sensor icon.
  - Commuter profile avatar button.
- Grounded Stitch bottom navigation bar with custom rounded container and active mint highlight pills.

#### [MODIFY] `apps/mobile/lib/features/passenger/views/passenger_home_view.dart`
- Replace mock data fallbacks with live Supabase queries (`routes`, `stops`, `buses`, `alerts`).
- **Greeting & Location:** "Good Morning, [Name]" with landmark location chip (`near_me Near Kaloor Metro Station, Kochi`).
- **Hero Destination Search:** Search container with mic button and horizontal destination chips (`Infopark Phase 1`, `Ernakulam South Station`, `Aluva Metro`, `Fort Kochi Jetty`).
- **Predictive Transit Insight (Stitch Spotlight):** Deep forest container (`#123C35`) with bold crowd reduction statistic and expandable **"Why?"** rationalization drawer.
- **Stitch Bus Cards:**
  - Route badge in deep evergreen rounded container.
  - Route title with directional arrow (`➔`).
  - Tabular countdown ETA numerals (jitter-free).
  - Occupancy percentage bar with crowd badge (`LOW`, `MODERATE`, `CROWDED`).
  - Factual truth stamp (`SIMULATED DATA` / `PREDICTION`).

#### [MODIFY] `apps/mobile/lib/features/conductor/views/conductor_shell.dart`
- Night-vision friendly, high-contrast operational cockpit with 48px+ touch targets and live trip controls.

---

## 4. Verification Plan

### Automated Tests
```bash
cd apps/mobile
flutter test
```
*Target: 100/100 tests passing with zero regressions.*

### Production APK Build
```bash
cd apps/mobile
flutter build apk --release
```
*Target: Clean release APK compilation with new launcher icon and updated manifest label.*

### Manual On-Device Verification
1. **Launcher Icon:** Verify the Android home screen shows the new solid aesthetic icon.
2. **App Name:** Confirm the app is labeled **"BusSense AI"** (not "bussense_mobile" or "Passenger").
3. **Multi-Role Login:**
   - Tap `Passenger (Rahul)` ➔ Logs in and opens Stitch Passenger Shell.
   - Tap `Conductor (Suresh)` ➔ Logs in and opens Conductor Cockpit.
   - Tap `Authority (Anjali)` ➔ Logs in and opens Authority Overview.
4. **Live Data:** Confirm bus routes and stops load dynamically from the live Supabase database.
"""

plan_path = os.path.join(artifact_dir, "stitch_mobile_ui_and_logo_plan.md")
with open(plan_path, "w", encoding="utf-8") as f:
    f.write(plan_content)

print(f"Plan updated successfully at {plan_path} with inline base64 images!")

