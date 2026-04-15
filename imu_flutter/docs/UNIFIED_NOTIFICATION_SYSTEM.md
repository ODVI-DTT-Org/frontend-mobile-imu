# Unified Notification System

## Overview

A new unified notification system has been implemented for the IMU mobile app. All notifications now appear at the **TOP** of the screen with consistent styling and color coding.

## Color Scheme

| Type | Color | Usage |
|------|-------|-------|
| **Success** | Green | Successful operations, completed actions |
| **Error** | Red | Failed operations, errors, validation issues |
| **Warning** | Orange | Warnings, confirmations needed |
| **Neutral** | Gray | Info messages, status updates |

## Usage

### Basic Notifications

```dart
import 'package:imu_flutter/core/utils/app_notification.dart';

// Success notification
AppNotification.showSuccess(context, 'Operation completed successfully!');

// Error notification
AppNotification.showError(context, 'Failed to complete operation.');

// Warning notification
AppNotification.showWarning(context, 'Please review before continuing.');

// Neutral notification
AppNotification.showNeutral(context, 'Syncing data...');
```

### Notifications with Actions

```dart
// Success with action
AppNotification.showSuccessWithAction(
  context,
  message: 'Changes saved successfully!',
  actionLabel: 'View',
  onAction: () {
    // Handle view action
  },
);

// Error with retry action
AppNotification.showErrorWithAction(
  context,
  message: 'Connection failed.',
  actionLabel: 'Retry',
  onAction: () {
    // Handle retry action
  },
);

// Warning with save action
AppNotification.showWarningWithAction(
  context,
  message: 'Unsaved changes detected.',
  actionLabel: 'Save',
  onAction: () {
    // Handle save action
  },
);

// Neutral with undo action
AppNotification.showNeutralWithAction(
  context,
  message: 'Item deleted.',
  actionLabel: 'Undo',
  onAction: () {
    // Handle undo action
  },
);
```

### Custom Duration

```dart
// Show notification for custom duration
AppNotification.showSuccess(
  context,
  'This will dismiss in 5 seconds',
  duration: const Duration(seconds: 5),
);
```

### Manual Dismiss

```dart
// Dismiss current notification
AppNotification.dismiss();
```

## Migration Guide

### Old Code (InAppNotification)

```dart
// Old way (still works but deprecated)
InAppNotification.showSuccess(context, 'Success!');
InAppNotification.showError(context, 'Error!');
InAppNotification.showWarning(context, 'Warning!');
InAppNotification.showInfo(context, 'Info!');
```

### New Code (AppNotification)

```dart
// New way (recommended)
AppNotification.showSuccess(context, 'Success!');
AppNotification.showError(context, 'Error!');
AppNotification.showWarning(context, 'Warning!');
AppNotification.showNeutral(context, 'Info!');
```

## Backward Compatibility

The old `InAppNotification` and `SyncNotification` classes are still available but marked as deprecated. They now internally use the new `AppNotification` system, so existing code will continue to work but will show deprecation warnings.

## Features

- **Top Positioning**: All notifications appear at the top of the screen
- **Safe Area Padding**: Respects device safe areas (notch, status bar)
- **Auto-dismiss**: Notifications automatically dismiss after a set duration
- **Manual Dismiss**: Users can tap the X button to dismiss
- **Action Buttons**: Support for action buttons (Retry, Undo, etc.)
- **Single Instance**: Only one notification visible at a time
- **Overlay System**: Uses Flutter's overlay system for proper positioning

## Demo Page

A demo page is available at `lib/features/debug/notification_demo_page.dart` to showcase all notification types and features.

To use the demo page:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NotificationDemoPage(),
  ),
);
```

## Files Changed

1. **New Files:**
   - `lib/core/utils/app_notification.dart` - Main notification system
   - `lib/features/debug/notification_demo_page.dart` - Demo page
   - `test/widget/app_notification_test.dart` - Widget tests

2. **Modified Files:**
   - `lib/core/utils/notification_utils.dart` - Updated to use new system
   - `lib/shared/widgets/background_sync_indicator.dart` - Updated SyncNotification

## Testing

Run the notification tests:

```bash
flutter test test/widget/app_notification_test.dart
```

All tests should pass:
- ✅ 7/7 tests passing

## Example: Replacing Old Notifications

### Before (ScaffoldMessenger)

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Client created successfully'),
    backgroundColor: Colors.green,
    behavior: SnackBarBehavior.floating,
  ),
);
```

### After (AppNotification)

```dart
AppNotification.showSuccess(context, 'Client created successfully!');
```

## Example: Error Handling

### Before

```dart
try {
  await apiClient.createClient(data);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Success'), backgroundColor: Colors.green),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
  );
}
```

### After

```dart
try {
  await apiClient.createClient(data);
  AppNotification.showSuccess(context, 'Client created successfully!');
} catch (e) {
  AppNotification.showError(context, 'Failed to create client: $e');
}
```

## Future Enhancements

- Queue system for multiple notifications
- Custom icons and animations
- Notification sound effects
- Haptic feedback integration
- Persistent notifications
- Progress indicators in notifications
