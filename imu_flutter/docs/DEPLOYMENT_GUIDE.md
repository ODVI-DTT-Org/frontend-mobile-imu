# IMU Mobile App - Deployment Guide

> **Version:** 1.0
> **Last Updated:** 2026-04-02
> **App:** IMU (Itinerary Manager - Uniformed) Flutter Mobile App

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Build Configuration](#build-configuration)
4. [Building for Android](#building-for-android)
5. [Building for iOS](#building-for-ios)
6. [Release Checklist](#release-checklist)
7. [Deployment Process](#deployment-process)
8. [Rollback Plan](#rollback-plan)
9. [Post-Deployment](#post-deployment)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

| Tool | Minimum Version | Recommended | Installation |
|------|----------------|-------------|--------------|
| **Flutter SDK** | 3.2.0 | 3.24.0+ | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| **Dart SDK** | 3.0.0 | 3.5.0+ | Included with Flutter |
| **Android Studio** | 2023.1+ | Latest | [developer.android.com](https://developer.android.com/studio) |
| **Xcode** (iOS only) | 15.0+ | Latest | Mac App Store |
| **Git** | 2.40+ | Latest | [git-scm.com](https://git-scm.com) |

### Required Accounts

- **Google Play Console** (Android distribution)
- **Apple Developer Account** (iOS distribution)
- **GitHub** (source code management)
- **Mapbox Account** (map services)

---

## Environment Setup

### 1. Clone Repository

```bash
git clone https://github.com/ODVI-DTT-Org/frontend-mobile-imu.git
cd frontend-mobile-imu/mobile/imu_flutter
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment Variables

Create environment files:

```bash
# Development
cp .env.dev.example .env.dev

# Production
cp .env.prod.example .env.prod
```

**Required Environment Variables:**

```bash
# API Configuration
API_BASE_URL=https://imu-api.cfbtools.app/api

# PowerSync Configuration
POWERSYNC_URL=https://xxx.powersync.journeyapps.com

# JWT Configuration
JWT_SECRET=your-production-jwt-secret-min-32-chars

# Mapbox Configuration
MAPBOX_ACCESS_TOKEN=your-mapbox-access-token

# App Configuration
DEBUG_MODE=false
LOG_LEVEL=info
```

### 4. Verify Setup

```bash
flutter doctor
flutter analyze
flutter test
```

---

## Build Configuration

### Android Build Configuration

**File:** `android/app/build.gradle`

```gradle
android {
    compileSdkVersion 35

    defaultConfig {
        applicationId "com.odvi.imu"
        minSdkVersion 21
        targetSdkVersion 35
        versionCode 1
        versionName "1.0.0"
    }

    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
    }
}
```

### iOS Build Configuration

**File:** `ios/Runner.xcodeproj/project.pbxproj`

- **Deployment Target:** iOS 13.0+
- **Bundle Identifier:** com.odvi.imu
- **Signing:** Apple Distribution Certificate

---

## Building for Android

### 1. Build Debug APK

```bash
flutter build apk --debug
```

**Output:** `build/app/outputs/flutter-apk/app-debug.apk`

### 2. Build Release APK

```bash
flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### 3. Build App Bundle (Recommended for Play Store)

```bash
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

### 4. Build for Specific Architecture

```bash
# ARM64 (most devices)
flutter build apk --release --target-platform android-arm64

# ARM32 (older devices)
flutter build apk --release --target-platform android-arm32

# x86_64 (emulators)
flutter build apk --release --target-platform android-x64
```

### 5. Split APK by Architecture

```bash
flutter build apk --release --split-per-abi
```

**Outputs:**
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (x86-64)

---

## Building for iOS

### 1. Build Debug IPA

```bash
flutter build ios --debug
```

### 2. Build Release IPA

```bash
flutter build ios --release
```

### 3. Build for App Store

```bash
flutter build ipa --release
```

**Output:** `build/ios/archive/Runner.xcarchive`

### 4. Export from Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Product → Archive
3. Wait for archive to complete
4. Click "Distribute App"
5. Follow App Store Connect prompts

---

## Release Checklist

### Pre-Release Checks ✅

- [ ] All tests passing (unit, widget, integration)
- [ ] Code review completed
- [ ] Security scan completed
- [ ] Performance testing completed
- [ ] Documentation updated
- [ ] Version number incremented
- [ ] Release notes prepared

### Security Checks ✅

- [ ] No hardcoded secrets in code
- [ ] JWT secret configured for production
- [ ] API endpoints using HTTPS
- [ ] Debug mode disabled
- [ ] Logging set to appropriate level
- [ ] Permissions properly declared

### Testing Checks ✅

- [ ] RBAC system tested (all roles)
- [ ] Touchpoint creation tested
- [ ] Offline sync tested
- [ ] Token refresh tested
- [ ] GPS functionality tested
- [ ] Camera/audio recording tested

### Performance Checks ✅

- [ ] App startup time < 3 seconds
- [ ] Memory usage acceptable
- [ ] No memory leaks
- [ ] Battery usage acceptable
- [ ] Network usage optimized

---

## Deployment Process

### Automated Deployment (Recommended)

#### Using GitHub Actions

**File:** `.github/workflows/deploy-android.yml`

```yaml
name: Deploy Android

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'

      - name: Build APK
        run: |
          flutter pub get
          flutter build apk --release --split-per-abi

      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.SERVICE_ACCOUNT_JSON }}
          packageName: com.odvi.imu
          releaseFiles: build/app/outputs/flutter-apk/*.apk
          track: internal
```

### Manual Deployment

#### Android Deployment Steps

1. **Build Release APK/AAB**
   ```bash
   flutter build appbundle --release
   ```

2. **Sign APK** (if not using build.gradle config)
   ```bash
   jarsigner -keystore ~/key.jks -storepass $STORE_PASSWORD -keypass $KEY_PASSWORD build/app/outputs/flutter-apk/app-release.apk release
   ```

3. **Upload to Google Play Console**
   - Go to [Play Console](https://play.google.com/console)
   - Select app: IMU
   - Navigate to: Release → Production → Create new release
   - Upload AAB file
   - Add release notes
   - Submit for review

#### iOS Deployment Steps

1. **Build Archive**
   ```bash
   flutter build ios --release
   ```

2. **Open in Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

3. **Archive and Export**
   - Product → Archive
   - Distribute App → App Store Connect
   - Upload to App Store Connect

4. **Submit for Review**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Select app: IMU
   - Add version information
   - Submit for review

---

## Rollback Plan

### Immediate Rollback (< 1 hour)

**Android:**
1. Go to Google Play Console
2. Navigate to: Release → Production
3. Click "Halt rollout" → "Stop rollout"
4. Previous version becomes active immediately

**iOS:**
1. Go to App Store Connect
2. Select app → Previous version
3. Click "Make available to all users"
4. Submit update (processed within 24 hours)

### Emergency Rollback (< 15 minutes)

**Database Issues:**
1. Disable API endpoints
2. Switch to maintenance mode
3. Restore database from backup
4. Re-enable endpoints

**Backend Issues:**
1. Scale down backend deployment
2. Revert to previous backend version
3. Scale up deployment
4. Verify functionality

---

## Post-Deployment

### Monitoring (First 24 Hours)

**Critical Metrics:**
- Crash rate (< 1% acceptable)
- API error rate (< 5% acceptable)
- App startup time (< 3 seconds)
- User engagement (daily active users)
- Battery usage impact

**Monitoring Tools:**
- Firebase Crashlytics
- Google Play Console Vitals
- App Store Connect Analytics
- Backend logs (error logs dashboard)

### User Communication

**Day 1:**
- Announce new features
- Highlight bug fixes
- Provide support contact

**Day 7:**
- Collect user feedback
- Address reported issues
- Prepare hotfix if needed

**Day 30:**
- Review performance metrics
- Plan next release
- Document lessons learned

---

## Troubleshooting

### Common Build Issues

#### Issue: "Flutter not found"

**Solution:**
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Or use full path
/path/to/flutter/bin/flutter build apk
```

#### Issue: "Gradle build failed"

**Solution:**
```bash
# Clean build cache
cd android
./gradlew clean
cd ..

# Retry build
flutter build apk --release
```

#### Issue: "Code signing error"

**Solution (iOS):**
```bash
# Clean iOS build
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

# Retry build
flutter build ios --release
```

### Common Runtime Issues

#### Issue: "Network request failed"

**Diagnosis:**
1. Check API base URL in `.env.prod`
2. Verify backend is accessible
3. Check network permissions

**Solution:**
```bash
# Test API connectivity
curl https://imu-api.cfbtools.app/api/health

# Verify permissions in AndroidManifest.xml
# <uses-permission android:name="android.permission.INTERNET" />
```

#### Issue: "Map not displaying"

**Diagnosis:**
1. Check Mapbox access token
2. Verify token is valid
3. Check network connectivity

**Solution:**
```bash
# Verify Mapbox token
echo $MAPBOX_ACCESS_TOKEN

# Test token validity
curl "https://api.mapbox.com/geocoding/v5/mapbox.places/Manila.json?access_token=$MAPBOX_ACCESS_TOKEN"
```

#### Issue: "Permissions denied"

**Diagnosis:**
1. Check RBAC configuration
2. Verify user role in database
3. Check permission cache

**Solution:**
```bash
# Clear permission cache (user needs to logout/login)
# Or use admin panel to refresh permissions
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-04-02 | Initial production release |
| | | RBAC system implementation |
| | | Offline-first sync with PowerSync |
| | | Touchpoint validation by role |
| | | JWT authentication with refresh |
| | | Mapbox integration |

---

## Support

**Development Team:** ODVI Development Team
**Documentation:** [CLAUDE.md](../CLAUDE.md)
**Architecture:** [docs/architecture/README.md](../docs/architecture/README.md)
**Testing:** [docs/TEST_RESULTS_2026-04-02.md](TEST_RESULTS_2026-04-02.md)

---

**Last Updated:** 2026-04-02
**Document Version:** 1.0
