# IMU Build Scripts

This directory contains build scripts for different environments.

## Available Scripts

### Android Scripts

| Script | Environment | Platform | Description |
|--------|-------------|----------|-------------|
| `build-qa-android.sh` | QA | Linux/macOS | Build QA APK for Android |
| `build-qa-android.bat` | QA | Windows | Build QA APK for Android |

### iOS Scripts

| Script | Environment | Platform | Description |
|--------|-------------|----------|-------------|
| `build-qa-ios.sh` | QA | macOS | Build QA IPA for iOS (requires Xcode) |

## Usage

### Building for QA

**Linux/macOS:**
```bash
# Android
./scripts/build-qa-android.sh

# iOS (requires macOS + Xcode)
./scripts/build-qa-ios.sh
```

**Windows:**
```batch
# Android
scripts\build-qa-android.bat
```

### Building for Production

**Linux/macOS/Windows:**
```bash
# Android
flutter build apk --release

# iOS (macOS only)
flutter build ipa --release
```

## Environment Variables

The app uses the `--dart-define=ENV=<environment>` flag to select the environment:

- `ENV=dev` - Development (default)
- `ENV=qa` - Quality Assurance
- `ENV=prod` - Production

When not specified, the app defaults to `dev`.

## Output Locations

### Android
- **APK:** `build/app/outputs/flutter-apk-<ENV>-release.apk`
- **App Bundle:** `build/app/outputs/bundle/<ENV>/release/app-aab`

### iOS
- **IPA:** `build/ios/archive/Runner.xcarchive`
- **App:** `build/ios/ipa/<ENV>-Runner.ipa`

## Manual Build Commands

### Android

```bash
# Development build (debug)
flutter build apk --debug

# QA build (release)
flutter build apk --release --dart-define=ENV=qa

# Production build (release)
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release
```

### iOS

```bash
# Development build
flutter build ios --debug

# QA build
flutter build ipa --release --dart-define=ENV=qa

# Production build
flutter build ipa --release
```

## Testing

After building, you can install the app on a device:

### Android

```bash
# Install APK
adb install build/app/outputs/flutter-apk-QA-release.apk

# Install App Bundle
bundle install build/app/outputs/bundle/qa/release/app-aab

# View logs
adb logcat
```

### iOS

Use Xcode or Apple Configurator to install the IPA file.

## Troubleshooting

### Build fails

1. Ensure you're in the project root directory
2. Run `flutter clean` and try again
3. Check Flutter version: `flutter --version`
4. Run `flutter doctor` to check for issues

### APK won't install

1. Enable USB debugging on device
2. Check device connection: `flutter devices`
3. Uninstall old version first: `adb uninstall com.example.imu`

### Environment not detected

1. Check `main.dart` has the environment detection code
2. Verify `.env.<env>` file exists
3. Check build logs for environment loading errors

## Automation

These scripts can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Build QA APK
  run: |
    cd mobile/imu_flutter
    flutter build apk --release --dart-define=ENV=qa
    mv build/app/outputs/flutter-apk-QA-release.apk build/app/outputs/qa-latest.apk

- name: Upload artifact
  uses: actions/upload-artifact@v3
  with:
    name: qa-apk
    path: mobile/imu_flutter/build/app/outputs/qa-latest.apk
```
