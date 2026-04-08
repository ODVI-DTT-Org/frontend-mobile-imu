# IMU Flutter App - Quick Deployment Guide

## Quick Start for Google Play Store Deployment

### Step 1: Generate Production Keystore (One-time setup)

```bash
# Run the keystore generation script
bash generate-keystore.sh

# Or generate manually
keytool -genkey -v -keystore release.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

**IMPORTANT:**
- Keep the keystore file secure (password manager, encrypted drive)
- NEVER commit the keystore file to git
- Backup the keystore in multiple secure locations

### Step 2: Set Environment Variables

```bash
# Windows (Command Prompt)
set KEYSTORE_PASSWORD=your_store_password
set KEY_PASSWORD=your_key_password
set KEY_ALIAS=release

# Windows (PowerShell)
$env:KEYSTORE_PASSWORD='your_store_password'
$env:KEY_PASSWORD='your_key_password'
$env:KEY_ALIAS='release'

# Linux/Mac
export KEYSTORE_PASSWORD=your_store_password
export KEY_PASSWORD=your_key_password
export KEY_ALIAS=release
```

### Step 3: Build Release App Bundle (AAB)

```bash
# Build App Bundle for Google Play Store
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### Step 4: Test Release Build

```bash
# Install on connected device for testing
flutter install --release build/app/outputs/flutter-apk/app-release.apk
```

### Step 5: Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app or select existing app
3. Upload AAB file: `build/app/outputs/bundle/release/app-release.aab`
4. Complete store listing information
5. Submit for review

---

## Build Commands Reference

```bash
# Debug build (development)
flutter build apk --debug

# Release APK (for testing)
flutter build apk --release

# Release App Bundle (for Play Store) - REQUIRED
flutter build appbundle --release

# Release with obfuscation (production)
flutter build apk --release --obfuscate --split-debug-info=./build/app/outputs/symbols
```

---

## File Locations

### Build Outputs
- **Debug APK:** `build/app/outputs/flutter-apk/app-debug.apk`
- **Release APK:** `build/app/outputs/flutter-apk/app-release.apk`
- **Release AAB:** `build/app/outputs/bundle/release/app-release.aab`

### Configuration Files
- **App signing:** `android/app/build.gradle`
- **ProGuard rules:** `android/app/proguard-rules.pro`
- **App version:** `pubspec.yaml` (line 4)

---

## Version Update Process

1. Update version in `pubspec.yaml` (line 4): `version: 1.3.3+6`
2. Update `android/app/build.gradle` (if needed)
3. Run `flutter pub get`
4. Build release AAB
5. Upload to Play Console

---

## Troubleshooting

### Build Issues

**"Execution failed for task ':app:packageRelease'"**
- Ensure KEYSTORE_PASSWORD and KEY_PASSWORD are set
- Verify release.keystore file exists in project root

**"Gradle build failed"**
- Run `flutter doctor` to check environment
- Ensure Android SDK 36 is installed
- Accept Android licenses: `flutter doctor --android-licenses`

**"Failed to sign APK"**
- Verify keystore passwords are correct
- Check that KEY_ALIAS matches keystore alias

### Play Store Issues

**"App rejected for insufficient screenshots"**
- Provide at least 2 phone screenshots
- Minimum resolution: 320px x 1080px
- Maximum aspect ratio: 16:9

**"App rejected for missing privacy policy"**
- Create privacy policy page
- Add privacy policy URL to store listing

**"App rejected for permission justification"**
- Provide detailed justification for each permission
- Explain why each permission is required

---

## Security Checklist

- [ ] Keystore file stored securely
- [ ] Keystore backed up in multiple locations
- [ ] Keystore passwords stored in password manager
- [ ] Keystore file NOT in git repository
- [ ] Environment variables NOT committed
- [ ] Production build tested on physical device
- [ ] No debug code in production build
- [ ] ProGuard/R8 obfuscation enabled
- [ ] Logging removed from production builds

---

## Current Status

**Version:** 1.3.2+5
**Build Status:** ✅ Ready for testing
**Code Quality:** ✅ Analysis issues fixed
**Signing:** ✅ Configuration updated
**Documentation:** ✅ Complete

**Next Steps:**
1. Generate production keystore
2. Build release AAB
3. Test on physical device
4. Prepare Play Store assets
5. Upload to Play Console

---

**Documentation:**
- Full guide: `GOOGLE_PLAY_DEPLOYMENT_GUIDE.md`
- Flutter docs: https://docs.flutter.dev/deployment/android
- Play Console: https://play.google.com/console

---

**Last Updated:** 2026-04-07
**Status:** Ready for deployment testing
