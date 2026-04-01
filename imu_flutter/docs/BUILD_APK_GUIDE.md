# Building IMU APK with Remote Server Connection

## Quick Start - Android Studio

When you build the APK in Android Studio, it will automatically connect to:
- **Backend API**: `https://imu-api.cfbtools.app/api`
- **PowerSync**: `https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com`

## How to Build APK in Android Studio

### Option 1: Using Android Studio UI (Recommended)

1. **Connect your Android device** via USB (with USB debugging enabled)
2. **In Android Studio**:
   - Click **Build** → **Flutter** → **Build APK**
   - Or press **Shift + F10** (Windows) / **Control + B** (Mac)
   - Select **Release** mode
3. **Wait for build to complete** (~2-5 minutes)
4. **Install on device**:
   - APK will be at: `build/app/outputs/flutter-apk-release.apk`
   - Or use: **Build** → **Flutter** → **Install to Device**

### Option 2: Using Command Line

```bash
cd mobile/imu_flutter

# Build APK (will use .env.dev configuration)
flutter build apk --release

# Install on connected device
adb install build/app/outputs/flutter-apk-release.apk
```

## Configuration Already Set Up

The `.env.dev` file is configured to connect to remote servers:
```bash
✅ POSTGRES_API_URL=https://imu-api.cfbtools.app/api
✅ POWERSYNC_URL=https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com
```

## Verification

After installing the APK on your phone:

1. **Check app connects to backend**:
   - Login should work with remote server
   - Data loading should work (clients, touchpoints, etc.)

2. **Check PowerSync syncs**:
   - Login with test account (caravan1@imu-qa.com / caravan123)
   - Navigate to clients - should load data from server
   - Create a touchpoint - should sync to PowerSync

3. **Check debug logs** (if needed):
   ```bash
   adb logcat | grep -E "IMU|PowerSync|API"
   ```

## Important Notes

⚠️ **Before building for the first time:**

1. **Update JWT Secrets** in `.env.dev`:
   ```bash
   JWT_SECRET=your-jwt-secret-key-min-32-characters
   POWERSYNC_JWT_SECRET=your-powersync-jwt-secret-here
   ```
   Get these values from your backend team.

2. **Update Mapbox Token**:
   ```bash
   MAPBOX_ACCESS_TOKEN=your_mapbox_access_token_here
   ```

3. **Clean build** (if needed):
   ```bash
   flutter clean
   flutter pub get
   ```

## Troubleshooting

### App won't connect to backend

**Check:**
1. Backend is running: `curl https://imu-api.cfbtools.app/health`
2. Phone has internet connection
3. JWT_SECRET in `.env.dev` matches backend

### PowerSync not syncing

**Check:**
1. PowerSync URL is correct
2. User has valid account in backend
3. JWT token is valid (try logging out and back in)

### APK not installing

**Try:**
1. Uninstall old version first
2. Enable "Install from unknown sources" on phone
3. Check Android version compatibility (min SDK 21+)

## Current Configuration Summary

| Setting | Value |
|---------|-------|
| **Backend API** | https://imu-api.cfbtools.app/api |
| **PowerSync** | https://69cb46b4f69619e9d4830ea1.powersync.journeyapps.com |
| **Environment** | Development (uses remote servers) |
| **Build Mode** | Release (for APK) |

---

**Last Updated:** 2026-04-02
