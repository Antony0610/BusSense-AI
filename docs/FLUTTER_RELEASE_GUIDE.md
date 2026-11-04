# BusSense AI — Flutter Production Release Guide
## Android Release Builds for Passenger & Conductor Applications

**Application:** BusSense AI Unified Mobile Client (`apps/mobile/`)  
**Target Platform:** Android (API Level 21+ / Android 5.0 to 14.0)  
**Package Identifier:** `ai.bussense.bussense_mobile`  
**Version:** `1.0.0+1`  
**Document Version:** 1.1.1-H23  
**Date:** November 2026  
**Build Status:** 100/100 TESTS PASSED | 53.4 MB RELEASE APK VERIFIED  

---

## 1. Release Architecture & Configuration

The Flutter mobile application supports both the **Passenger Experience** and the **Driver/Conductor Cockpit** within a single unified codebase governed by role-based routing.

### Backend Connectivity
- **Production Supabase Host:** `https://lqegmqgkymstycpzplld.supabase.co`
- **Unified API Gateway:** `https://lqegmqgkymstycpzplld.supabase.co/functions/v1/api`
- **Realtime Gateway:** `wss://lqegmqgkymstycpzplld.supabase.co/realtime/v1/websocket`
- Configured dynamically via `--dart-define` compilation flags or `EnvConfig.defaultEdgeFunctionApiUrl`.
- **Zero Localhost References:** All development `10.0.2.2` and `localhost` fallbacks are locked out of production release builds.

---

## 2. Release Signing Configuration

### 2.1 Signing Status Disclosure
In Phase H23, the release APK was generated using:
- **Build Mode:** Release optimization with ProGuard, R8, and tree-shaken font icons.
- **Signing Keystore:** Standard Android debug keystore (`signingConfig = signingConfigs.getByName("debug")`).
- **Operational Scope:** Suitable for pilot side-loading on test devices via ADB. **Not claimed as a Google Play production-signed release** until signed with an institutional transport authority KeyStore.

### 2.2 Production Keystore Setup (For Google Play / OEM distribution)
```bash
# Generate production keystore
keytool -genkey -v -keystore apps/mobile/android/app/bussense-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias bussense-release
```

Create `apps/mobile/android/key.properties`:
```properties
storePassword=<SECURE_KEYSTORE_PASSWORD>
keyPassword=<SECURE_KEY_PASSWORD>
keyAlias=bussense-release
storeFile=bussense-release-key.jks
```

---

## 3. Build & Compilation Verification

### Automated Test Suite
```bash
cd apps/mobile
flutter test
```
**Results (Phase H23):** `100 / 100 passed` in 45.0 seconds.

### Generating the Release APK
```bash
cd apps/mobile
flutter build apk --release
```

### Verified Release Artifacts:
- **File Path:** `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`
- **File Size:** `56,009,434 bytes` (~53.4 MB)
- **Target Architectures:** `armeabi-v7a`, `arm64-v8a`, `x86_64` (Universal APK)

---

## 4. Physical Android Device Side-Loading & Testing

To install and verify the release APK on a physical Android test device:

```bash
# 1. Connect Android device with USB Debugging enabled
adb devices

# 2. Install the release APK
adb install -r apps/mobile/build/app/outputs/flutter-apk/app-release.apk

# 3. Launch the application
adb shell monkey -p ai.bussense.bussense_mobile -c android.intent.category.LAUNCHER 1
```

### Verification Checklist on Device:
- [x] Application launches without crashing on Android 12/13/14.
- [x] Role selector renders (`Passenger`, `Driver / Conductor`, `Authority`).
- [x] Passenger route and stop discovery loads data from Supabase cloud.
- [x] Conductor shift check-in and QR ticket scanner activates device camera.
- [x] Network disconnection gracefully triggers offline banner without force-close.

---
*BusSense AI Flutter Release Guide — Version 1.1.1-H23*
