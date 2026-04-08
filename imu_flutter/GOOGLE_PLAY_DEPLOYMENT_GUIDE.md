# Google Play Store Deployment Guide - IMU Flutter App

> **Version:** 1.0
> **Last Updated:** 2026-04-07
> **App Version:** 1.3.2+5

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Code Quality & Testing](#code-quality--testing)
3. [App Signing](#app-signing)
4. [Building Release APK/AAB](#building-release-apkaab)
5. [Play Store Listing](#play-store-listing)
6. [Testing Checklist](#testing-checklist)
7. [Post-Release](#post-release)

---

## Prerequisites

### Required Software
- ✅ Flutter SDK 3.24.5
- ✅ Dart SDK 3.5.4
- ✅ Android SDK 36 (API Level 36)
- ✅ Android Studio 2024.1
- ✅ Java JDK 17+
- ✅ keytool (included in JDK)

### Environment Setup
```bash
# Verify Flutter installation
flutter doctor -v

# Check available devices
flutter devices

# Verify Android SDK
flutter doctor --android-licenses
```

---

## Code Quality & Testing

### Current Analysis Status
- **Total Issues:** 912 (mostly style warnings)
- **Critical Issues:** Fixed (deprecated lint rules removed)
- **Test Status:** Some integration tests need fixing

### Running Analysis
```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Run integration tests
flutter test integration_test/
```

### Known Issues & Fixes
1. ✅ **Deprecated lint rules** - Fixed in analysis_options.yaml
2. ✅ **Release signing configuration** - Fixed in build.gradle
3. ✅ **ProGuard rules** - Added proguard-rules.pro

---

## App Signing

### Generate Production Keystore

**Option 1: Use the provided script**
```bash
cd mobile/imu_flutter
bash generate-keystore.sh
```

**Option 2: Manual generation**
```bash
# Generate keystore
keytool -genkey \
    -v \
    -keystore release.keystore \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias release \
    -dname "CN=IMU, OU=ODVI, O=ODVI, L=Cebu, ST=Cebu, PH"
```

### Security Best Practices

**DO:**
- ✅ Store keystore file securely (password manager, encrypted drive)
- ✅ Backup keystore in multiple secure locations
- ✅ Use strong passwords (minimum 12 characters, mixed case, numbers, symbols)
- ✅ Document keystore location and passwords securely
- ✅ Add keystore file to .gitignore

**DON'T:**
- ❌ Commit keystore file to git
- ❌ Share keystore passwords via email/chat
- ❌ Use debug keystore for production builds
- ❌ Store keystore in project directory
- ❌ Use weak passwords

### Environment Variables

Set environment variables before building:

**Windows (Command Prompt):**
```cmd
set KEYSTORE_PASSWORD=your_store_password
set KEY_PASSWORD=your_key_password
set KEY_ALIAS=release
```

**Windows (PowerShell):**
```powershell
$env:KEYSTORE_PASSWORD='your_store_password'
$env:KEY_PASSWORD='your_key_password'
$env:KEY_ALIAS='release'
```

**Linux/Mac:**
```bash
export KEYSTORE_PASSWORD=your_store_password
export KEY_PASSWORD=your_key_password
export KEY_ALIAS=release
```

---

## Building Release APK/AAB

### Build Release APK (for testing)
```bash
# Set environment variables first
set KEYSTORE_PASSWORD=your_store_password
set KEY_PASSWORD=your_key_password
set KEY_ALIAS=release

# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (for Play Store)
```bash
# Build App Bundle (AAB) - REQUIRED for Play Store
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build Commands with Options
```bash
# Build for specific architectures
flutter build apk --release --split-per-abi

# Build with obfuscation
flutter build apk --release --obfuscate --split-debug-info=./build/app/outputs/symbols

# Build with size optimization
flutter build apk --release --analyze-size
```

---

## Play Store Listing

### Store Listing Requirements

#### App Information
- **App Name:** IMU - Itinerary Manager Uniformed
- **Short Description:** Field agent management app for client visits and touchpoints
- **Full Description:** [See description template below]
- **Language:** English
- **Category:** Productivity / Business

#### Description Template
```
IMU (Itinerary Manager Uniformed) is a comprehensive mobile application
designed for field agents managing client visits and touchpoints.

KEY FEATURES:
• Client Management - View and manage client information offline
• Touchpoint Tracking - Record visit and call touchpoints with GPS location
• Itinerary Management - Daily schedules and route optimization
• Offline-First - Works without internet connection, syncs when online
• Secure Authentication - PIN-based authentication with biometric support
• Real-Time Sync - Automatic data synchronization when online
• Location Services - GPS tracking and address verification
• Photo & Audio - Capture photos and audio recordings for touchpoints

TARGET USERS:
• Field agents (Caravan) managing client visits
• Telemarketers (Tele) making follow-up calls
• Area managers overseeing field operations

PERMISSIONS:
• Location - For GPS tracking and address verification
• Camera - For capturing touchpoint photos
• Microphone - For recording touchpoint notes
• Storage - For offline data storage
• Network - For API communication and sync

SECURITY:
• All data encrypted during transmission and storage
• PIN-based authentication with biometric support
• Session timeout after 15 minutes of inactivity
• RBAC system with role-based permissions
```

#### Screenshots Required
- ✅ At least 2 phone screenshots
- ✅ Resolution: 320px minimum width, 1080px minimum height
- ✅ Aspect ratio: Must not exceed 16:9
- ✅ Format: JPG or PNG, 24-bit color

#### Screenshots to Capture
1. **Login Screen** - Email/password or PIN entry
2. **Home Dashboard** - 6-icon grid with quick actions
3. **Client List** - Search and filter clients
4. **Client Detail** - Client information with touchpoint history
5. **Touchpoint Form** - Recording visit/call touchpoint
6. **Itinerary View** - Daily schedule with route map
7. **Sync Status** - Offline-first sync indicator

### Privacy Policy URL
- **Required:** Yes (app collects user location)
- **Template:** [Create privacy policy page](https://www.freeprivacypolicy.com/)
- **Hosting:** GitHub Pages, company website, or dedicated privacy policy service

### Permission Declarations
The app requires the following permissions (must be justified in Play Console):

1. **INTERNET** - Required for API communication and data sync
2. **ACCESS_NETWORK_STATE** - Required to check network connectivity
3. **ACCESS_FINE_LOCATION** - Required for GPS tracking and address verification
4. **ACCESS_COARSE_LOCATION** - Required for approximate location
5. **ACCESS_BACKGROUND_LOCATION** - Required for location tracking during touchpoints
6. **CAMERA** - Required for capturing touchpoint photos
7. **RECORD_AUDIO** - Required for recording touchpoint notes
8. **POST_NOTIFICATIONS** - Required for sync status notifications
9. **VIBRATE** - Required for haptic feedback
10. **READ_EXTERNAL_STORAGE** (if applicable) - For accessing photos

### Content Rating
- **Rating:** Everyone
- **Violence:** None
- **Sexual Content:** None
- **Profanity:** None
- **Drug Reference:** None

---

## Testing Checklist

### Pre-Release Testing

#### Functional Testing
- [ ] User can log in with email/password
- [ ] User can set up 6-digit PIN
- [ ] User can authenticate with biometrics (fingerprint/Face ID)
- [ ] User can view client list
- [ ] User can search and filter clients
- [ ] User can create touchpoints (Visit/Call)
- [ ] User can capture GPS location
- [ ] User can upload photos
- [ ] User can record audio notes
- [ ] User can view itinerary
- [ ] User can sync data when online
- [ ] User can view sync status
- [ ] User can log out
- [ ] Session expires after 15 minutes of inactivity

#### Offline Testing
- [ ] App works without internet connection
- [ ] Client data is accessible offline
- [ ] Touchpoints can be created offline
- [ ] Data syncs when connection restored
- [ ] Sync status indicator shows correct state

#### Performance Testing
- [ ] App launches in under 3 seconds
- [ ] Client list scrolls smoothly
- [ ] Touchpoint form loads quickly
- [ ] Sync completes within reasonable time
- [ ] No memory leaks detected

#### Security Testing
- [ ] PIN authentication works correctly
- [ ] Biometric authentication works correctly
- [ ] Session timeout works correctly
- [ ] Data is encrypted during transmission
- [ ] No sensitive data logged in production

#### Device Testing
- [ ] Test on Android phone (minimum requirement)
- [ ] Test on tablet (if applicable)
- [ ] Test on different Android versions (API 23+)
- [ ] Test on different screen sizes
- [ ] Test with poor network conditions
- [ ] Test with no network connection

---

## Post-Release

### Monitor App Performance
- **Crash Reports:** Check Firebase Crashlytics or Play Console
- **User Feedback:** Monitor reviews and ratings
- **Analytics:** Track user behavior and app performance

### Update Strategy
- **Version Naming:** Use semantic versioning (major.minor.patch)
- **Build Number:** Increment with each release
- **Release Notes:** Document changes in each version

### Rollback Plan
- Keep previous APK/AAB versions available
- Document rollback procedure
- Have emergency contact plan

---

## Troubleshooting

### Build Issues

**Issue: "Execution failed for task ':app:packageRelease'**
- **Cause:** Missing keystore configuration
- **Solution:** Ensure KEYSTORE_PASSWORD and KEY_PASSWORD are set

**Issue: "Gradle build failed"
- **Cause:** Android SDK or configuration issue
- **Solution:** Run `flutter doctor` and fix issues

**Issue: "Failed to sign APK"
- **Cause:** Invalid keystore or wrong passwords
- **Solution:** Verify keystore file exists and passwords are correct

### Play Store Issues

**Issue: "App rejected for insufficient screenshots"
- **Solution:** Provide at least 2 phone screenshots meeting requirements

**Issue: "App rejected for missing privacy policy"
- **Solution:** Create and host privacy policy page, add URL to listing

**Issue: "App rejected for permission justification"
- **Solution:** Provide detailed justification for each permission in Play Console

---

## Quick Reference

### Build Commands
```bash
# Debug build
flutter build apk --debug

# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release

# Release with obfuscation
flutter build apk --release --obfuscate --split-debug-info=./build/app/outputs/symbols
```

### Version Update
1. Update `version` in `pubspec.yaml` (format: 1.3.2+5)
2. Update `versionCode` and `versionName` in `build.gradle`
3. Run `flutter pub get` to update dependencies
4. Build release APK/AAB

### Environment Variables
```bash
# Windows
set KEYSTORE_PASSWORD=xxx
set KEY_PASSWORD=xxx
set KEY_ALIAS=release

# PowerShell
$env:KEYSTORE_PASSWORD='xxx'
$env:KEY_PASSWORD='xxx'
$env:KEY_ALIAS='release'

# Linux/Mac
export KEYSTORE_PASSWORD=xxx
export KEY_PASSWORD=xxx
export KEY_ALIAS=release
```

---

## Next Steps

1. ✅ Generate production keystore
2. ✅ Fix analysis issues
3. ✅ Build release APK for testing
4. ✅ Test on physical device
5. ⏳ Capture screenshots for Play Store
6. ⏳ Create privacy policy page
7. ⏳ Prepare store listing content
8. ⏳ Create Google Play Console account
9. ⏳ Upload AAB to Play Console
10. ⏳ Complete store listing
11. ⏳ Submit for review
12. ⏳ Monitor review status

---

**Status:** In Progress
**Last Updated:** 2026-04-07
**Next Action:** Generate keystore and build release APK
