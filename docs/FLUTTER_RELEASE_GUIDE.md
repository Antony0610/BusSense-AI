# BusSense AI — Flutter Production Release Guide
## Android Release Builds for Passenger & Conductor Applications

**Application:** BusSense AI Unified Mobile Client (`apps/mobile/`)  
**Target Platform:** Android (API Level 21+ / Android 5.0 to 14.0)  
**Package Identifier:** `ai.bussense.bussense_mobile`  
**Version:** `1.0.0+1`  
**Document Version:** 1.0.0-H22  
**Date:** November 2026

---

## 1. Release Architecture & Configuration

The Flutter mobile application supports both the **Passenger Experience** and the **Driver/Conductor Cockpit** within a single unified Flutter codebase governed by role-based routing.

### Backend Connectivity
- **Production Supabase Host:** `https://lqegmqgkymstycpzplld.supabase.co`
- **Unified API Gateway:** `https://lqegmqgkymstycpzplld.supabase.co/functions/v1/api`
- **Realtime Gateway:** `wss://lqegmqgkymstycpzplld.supabase.co/realtime/v1/websocket`
- Configured dynamically via `--dart-define` compilation flags or `EnvConfig.defaultEdgeFunctionApiUrl`.
- **Zero Localhost References:** All development `10.0.2.2` and `localhost` fallbacks are locked out of production release builds.

---

## 2. Release Signing Configuration

### 2.1 Generating a Production Keystore
Generate a private Java KeyStore file (do NOT commit to git):
```bash
keytool -genkey -v -keystore apps/mobile/android/app/bussense-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias bussense-release
```

### 2.2 Configuring `key.properties`
Create `apps/mobile/android/key.properties` (protected by `.gitignore`):
```properties
storePassword=<SECURE_KEYSTORE_PASSWORD>
keyPassword=<SECURE_KEY_PASSWORD>
keyAlias=bussense-release
storeFile=bussense-release-key.jks
```

### 2.3 Gradle Signing Hook
`apps/mobile/android/app/build.gradle.kts` incorporates the signing configuration:
```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}
```

---

## 3. Building Android Release Artifacts

### 3.1 Building Signed Release APK
To generate a standalone APK suitable for conductor POS devices and passenger pilot sideloading:
```bash
cd apps/mobile
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://lqegmqgkymstycpzplld.supabase.co \
  --dart-define=API_BASE_URL=https://lqegmqgkymstycpzplld.supabase.co/functions/v1/api
```
- **Output Artifact:** `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`
- **Verified Size:** `53.4 MB`
- **Compilation Status:** `BUILD SUCCESSFUL`

### 3.2 Building Android App Bundle (AAB) for Google Play
To generate an optimized bundle for Play Store distribution:
```bash
cd apps/mobile
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://lqegmqgkymstycpzplld.supabase.co \
  --dart-define=API_BASE_URL=https://lqegmqgkymstycpzplld.supabase.co/functions/v1/api
```
- **Output Artifact:** `apps/mobile/build/app/outputs/bundle/release/app-release.aab`

---

## 4. Permissions & Privacy Audit

The Android Manifest (`apps/mobile/android/app/src/main/AndroidManifest.xml`) requires only standard mobility permissions:
- `android.permission.INTERNET`: Communicating with Supabase and real-time fleet channels.
- `android.permission.ACCESS_FINE_LOCATION`: Snapping user position to nearest Greater Kochi stop.
- `android.permission.ACCESS_COARSE_LOCATION`: Rough corridor discovery.
- `android.permission.CAMERA`: QR ticket scanning on conductor POS terminals.

**Privacy Verification:** Zero biometric hardware permissions, audio recording, or background identity harvesting permissions are requested.

---

## 5. Device Verification Checklist

Before deploying the APK to conductor test devices:
- [ ] Install APK: `adb install -r build/app/outputs/flutter-apk/app-release.apk`
- [ ] Confirm app launches smoothly to login screen.
- [ ] Log in as passenger: confirm Route 205 & 14A live cards render.
- [ ] Book test ticket: verify base64 QR boarding pass displays.
- [ ] Log in as conductor: test scanner and confirm ticket validates in $< 200\text{ms}$.
- [ ] Double-scan: confirm `ALREADY_USED` rejection displays.

---
*BusSense AI Flutter Release Guide — Version 1.0.0-H22*
