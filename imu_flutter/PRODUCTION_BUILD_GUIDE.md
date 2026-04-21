# IMU Production Build Guide

## Overview

This guide explains how to build production APKs for the IMU mobile application.

## Prerequisites

- Flutter SDK 3.2.0 or higher
- Android SDK with API level 36
- Java Development Kit (JDK) 11 or higher
- Release keystore (already generated)

## Production Configuration Files

### 1. `.env.prod` - Environment Configuration
Located at: `mobile/imu_flutter/.env.prod`

Contains:
- Production PowerSync URL
- Production Backend API URL
- JWT secret (for local validation)
- PostHog analytics key

### 2. `android/key.properties` - Keystore Credentials
Located at: `mobile/imu_flutter/android/key.properties`
⚠️ **DO NOT COMMIT THIS FILE TO GIT**

Contains:
- Keystore password
- Key alias
- Key password

### 3. `android/app/release.keystore` - Release Signing Key
Located at: `mobile/imu_flutter/android/app/release.keystore`
⚠️ **DO NOT COMMIT THIS FILE TO GIT**

## Building Production APK

### Option 1: Standard Release Build

```bash
cd mobile/imu_flutter
flutter build apk --release
```

This creates: `build/app/outputs/flutter-apk/app-release.apk`

### Option 2: App Bundle for Play Store

```bash
cd mobile/imu_flutter
flutter build appbundle --release
```

This creates: `build/app/outputs/bundle/release/app-release.aab`

### Option 3: Split APKs (smaller size)

```bash
cd mobile/imu_flutter
flutter build apk --split-per-abi --release
```

This creates separate APKs for each architecture:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (x86-64)

## Build Output Location

All builds are output to:
- APKs: `mobile/imu_flutter/build/app/outputs/flutter-apk/`
- App Bundles: `mobile/imu_flutter/build/app/outputs/bundle/`

## Testing Production Build

### 1. Install on Device

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 2. Verify Configuration

After launching the production app, verify:
- ✅ Production API URL: `https://imu-api.cfbtools.app/api`
- ✅ Production PowerSync URL
- ✅ Debug mode is disabled
- ✅ Analytics is working (PostHog)
- ✅ All features work correctly

### 3. Check Logs

```bash
adb logcat | grep -E "IMU|PowerSync|AppConfig"
```

## Signing Information

**Keystore:** `release.keystore`
**Alias:** `imu-release-key`
**Password:** `imu2026`
**Validity:** 10,000 days

## Version Management

Update version in `pubspec.yaml`:

```yaml
name: imu_flutter
version: 1.3.2+5  # versionName+versionCode
```

- `versionName`: Human-readable version (e.g., 1.3.2)
- `versionCode`: Integer for Play Store (e.g., 5)

## Environment-Specific Builds

### Development Build
```bash
flutter build apk --debug
```

### QA Build
```bash
flutter build apk --release --dart-define=ENV=qa
```

### Production Build
```bash
flutter build apk --release
```

## Play Store Submission

### Required Screenshots
- Feature graphic: 1024 x 500 px
- 7-inch tablet screenshots
- 8-inch tablet screenshots
- Phone screenshots (at least 2)

### Required Information
- App name: IMU
- Package name: com.odvi.imu
- Category: Business
- Content rating: Everyone

## Troubleshooting

### Build Errors

**Error:** "Execution failed for task ':app:validateReleaseSigning'"

**Solution:** Ensure `key.properties` and `release.keystore` exist in `android/` directory.

**Error:** "Flutter SDK not found"

**Solution:** Check `android/local.properties` contains valid Flutter SDK path.

### Signing Issues

**Error:** "Keystore file not found"

**Solution:** Run keystore generation command:
```bash
keytool -genkey -v -keystore android/app/release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass imu2026 -keypass imu2026 \
  -alias imu-release-key \
  -dname "CN=IMU Production, OU=Development, O=ODVI, C=PH"
```

## Security Checklist

- [ ] Keystore file is NOT in git
- [ ] key.properties is NOT in git
- [ ] .env.prod has correct production URLs
- [ ] JWT_SECRET is at least 32 characters
- [ ] DEBUG_MODE=false in production
- [ ] ProGuard is enabled (minifyEnabled=true)
- [ ] No hardcoded secrets in code
- [ ] SSL certificate pinning (optional, currently disabled)

## Release Process

1. Update version in `pubspec.yaml`
2. Test all features thoroughly
3. Build production APK/App Bundle
4. Install on test device and verify
5. Submit to Google Play Console
6. Wait for review and approval
7. Release to production

## Contact

For issues or questions, contact the development team.

---

**Last Updated:** April 2026
**App Version:** 1.3.2
**Build Number:** 5
