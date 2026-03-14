xg!EhML376z
# IMU Flutter App

IMU (Itinerary Manager Uniformed) - Mobile app for field agents (Caravan role) to manage client visits, itineraries, and touchpoints.

## Requirements

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- Android Studio / Xcode (for platform-specific builds)

## Getting Started

1. **Install Flutter**

   Follow the official guide: https://docs.flutter.dev/get-started/install

2. **Clone and setup**
   ```bash
   cd imu_flutter
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App configuration
├── core/
│   ├── constants/           # App colors, strings, assets
│   ├── theme/               # Light/dark themes
│   ├── router/              # GoRouter configuration
│   └── utils/               # Helper utilities
├── features/
│   ├── auth/                # Login, PIN, forgot password
│   ├── home/                # Dashboard
│   ├── clients/             # Client list and details
│   ├── itinerary/           # Visit scheduling
│   ├── touchpoints/         # Touchpoint forms
│   └── settings/            # App settings
├── shared/
│   ├── widgets/             # Reusable widgets
│   └── providers/           # Global providers
└── services/
    ├── local_storage/       # Hive database
    ├── location/            # GPS services
    └── media/               # Camera, audio
```

## Features

### Authentication
- Email + Password login
- 6-digit PIN quick unlock
- Biometric authentication (optional)
- Forgot password flow

### Client Management
- Client list with search and filters
- Client detail with touchpoint history
- Add new clients
- Swipe actions (coming soon)

### Itinerary
- Daily visit schedule
- Yesterday/Today/Tomorrow tabs
- Calendar picker
- Visit cards with details

### Touchpoints
- 7-touchpoint sequence (Visit-Call-Call-Visit-Call-Call-Visit)
- Visit/Call tracking
- Reason codes (25+ options)
- Time and odometer logging

## Tech Stack

| Layer | Technology |
|-------|------------|
| State Management | Riverpod 2.0 |
| Navigation | go_router |
| Local Database | Hive |
| Maps | Mapbox (display) + Google Maps (navigation) |
| HTTP Client | Dio |
| Crash Reporting | Firebase Crashlytics |
| Push Notifications | Firebase Cloud Messaging |

## Configuration

### Environment Variables

Create a `.env` file in the project root:

```
MAPBOX_ACCESS_TOKEN=your_mapbox_token
API_BASE_URL=your_api_url
```

### Firebase Setup

1. Create a Firebase project
2. Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Enable Crashlytics and Cloud Messaging

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

## Related Files

- [Master Plan](../master_plan_mobile_tablet.md) - Full project planning document
- [Elephant Carpaccio](../elephant-carpaccio-version-2.md) - Slicing methodology

## License

Proprietary - ODVI Apps
