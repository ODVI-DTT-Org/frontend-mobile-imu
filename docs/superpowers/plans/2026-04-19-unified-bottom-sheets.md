# Unified Recording Bottom Sheets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the three recording bottom sheets (Touchpoint, Visit, Loan Release) with a unified Grab-style design, hybrid validation, required GPS, and a shared base widget architecture.

**Architecture:** A new `UnifiedActionBottomSheet` base widget owns the header, card layout, keyboard handling, and submit button. Six shared card widgets handle individual form sections. Three thin `HookConsumerWidget` sheets wire up state and call the base.

**Tech Stack:** Flutter, flutter_hooks, hooks_riverpod, geolocator ^10.1.0, geocoding ^2.1.1, image_picker ^1.0.7, permission_handler ^11.0.1, lucide_icons

---

## File Map

**Create:**
- `lib/features/record_forms/presentation/widgets/shared/location_card.dart`
- `lib/features/record_forms/presentation/widgets/shared/schedule_card.dart`
- `lib/features/record_forms/presentation/widgets/shared/details_card.dart`
- `lib/features/record_forms/presentation/widgets/shared/notes_card.dart`
- `lib/features/record_forms/presentation/widgets/shared/photo_card.dart`
- `lib/features/record_forms/presentation/widgets/shared/loan_details_card.dart`
- `lib/features/record_forms/presentation/widgets/unified_action_bottom_sheet.dart`
- `lib/features/record_forms/presentation/widgets/record_touchpoint_bottom_sheet.dart` (replaces clients/ version)
- `lib/features/record_forms/presentation/widgets/record_visit_bottom_sheet.dart` (replaces record_visit_only)
- `lib/features/record_forms/presentation/widgets/record_loan_release_bottom_sheet.dart` (replaces clients/ version)
- `test/features/record_forms/presentation/widgets/shared/location_card_test.dart`
- `test/features/record_forms/presentation/widgets/shared/schedule_card_test.dart`
- `test/features/record_forms/presentation/widgets/shared/details_card_test.dart`
- `test/features/record_forms/presentation/widgets/shared/notes_card_test.dart`
- `test/features/record_forms/presentation/widgets/shared/photo_card_test.dart`
- `test/features/record_forms/presentation/widgets/shared/loan_details_card_test.dart`
- `test/features/record_forms/presentation/widgets/unified_action_bottom_sheet_test.dart`

**Modify:**
- `lib/features/record_forms/data/models/visit_form_data.dart` — remove auto-set enforcement, make reason/status user-editable
- `lib/features/clients/presentation/pages/client_detail_page.dart` — update 3 call sites
- `lib/features/itinerary/presentation/pages/itinerary_page.dart` — update 2 call sites
- `lib/features/my_day/presentation/pages/my_day_page.dart` — update 2 call sites

**Delete (after call sites updated):**
- `lib/features/clients/presentation/widgets/client_action_bottom_sheet.dart`
- `lib/features/clients/presentation/widgets/record_touchpoint_bottom_sheet.dart`
- `lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart`
- `lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart`

---

## Task 1: LocationCard widget

**Files:**
- Create: `lib/features/record_forms/presentation/widgets/shared/location_card.dart`
- Test: `test/features/record_forms/presentation/widgets/shared/location_card_test.dart`

- [ ] **Step 1: Create the test file**

```dart
// test/features/record_forms/presentation/widgets/shared/location_card_test.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('LocationCard', () {
    testWidgets('shows acquiring state initially', (tester) async {
      final completer = Completer<LocationData?>();
      await tester.pumpWidget(_wrap(
        LocationCard(
          locationFetcher: () => completer.future,
          onAcquired: (_) {},
          onFailed: () {},
          showError: false,
        ),
      ));
      expect(find.text('Acquiring location...'), findsOneWidget);
    });

    testWidgets('shows acquired state with coordinates', (tester) async {
      await tester.pumpWidget(_wrap(
        LocationCard(
          locationFetcher: () async => const LocationData(
            lat: 14.5995,
            lng: 120.9842,
            address: 'Brgy. Poblacion, Manila',
          ),
          onAcquired: (_) {},
          onFailed: () {},
          showError: false,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('14.5995'), findsOneWidget);
      expect(find.text('Brgy. Poblacion, Manila'), findsOneWidget);
    });

    testWidgets('shows failed state when fetcher returns null', (tester) async {
      await tester.pumpWidget(_wrap(
        LocationCard(
          locationFetcher: () async => null,
          onAcquired: (_) {},
          onFailed: () {},
          showError: false,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('GPS Unavailable'), findsOneWidget);
      expect(find.text('Enable Location Settings'), findsOneWidget);
    });

    testWidgets('calls onAcquired callback with data', (tester) async {
      LocationData? received;
      const data = LocationData(lat: 1.0, lng: 2.0, address: 'Test');
      await tester.pumpWidget(_wrap(
        LocationCard(
          locationFetcher: () async => data,
          onAcquired: (d) => received = d,
          onFailed: () {},
          showError: false,
        ),
      ));
      await tester.pumpAndSettle();
      expect(received, equals(data));
    });

    testWidgets('calls onFailed when fetcher returns null', (tester) async {
      var failed = false;
      await tester.pumpWidget(_wrap(
        LocationCard(
          locationFetcher: () async => null,
          onAcquired: (_) {},
          onFailed: () => failed = true,
          showError: false,
        ),
      ));
      await tester.pumpAndSettle();
      expect(failed, isTrue);
    });

    testWidgets('shows red background when showError is true and GPS failed', (tester) async {
      await tester.pumpWidget(_wrap(
        LocationCard(
          locationFetcher: () async => null,
          onAcquired: (_) {},
          onFailed: () {},
          showError: true,
        ),
      ));
      await tester.pumpAndSettle();
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('GPS Unavailable'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(const Color(0xFFFEE2E2)));
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd imu_flutter
flutter test test/features/record_forms/presentation/widgets/shared/location_card_test.dart
```
Expected: FAIL — `location_card.dart` does not exist yet.

- [ ] **Step 3: Create the LocationCard widget**

```dart
// lib/features/record_forms/presentation/widgets/shared/location_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationData {
  final double lat;
  final double lng;
  final String address;

  const LocationData({
    required this.lat,
    required this.lng,
    required this.address,
  });

  @override
  bool operator ==(Object other) =>
      other is LocationData && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

typedef LocationFetcher = Future<LocationData?> Function();

enum _GpsStatus { acquiring, acquired, failed }

Future<LocationData?> _defaultFetch() async {
  try {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    final place = placemarks.isNotEmpty ? placemarks.first : null;
    final address = place != null
        ? '${place.subLocality ?? ''}, ${place.locality ?? ''}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), '')
        : '${position.latitude.toStringAsFixed(4)}°N, ${position.longitude.toStringAsFixed(4)}°E';
    return LocationData(
      lat: position.latitude,
      lng: position.longitude,
      address: address,
    );
  } catch (_) {
    return null;
  }
}

class LocationCard extends HookWidget {
  final void Function(LocationData) onAcquired;
  final VoidCallback onFailed;
  final bool showError;
  final LocationFetcher? locationFetcher;

  const LocationCard({
    super.key,
    required this.onAcquired,
    required this.onFailed,
    this.showError = false,
    this.locationFetcher,
  });

  @override
  Widget build(BuildContext context) {
    final status = useState(_GpsStatus.acquiring);
    final location = useState<LocationData?>(null);

    useEffect(() {
      final fetch = locationFetcher ?? _defaultFetch;
      fetch().then((data) {
        if (data != null) {
          location.value = data;
          status.value = _GpsStatus.acquired;
          onAcquired(data);
        } else {
          status.value = _GpsStatus.failed;
          onFailed();
        }
      });
      return null;
    }, const []);

    return _SectionCard(
      title: 'LOCATION',
      child: _buildContent(status.value, location.value),
    );
  }

  Widget _buildContent(_GpsStatus gpsStatus, LocationData? data) {
    switch (gpsStatus) {
      case _GpsStatus.acquiring:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Acquiring location...', style: TextStyle(color: Color(0xFF64748B))),
          ]),
        );
      case _GpsStatus.acquired:
        final loc = data!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 18, color: Color(0xFF22C55E)),
              const SizedBox(width: 8),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${loc.lat.toStringAsFixed(4)}°N, ${loc.lng.toStringAsFixed(4)}°E',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                  ),
                  Text(loc.address, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              )),
            ],
          ),
        );
      case _GpsStatus.failed:
        return Container(
          decoration: BoxDecoration(
            color: showError ? const Color(0xFFFEE2E2) : const Color(0xFFFFF7F7),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.location_off, size: 18, color: Color(0xFFEF4444)),
                SizedBox(width: 8),
                Text('GPS Unavailable', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              const Text('Location access is required', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: openAppSettings,
                child: const Text(
                  'Enable Location Settings',
                  style: TextStyle(fontSize: 13, color: Color(0xFF3B82F6), fontWeight: FontWeight.w500, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// Shared section card wrapper used by all card widgets
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
```

> Note: Export `_SectionCard` as `SectionCard` (remove underscore) so other card widgets can import it. Update the class name to `SectionCard` in the file.

- [ ] **Step 4: Make `SectionCard` importable — rename `_SectionCard` to `SectionCard` in the file above**

- [ ] **Step 5: Run tests**

```bash
flutter test test/features/record_forms/presentation/widgets/shared/location_card_test.dart
```
Expected: All 6 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/record_forms/presentation/widgets/shared/location_card.dart \
        test/features/record_forms/presentation/widgets/shared/location_card_test.dart
git commit -m "feat: add LocationCard widget with GPS auto-capture and 3 states"
```

---

## Task 2: ScheduleCard widget

**Files:**
- Create: `lib/features/record_forms/presentation/widgets/shared/schedule_card.dart`
- Test: `test/features/record_forms/presentation/widgets/shared/schedule_card_test.dart`

- [ ] **Step 1: Create the test file**

```dart
// test/features/record_forms/presentation/widgets/shared/schedule_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/schedule_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('ScheduleCard', () {
    testWidgets('shows placeholder text when no values set', (tester) async {
      await tester.pumpWidget(_wrap(ScheduleCard(
        timeIn: null, timeOut: null,
        odometerArrival: null, odometerDeparture: null,
        onTimeInChanged: (_) {}, onTimeOutChanged: (_) {},
        onOdometerArrivalChanged: (_) {}, onOdometerDepartureChanged: (_) {},
        showErrors: false,
      )));
      expect(find.text('Time In'), findsOneWidget);
      expect(find.text('Time Out'), findsOneWidget);
      expect(find.text('Odo Arrival'), findsOneWidget);
      expect(find.text('Odo Departure'), findsOneWidget);
    });

    testWidgets('shows red border color on time fields when showErrors true and null', (tester) async {
      await tester.pumpWidget(_wrap(ScheduleCard(
        timeIn: null, timeOut: null,
        odometerArrival: null, odometerDeparture: null,
        onTimeInChanged: (_) {}, onTimeOutChanged: (_) {},
        onOdometerArrivalChanged: (_) {}, onOdometerDepartureChanged: (_) {},
        showErrors: true,
      )));
      expect(find.text('Required'), findsNWidgets(4));
    });

    testWidgets('shows formatted time when value set', (tester) async {
      await tester.pumpWidget(_wrap(ScheduleCard(
        timeIn: const TimeOfDay(hour: 8, minute: 30),
        timeOut: null,
        odometerArrival: null, odometerDeparture: null,
        onTimeInChanged: (_) {}, onTimeOutChanged: (_) {},
        onOdometerArrivalChanged: (_) {}, onOdometerDepartureChanged: (_) {},
        showErrors: false,
      )));
      expect(find.text('8:30 AM'), findsOneWidget);
    });

    testWidgets('shows odometer value when set', (tester) async {
      await tester.pumpWidget(_wrap(ScheduleCard(
        timeIn: null, timeOut: null,
        odometerArrival: '12345', odometerDeparture: null,
        onTimeInChanged: (_) {}, onTimeOutChanged: (_) {},
        onOdometerArrivalChanged: (_) {}, onOdometerDepartureChanged: (_) {},
        showErrors: false,
      )));
      expect(find.text('12345 km'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/features/record_forms/presentation/widgets/shared/schedule_card_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create ScheduleCard**

```dart
// lib/features/record_forms/presentation/widgets/shared/schedule_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart' show SectionCard;

class ScheduleCard extends StatelessWidget {
  final TimeOfDay? timeIn;
  final TimeOfDay? timeOut;
  final String? odometerArrival;
  final String? odometerDeparture;
  final void Function(TimeOfDay) onTimeInChanged;
  final void Function(TimeOfDay) onTimeOutChanged;
  final void Function(String) onOdometerArrivalChanged;
  final void Function(String) onOdometerDepartureChanged;
  final bool showErrors;

  const ScheduleCard({
    super.key,
    required this.timeIn,
    required this.timeOut,
    required this.odometerArrival,
    required this.odometerDeparture,
    required this.onTimeInChanged,
    required this.onTimeOutChanged,
    required this.onOdometerArrivalChanged,
    required this.onOdometerDepartureChanged,
    required this.showErrors,
  });

  String _formatTime(TimeOfDay t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'SCHEDULE',
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _TimeField(
              label: 'Time In',
              value: timeIn,
              showError: showErrors && timeIn == null,
              onChanged: onTimeInChanged,
              formatTime: _formatTime,
            )),
            const SizedBox(width: 10),
            Expanded(child: _TimeField(
              label: 'Time Out',
              value: timeOut,
              showError: showErrors && timeOut == null,
              onChanged: onTimeOutChanged,
              formatTime: _formatTime,
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _OdometerField(
              label: 'Odo Arrival',
              value: odometerArrival,
              showError: showErrors && (odometerArrival == null || odometerArrival!.isEmpty),
              onChanged: onOdometerArrivalChanged,
            )),
            const SizedBox(width: 10),
            Expanded(child: _OdometerField(
              label: 'Odo Departure',
              value: odometerDeparture,
              showError: showErrors && (odometerDeparture == null || odometerDeparture!.isEmpty),
              onChanged: onOdometerDepartureChanged,
            )),
          ]),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final bool showError;
  final void Function(TimeOfDay) onChanged;
  final String Function(TimeOfDay) formatTime;

  const _TimeField({
    required this.label, required this.value, required this.showError,
    required this.onChanged, required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: value ?? TimeOfDay.now(),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: showError ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB), width: showError ? 2 : 1),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF9FAFB),
            ),
            child: Row(children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                value != null ? formatTime(value!) : (showError ? 'Required' : '--:--'),
                style: TextStyle(
                  fontSize: 14,
                  color: showError && value == null ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _OdometerField extends StatelessWidget {
  final String label;
  final String? value;
  final bool showError;
  final void Function(String) onChanged;

  const _OdometerField({
    required this.label, required this.value, required this.showError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            controller: TextEditingController(text: value ?? ''),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              suffixText: value != null && value!.isNotEmpty ? 'km' : null,
              hintText: showError ? 'Required' : '0',
              hintStyle: TextStyle(color: showError ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: showError ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB), width: showError ? 2 : 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: showError ? const Color(0xFFEF4444) : const Color(0xFF0F172A), width: 1.5),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/record_forms/presentation/widgets/shared/schedule_card_test.dart
```
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/record_forms/presentation/widgets/shared/schedule_card.dart \
        test/features/record_forms/presentation/widgets/shared/schedule_card_test.dart
git commit -m "feat: add ScheduleCard with time/odometer fields and validation"
```

---

## Task 3: DetailsCard widget

**Files:**
- Create: `lib/features/record_forms/presentation/widgets/shared/details_card.dart`
- Test: `test/features/record_forms/presentation/widgets/shared/details_card_test.dart`

- [ ] **Step 1: Create the test file**

```dart
// test/features/record_forms/presentation/widgets/shared/details_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/details_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('DetailsCard (editable)', () {
    testWidgets('renders reason and status dropdowns', (tester) async {
      await tester.pumpWidget(_wrap(DetailsCard(
        locked: false,
        reason: null, status: null,
        availableReasons: TouchpointReason.values.where((r) => r != TouchpointReason.newReleaseLoan).toList(),
        availableStatuses: [TouchpointStatus.interested, TouchpointStatus.undecided, TouchpointStatus.notInterested, TouchpointStatus.completed],
        onReasonChanged: (_) {}, onStatusChanged: (_) {},
        showErrors: false,
      )));
      expect(find.text('Reason'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('shows Required hint when showErrors true and fields null', (tester) async {
      await tester.pumpWidget(_wrap(DetailsCard(
        locked: false,
        reason: null, status: null,
        availableReasons: TouchpointReason.values.where((r) => r != TouchpointReason.newReleaseLoan).toList(),
        availableStatuses: [TouchpointStatus.interested, TouchpointStatus.undecided],
        onReasonChanged: (_) {}, onStatusChanged: (_) {},
        showErrors: true,
      )));
      expect(find.text('Select reason'), findsOneWidget);
      expect(find.text('Select status'), findsOneWidget);
    });
  });

  group('DetailsCard (locked)', () {
    testWidgets('shows lock icon and no dropdown arrow', (tester) async {
      await tester.pumpWidget(_wrap(DetailsCard(
        locked: true,
        reason: null, status: null,
        availableReasons: [], availableStatuses: [],
        onReasonChanged: null, onStatusChanged: null,
        showErrors: false,
        lockedReasonLabel: 'New Loan Release',
        lockedStatusLabel: 'Completed',
      )));
      expect(find.text('New Loan Release'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/features/record_forms/presentation/widgets/shared/details_card_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create DetailsCard**

```dart
// lib/features/record_forms/presentation/widgets/shared/details_card.dart
import 'package:flutter/material.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart' show SectionCard;

class DetailsCard extends StatelessWidget {
  final bool locked;
  final TouchpointReason? reason;
  final TouchpointStatus? status;
  final List<TouchpointReason> availableReasons;
  final List<TouchpointStatus> availableStatuses;
  final void Function(TouchpointReason)? onReasonChanged;
  final void Function(TouchpointStatus)? onStatusChanged;
  final bool showErrors;
  final String? lockedReasonLabel;
  final String? lockedStatusLabel;

  const DetailsCard({
    super.key,
    required this.locked,
    required this.reason,
    required this.status,
    required this.availableReasons,
    required this.availableStatuses,
    required this.onReasonChanged,
    required this.onStatusChanged,
    required this.showErrors,
    this.lockedReasonLabel,
    this.lockedStatusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'DETAILS',
      child: Column(
        children: [
          _DropdownRow(
            label: 'Reason',
            locked: locked,
            lockedLabel: lockedReasonLabel,
            showError: showErrors && !locked && reason == null,
            child: locked
                ? null
                : DropdownButtonHideUnderline(
                    child: DropdownButton<TouchpointReason>(
                      value: reason,
                      isExpanded: true,
                      hint: const Text('Select reason', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                      items: availableReasons.map((r) => DropdownMenuItem(value: r, child: Text(r.displayName))).toList(),
                      onChanged: (v) { if (v != null) onReasonChanged?.call(v); },
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          _DropdownRow(
            label: 'Status',
            locked: locked,
            lockedLabel: lockedStatusLabel,
            showError: showErrors && !locked && status == null,
            child: locked
                ? null
                : DropdownButtonHideUnderline(
                    child: DropdownButton<TouchpointStatus>(
                      value: status,
                      isExpanded: true,
                      hint: const Text('Select status', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                      items: availableStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
                      onChanged: (v) { if (v != null) onStatusChanged?.call(v); },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final bool locked;
  final String? lockedLabel;
  final bool showError;
  final Widget? child;

  const _DropdownRow({
    required this.label, required this.locked, required this.showError,
    this.lockedLabel, this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: showError ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
              width: showError ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: locked ? const Color(0xFFF9FAFB) : Colors.white,
          ),
          child: locked
              ? Row(children: [
                  Expanded(child: Text(lockedLabel ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)))),
                  const Icon(Icons.lock_outline, size: 16, color: Color(0xFF9CA3AF)),
                ])
              : child!,
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${label.toLowerCase()} is required',
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/record_forms/presentation/widgets/shared/details_card_test.dart
```
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/record_forms/presentation/widgets/shared/details_card.dart \
        test/features/record_forms/presentation/widgets/shared/details_card_test.dart
git commit -m "feat: add DetailsCard with editable dropdowns and locked variant"
```

---

## Task 4: NotesCard widget

**Files:**
- Create: `lib/features/record_forms/presentation/widgets/shared/notes_card.dart`
- Test: `test/features/record_forms/presentation/widgets/shared/notes_card_test.dart`

- [ ] **Step 1: Create the test file**

```dart
// test/features/record_forms/presentation/widgets/shared/notes_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/notes_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('NotesCard', () {
    testWidgets('renders Remarks label and multiline field', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(_wrap(NotesCard(controller: ctrl, showError: false)));
      expect(find.text('Remarks'), findsOneWidget);
    });

    testWidgets('shows red border and error text when showError true and empty', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(_wrap(NotesCard(controller: ctrl, showError: true)));
      expect(find.text('Remarks is required'), findsOneWidget);
    });

    testWidgets('no error shown when controller has text even with showError', (tester) async {
      final ctrl = TextEditingController(text: 'Some notes');
      await tester.pumpWidget(_wrap(NotesCard(controller: ctrl, showError: true)));
      expect(find.text('Remarks is required'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/features/record_forms/presentation/widgets/shared/notes_card_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create NotesCard**

```dart
// lib/features/record_forms/presentation/widgets/shared/notes_card.dart
import 'package:flutter/material.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart' show SectionCard;

class NotesCard extends StatelessWidget {
  final TextEditingController controller;
  final bool showError;

  const NotesCard({super.key, required this.controller, required this.showError});

  bool get _isEmpty => controller.text.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final hasError = showError && _isEmpty;
    return SectionCard(
      title: 'NOTES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Remarks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: 4,
            maxLength: 255,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12),
              hintText: 'Enter remarks...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: hasError ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB), width: hasError ? 2 : 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: hasError ? const Color(0xFFEF4444) : const Color(0xFF0F172A), width: 1.5),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
          ),
          if (hasError)
            const Text('Remarks is required', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/record_forms/presentation/widgets/shared/notes_card_test.dart
```
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/record_forms/presentation/widgets/shared/notes_card.dart \
        test/features/record_forms/presentation/widgets/shared/notes_card_test.dart
git commit -m "feat: add NotesCard with required remarks field and error state"
```

---

## Task 5: PhotoCard widget

**Files:**
- Create: `lib/features/record_forms/presentation/widgets/shared/photo_card.dart`
- Test: `test/features/record_forms/presentation/widgets/shared/photo_card_test.dart`

- [ ] **Step 1: Create the test file**

```dart
// test/features/record_forms/presentation/widgets/shared/photo_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/photo_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('PhotoCard', () {
    testWidgets('shows Take Photo button when no photo', (tester) async {
      await tester.pumpWidget(_wrap(PhotoCard(
        photoPath: null,
        onPhotoTaken: (_) {},
        showError: false,
      )));
      expect(find.text('Take Photo'), findsOneWidget);
    });

    testWidgets('shows Photo Captured and retake text when photo set', (tester) async {
      await tester.pumpWidget(_wrap(PhotoCard(
        photoPath: '/fake/path/photo.jpg',
        onPhotoTaken: (_) {},
        showError: false,
      )));
      expect(find.text('Photo Captured'), findsOneWidget);
      expect(find.text('Tap to retake'), findsOneWidget);
    });

    testWidgets('shows red border and error text when showError and no photo', (tester) async {
      await tester.pumpWidget(_wrap(PhotoCard(
        photoPath: null,
        onPhotoTaken: (_) {},
        showError: true,
      )));
      expect(find.text('Photo is required'), findsOneWidget);
    });

    testWidgets('no error shown when photo is set even with showError', (tester) async {
      await tester.pumpWidget(_wrap(PhotoCard(
        photoPath: '/path/photo.jpg',
        onPhotoTaken: (_) {},
        showError: true,
      )));
      expect(find.text('Photo is required'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/features/record_forms/presentation/widgets/shared/photo_card_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create PhotoCard**

```dart
// lib/features/record_forms/presentation/widgets/shared/photo_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart' show SectionCard;

class PhotoCard extends StatelessWidget {
  final String? photoPath;
  final void Function(String path) onPhotoTaken;
  final bool showError;

  const PhotoCard({
    super.key,
    required this.photoPath,
    required this.onPhotoTaken,
    required this.showError,
  });

  bool get _hasPhoto => photoPath != null && photoPath!.isNotEmpty;
  bool get _hasError => showError && !_hasPhoto;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) onPhotoTaken(picked.path);
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'PHOTO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hasError ? const Color(0xFFEF4444) : (_hasPhoto ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB)),
                  width: _hasError ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _hasPhoto ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
              ),
              child: _hasPhoto
                  ? Row(children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), bottomLeft: Radius.circular(7)),
                        child: Image.file(File(photoPath!), width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: const [
                            Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                            SizedBox(width: 6),
                            Text('Photo Captured', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF16A34A))),
                          ]),
                          const Text('Tap to retake', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ])
                  : Center(child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 18, color: _hasError ? const Color(0xFFEF4444) : const Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text('Take Photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _hasError ? const Color(0xFFEF4444) : const Color(0xFF64748B))),
                      ],
                    )),
            ),
          ),
          if (_hasError)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Photo is required', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/record_forms/presentation/widgets/shared/photo_card_test.dart
```
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/record_forms/presentation/widgets/shared/photo_card.dart \
        test/features/record_forms/presentation/widgets/shared/photo_card_test.dart
git commit -m "feat: add PhotoCard with camera capture and thumbnail preview"
```

---

## Task 6: LoanDetailsCard widget

**Files:**
- Create: `lib/features/record_forms/presentation/widgets/shared/loan_details_card.dart`
- Test: `test/features/record_forms/presentation/widgets/shared/loan_details_card_test.dart`

- [ ] **Step 1: Create the test file**

```dart
// test/features/record_forms/presentation/widgets/shared/loan_details_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/loan_details_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('LoanDetailsCard', () {
    testWidgets('renders Product Type, Loan Type, and UDI Number fields', (tester) async {
      await tester.pumpWidget(_wrap(LoanDetailsCard(
        productType: null, loanType: null,
        udiController: TextEditingController(),
        onProductTypeChanged: (_) {}, onLoanTypeChanged: (_) {},
        showErrors: false,
      )));
      expect(find.text('Product Type'), findsOneWidget);
      expect(find.text('Loan Type'), findsOneWidget);
      expect(find.text('UDI Number'), findsOneWidget);
    });

    testWidgets('shows error texts when showErrors true and all null/empty', (tester) async {
      await tester.pumpWidget(_wrap(LoanDetailsCard(
        productType: null, loanType: null,
        udiController: TextEditingController(),
        onProductTypeChanged: (_) {}, onLoanTypeChanged: (_) {},
        showErrors: true,
      )));
      expect(find.text('product type is required'), findsOneWidget);
      expect(find.text('loan type is required'), findsOneWidget);
      expect(find.text('UDI number is required'), findsOneWidget);
    });

    testWidgets('no errors shown when all fields filled', (tester) async {
      await tester.pumpWidget(_wrap(LoanDetailsCard(
        productType: ProductType.pnpPension,
        loanType: LoanType.newLoan,
        udiController: TextEditingController(text: '50000'),
        onProductTypeChanged: (_) {}, onLoanTypeChanged: (_) {},
        showErrors: true,
      )));
      expect(find.text('product type is required'), findsNothing);
      expect(find.text('loan type is required'), findsNothing);
      expect(find.text('UDI number is required'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/features/record_forms/presentation/widgets/shared/loan_details_card_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create LoanDetailsCard**

```dart
// lib/features/record_forms/presentation/widgets/shared/loan_details_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart' show SectionCard;

class LoanDetailsCard extends StatelessWidget {
  final ProductType? productType;
  final LoanType? loanType;
  final TextEditingController udiController;
  final void Function(ProductType) onProductTypeChanged;
  final void Function(LoanType) onLoanTypeChanged;
  final bool showErrors;

  const LoanDetailsCard({
    super.key,
    required this.productType,
    required this.loanType,
    required this.udiController,
    required this.onProductTypeChanged,
    required this.onLoanTypeChanged,
    required this.showErrors,
  });

  @override
  Widget build(BuildContext context) {
    final productError = showErrors && productType == null;
    final loanError = showErrors && loanType == null;
    final udiError = showErrors && udiController.text.trim().isEmpty;

    return SectionCard(
      title: 'LOAN DETAILS',
      child: Column(
        children: [
          _LabeledDropdown<ProductType>(
            label: 'Product Type',
            value: productType,
            showError: productError,
            hint: 'Select product type',
            items: ProductType.values.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName))).toList(),
            onChanged: (v) { if (v != null) onProductTypeChanged(v); },
          ),
          const SizedBox(height: 10),
          _LabeledDropdown<LoanType>(
            label: 'Loan Type',
            value: loanType,
            showError: loanError,
            hint: 'Select loan type',
            items: LoanType.values.map((l) => DropdownMenuItem(value: l, child: Text(l.displayName))).toList(),
            onChanged: (v) { if (v != null) onLoanTypeChanged(v); },
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('UDI Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: udiController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    hintText: udiError ? 'Required' : 'Enter UDI number',
                    hintStyle: TextStyle(color: udiError ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.tag, size: 16, color: Color(0xFF64748B)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: udiError ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB), width: udiError ? 2 : 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: udiError ? const Color(0xFFEF4444) : const Color(0xFF0F172A), width: 1.5),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
                ),
              ),
              if (udiError)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('UDI number is required', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final bool showError;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _LabeledDropdown({
    required this.label, required this.value, required this.showError,
    required this.hint, required this.items, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: showError ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB), width: showError ? 2 : 1),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(showError ? 'Required' : hint, style: TextStyle(color: showError ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF), fontSize: 14)),
              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${label.toLowerCase()} is required', style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/record_forms/presentation/widgets/shared/loan_details_card_test.dart
```
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/record_forms/presentation/widgets/shared/loan_details_card.dart \
        test/features/record_forms/presentation/widgets/shared/loan_details_card_test.dart
git commit -m "feat: add LoanDetailsCard with Product Type, Loan Type, and UDI fields"
```

---

## Task 7: UnifiedActionBottomSheet base widget

**Files:**
- Create: `lib/features/record_forms/presentation/widgets/unified_action_bottom_sheet.dart`
- Test: `test/features/record_forms/presentation/widgets/unified_action_bottom_sheet_test.dart`

- [ ] **Step 1: Create the test file**

```dart
// test/features/record_forms/presentation/widgets/unified_action_bottom_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/unified_action_bottom_sheet.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('UnifiedActionBottomSheet', () {
    testWidgets('shows title, client name, and pension label', (tester) async {
      await tester.pumpWidget(_wrap(UnifiedActionBottomSheet(
        icon: Icons.assignment,
        title: 'Record Touchpoint',
        clientName: 'Juan dela Cruz',
        pensionLabel: 'PNP Pension',
        touchpointLabel: 'Touchpoint 3 of 7',
        cards: const [],
        submitLabel: 'Record Touchpoint',
        isFormValid: false,
        isSubmitting: false,
        onSubmit: () {},
      )));
      expect(find.text('Record Touchpoint'), findsWidgets);
      expect(find.text('Juan dela Cruz'), findsOneWidget);
      expect(find.text('PNP Pension'), findsOneWidget);
      expect(find.text('Touchpoint 3 of 7'), findsOneWidget);
    });

    testWidgets('submit button is disabled when isFormValid is false', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(UnifiedActionBottomSheet(
        icon: Icons.assignment,
        title: 'Record Touchpoint',
        clientName: 'Juan dela Cruz',
        pensionLabel: 'PNP Pension',
        touchpointLabel: null,
        cards: const [],
        submitLabel: 'Submit',
        isFormValid: false,
        isSubmitting: false,
        onSubmit: () => tapped = true,
      )));
      await tester.tap(find.text('Submit'));
      expect(tapped, isFalse);
    });

    testWidgets('submit button is enabled when isFormValid is true', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(UnifiedActionBottomSheet(
        icon: Icons.assignment,
        title: 'Record Touchpoint',
        clientName: 'Juan dela Cruz',
        pensionLabel: 'PNP Pension',
        touchpointLabel: null,
        cards: const [],
        submitLabel: 'Submit',
        isFormValid: true,
        isSubmitting: false,
        onSubmit: () => tapped = true,
      )));
      await tester.tap(find.text('Submit'));
      expect(tapped, isTrue);
    });

    testWidgets('shows spinner when isSubmitting is true', (tester) async {
      await tester.pumpWidget(_wrap(UnifiedActionBottomSheet(
        icon: Icons.assignment,
        title: 'Record Touchpoint',
        clientName: 'Juan dela Cruz',
        pensionLabel: 'PNP Pension',
        touchpointLabel: null,
        cards: const [],
        submitLabel: 'Submit',
        isFormValid: true,
        isSubmitting: true,
        onSubmit: () {},
      )));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/features/record_forms/presentation/widgets/unified_action_bottom_sheet_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create UnifiedActionBottomSheet**

```dart
// lib/features/record_forms/presentation/widgets/unified_action_bottom_sheet.dart
import 'package:flutter/material.dart';

class UnifiedActionBottomSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String clientName;
  final String pensionLabel;
  final String? touchpointLabel;
  final List<Widget> cards;
  final String submitLabel;
  final bool isFormValid;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const UnifiedActionBottomSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.clientName,
    required this.pensionLabel,
    required this.touchpointLabel,
    required this.cards,
    required this.submitLabel,
    required this.isFormValid,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(icon, size: 18, color: const Color(0xFF0F172A)),
                      const SizedBox(width: 8),
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                    ]),
                    const SizedBox(height: 6),
                    Text(clientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Row(children: [
                      Text(pensionLabel, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      if (touchpointLabel != null) ...[
                        const Text(' · ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        Text(touchpointLabel!, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ]),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // Scrollable card content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
                  child: Column(children: cards),
                ),
              ),

              // Submit button
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: (isFormValid && !isSubmitting) ? onSubmit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(submitLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/record_forms/presentation/widgets/unified_action_bottom_sheet_test.dart
```
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/record_forms/presentation/widgets/unified_action_bottom_sheet.dart \
        test/features/record_forms/presentation/widgets/unified_action_bottom_sheet_test.dart
git commit -m "feat: add UnifiedActionBottomSheet base widget with header and submit button"
```

---

## Task 8: Update VisitFormData — make Reason and Status user-editable

**Files:**
- Modify: `lib/features/record_forms/data/models/visit_form_data.dart`

The current `VisitFormData` enforces that reason must be `clientNotAvailable` and status must be `incomplete`. Remove that enforcement so the user can pick freely.

- [ ] **Step 1: Replace the validation in `visit_form_data.dart`**

Open `lib/features/record_forms/data/models/visit_form_data.dart` and replace the entire `validationErrors` getter:

```dart
@override
Map<String, String?> get validationErrors {
  final errors = <String, String?>{};

  if (timeIn == null) errors['timeIn'] = 'Time In is required';

  if (calculatedTimeOut == null) {
    errors['timeOut'] = 'Time Out is required';
  } else if (timeIn != null && calculatedTimeOut!.isBefore(timeIn!)) {
    errors['timeOut'] = 'Must be after Time In';
  }

  if (odometerIn == null || odometerIn!.isEmpty) errors['odometerIn'] = 'Odometer In is required';

  if (odometerOut == null || odometerOut!.isEmpty) {
    errors['odometerOut'] = 'Odometer Out is required';
  } else if (odometerIn != null && odometerOut != null) {
    final inVal = int.tryParse(odometerIn!);
    final outVal = int.tryParse(odometerOut!);
    if (inVal != null && outVal != null && outVal < inVal) {
      errors['odometerOut'] = 'Must be >= Odometer In';
    }
  }

  if (photoPath == null || photoPath!.isEmpty) errors['photo'] = 'Photo is required';
  if (remarks == null || remarks!.trim().isEmpty) errors['remarks'] = 'Remarks is required';
  if (reason == null) errors['reason'] = 'Reason is required';
  if (status == null) errors['status'] = 'Status is required';

  return errors;
}
```

Also remove the `withAutoSetValues` factory constructor entirely (lines 29–55), since we no longer auto-set values.

Also update `isFilled`:
```dart
@override
bool get isFilled => super.isFilled &&
    reason != null &&
    status != null &&
    remarks != null &&
    remarks!.trim().isNotEmpty;
```

- [ ] **Step 2: Verify no other code uses `withAutoSetValues` for VisitFormData**

```bash
grep -r "VisitFormData.withAutoSetValues" --include="*.dart" .
```
Expected: No results. If results appear, update those call sites to use `VisitFormData(...)` directly with user-provided reason/status.

- [ ] **Step 3: Run existing tests to ensure nothing broke**

```bash
flutter test
```
Expected: All existing tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/record_forms/data/models/visit_form_data.dart
git commit -m "fix: make VisitFormData reason and status user-editable (remove auto-set enforcement)"
```

---

## Task 9: RecordTouchpointBottomSheet (thin wrapper)

**Files:**
- Create: `lib/features/record_forms/presentation/widgets/record_touchpoint_bottom_sheet.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/features/record_forms/presentation/widgets/record_touchpoint_bottom_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/schedule_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/details_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/notes_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/photo_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/unified_action_bottom_sheet.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart' show touchpointCreationServiceProvider;
import 'package:imu_flutter/core/utils/app_notification.dart';

class RecordTouchpointBottomSheet extends HookConsumerWidget {
  final Client client;

  const RecordTouchpointBottomSheet({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeIn = useState<TimeOfDay?>(null);
    final timeOut = useState<TimeOfDay?>(null);
    final odometerArrival = useState<String?>(null);
    final odometerDeparture = useState<String?>(null);
    final gpsData = useState<LocationData?>(null);
    final gpsFailed = useState(false);
    final reason = useState<TouchpointReason?>(null);
    final status = useState<TouchpointStatus?>(null);
    final remarks = useTextEditingController();
    final photoPath = useState<String?>(null);
    final submitAttempted = useState(false);
    final isSubmitting = useState(false);

    final isFormValid = timeIn.value != null &&
        timeOut.value != null &&
        (odometerArrival.value?.isNotEmpty ?? false) &&
        (odometerDeparture.value?.isNotEmpty ?? false) &&
        gpsData.value != null &&
        !gpsFailed.value &&
        reason.value != null &&
        status.value != null &&
        remarks.text.trim().isNotEmpty &&
        photoPath.value != null;

    final showErrors = submitAttempted.value;

    Future<void> handleSubmit() async {
      submitAttempted.value = true;
      if (!isFormValid) return;

      isSubmitting.value = true;
      try {
        final now = DateTime.now();
        final timeInDt = DateTime(now.year, now.month, now.day, timeIn.value!.hour, timeIn.value!.minute);
        final timeOutDt = DateTime(now.year, now.month, now.day, timeOut.value!.hour, timeOut.value!.minute);
        final gps = gpsData.value!;

        final touchpoint = Touchpoint(
          id: '',
          clientId: client.id!,
          touchpointNumber: client.nextTouchpointNumber ?? 1,
          type: TouchpointType.visit,
          reason: reason.value!,
          status: status.value!,
          date: now,
          createdAt: now,
          userId: '',
          remarks: remarks.text.trim(),
          photoPath: null,
          audioPath: null,
          timeIn: timeInDt,
          timeOut: timeOutDt,
          timeInGpsLat: gps.lat,
          timeInGpsLng: gps.lng,
          timeInGpsAddress: gps.address,
          timeOutGpsLat: gps.lat,
          timeOutGpsLng: gps.lng,
          timeOutGpsAddress: gps.address,
          odometerArrival: odometerArrival.value,
          odometerDeparture: odometerDeparture.value,
        );

        final service = ref.read(touchpointCreationServiceProvider);
        await service.createTouchpoint(
          client.id!,
          touchpoint,
          photo: photoPath.value != null ? File(photoPath.value!) : null,
        );

        if (context.mounted) {
          AppNotification.showSuccess(context, 'Touchpoint recorded successfully');
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(context, 'Failed to record touchpoint: $e');
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return UnifiedActionBottomSheet(
      icon: Icons.assignment_outlined,
      title: 'Record Touchpoint',
      clientName: client.fullName,
      pensionLabel: client.pensionType.toString(),
      touchpointLabel: 'Touchpoint ${client.nextTouchpointNumber ?? 1} of 7',
      submitLabel: 'Record Touchpoint',
      isFormValid: isFormValid,
      isSubmitting: isSubmitting.value,
      onSubmit: handleSubmit,
      cards: [
        ScheduleCard(
          timeIn: timeIn.value,
          timeOut: timeOut.value,
          odometerArrival: odometerArrival.value,
          odometerDeparture: odometerDeparture.value,
          showErrors: showErrors,
          onTimeInChanged: (t) {
            timeIn.value = t;
            // Auto-calculate Time Out as Time In + 5 min
            final totalMin = t.hour * 60 + t.minute + 5;
            timeOut.value = TimeOfDay(hour: (totalMin ~/ 60) % 24, minute: totalMin % 60);
          },
          onTimeOutChanged: (t) => timeOut.value = t,
          onOdometerArrivalChanged: (v) {
            odometerArrival.value = v;
            // Auto-calculate Odometer Departure as Arrival + 5
            final arrival = double.tryParse(v);
            if (arrival != null) odometerDeparture.value = (arrival + 5).toStringAsFixed(0);
          },
          onOdometerDepartureChanged: (v) => odometerDeparture.value = v,
        ),
        LocationCard(
          showError: showErrors && gpsData.value == null,
          onAcquired: (data) => gpsData.value = data,
          onFailed: () => gpsFailed.value = true,
        ),
        DetailsCard(
          locked: false,
          reason: reason.value,
          status: status.value,
          availableReasons: TouchpointReason.values.where((r) => r != TouchpointReason.newReleaseLoan).toList(),
          availableStatuses: [
            TouchpointStatus.interested,
            TouchpointStatus.undecided,
            TouchpointStatus.notInterested,
            TouchpointStatus.completed,
            TouchpointStatus.followUpNeeded,
          ],
          onReasonChanged: (r) => reason.value = r,
          onStatusChanged: (s) => status.value = s,
          showErrors: showErrors,
        ),
        NotesCard(controller: remarks, showError: showErrors),
        PhotoCard(
          photoPath: photoPath.value,
          onPhotoTaken: (path) => photoPath.value = path,
          showError: showErrors,
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Run the full test suite to confirm no regressions**

```bash
flutter test
```
Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/features/record_forms/presentation/widgets/record_touchpoint_bottom_sheet.dart
git commit -m "feat: add RecordTouchpointBottomSheet as thin wrapper using UnifiedActionBottomSheet"
```

---

## Task 10: RecordVisitBottomSheet (thin wrapper)

**Files:**
- Create: `lib/features/record_forms/presentation/widgets/record_visit_bottom_sheet.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/features/record_forms/presentation/widgets/record_visit_bottom_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/schedule_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/details_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/notes_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/photo_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/unified_action_bottom_sheet.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart' show visitCreationServiceProvider;
import 'package:imu_flutter/core/utils/app_notification.dart';

class RecordVisitBottomSheet extends HookConsumerWidget {
  final Client client;

  const RecordVisitBottomSheet({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeIn = useState<TimeOfDay?>(null);
    final timeOut = useState<TimeOfDay?>(null);
    final odometerArrival = useState<String?>(null);
    final odometerDeparture = useState<String?>(null);
    final gpsData = useState<LocationData?>(null);
    final gpsFailed = useState(false);
    final reason = useState<TouchpointReason?>(null);
    final status = useState<TouchpointStatus?>(null);
    final remarks = useTextEditingController();
    final photoPath = useState<String?>(null);
    final submitAttempted = useState(false);
    final isSubmitting = useState(false);

    final isFormValid = timeIn.value != null &&
        timeOut.value != null &&
        (odometerArrival.value?.isNotEmpty ?? false) &&
        (odometerDeparture.value?.isNotEmpty ?? false) &&
        gpsData.value != null &&
        !gpsFailed.value &&
        reason.value != null &&
        status.value != null &&
        remarks.text.trim().isNotEmpty &&
        photoPath.value != null;

    final showErrors = submitAttempted.value;

    Future<void> handleSubmit() async {
      submitAttempted.value = true;
      if (!isFormValid) return;

      isSubmitting.value = true;
      try {
        final now = DateTime.now();
        final timeInDt = DateTime(now.year, now.month, now.day, timeIn.value!.hour, timeIn.value!.minute);
        final timeOutDt = DateTime(now.year, now.month, now.day, timeOut.value!.hour, timeOut.value!.minute);
        final gps = gpsData.value!;

        final service = ref.read(visitCreationServiceProvider);
        await service.createVisit(
          clientId: client.id!,
          timeIn: timeInDt,
          timeOut: timeOutDt,
          odometerArrival: odometerArrival.value!,
          odometerDeparture: odometerDeparture.value!,
          gpsLatitude: gps.lat,
          gpsLongitude: gps.lng,
          gpsAddress: gps.address,
          reason: reason.value!,
          status: status.value!,
          remarks: remarks.text.trim(),
          photo: photoPath.value != null ? File(photoPath.value!) : null,
        );

        if (context.mounted) {
          AppNotification.showSuccess(context, 'Visit recorded successfully');
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(context, 'Failed to record visit: $e');
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return UnifiedActionBottomSheet(
      icon: Icons.home_outlined,
      title: 'Record Visit',
      clientName: client.fullName,
      pensionLabel: client.pensionType.toString(),
      touchpointLabel: 'Touchpoint ${client.nextTouchpointNumber ?? 1} of 7',
      submitLabel: 'Record Visit',
      isFormValid: isFormValid,
      isSubmitting: isSubmitting.value,
      onSubmit: handleSubmit,
      cards: [
        ScheduleCard(
          timeIn: timeIn.value,
          timeOut: timeOut.value,
          odometerArrival: odometerArrival.value,
          odometerDeparture: odometerDeparture.value,
          showErrors: showErrors,
          onTimeInChanged: (t) {
            timeIn.value = t;
            final totalMin = t.hour * 60 + t.minute + 5;
            timeOut.value = TimeOfDay(hour: (totalMin ~/ 60) % 24, minute: totalMin % 60);
          },
          onTimeOutChanged: (t) => timeOut.value = t,
          onOdometerArrivalChanged: (v) {
            odometerArrival.value = v;
            final arrival = double.tryParse(v);
            if (arrival != null) odometerDeparture.value = (arrival + 5).toStringAsFixed(0);
          },
          onOdometerDepartureChanged: (v) => odometerDeparture.value = v,
        ),
        LocationCard(
          showError: showErrors && gpsData.value == null,
          onAcquired: (data) => gpsData.value = data,
          onFailed: () => gpsFailed.value = true,
        ),
        DetailsCard(
          locked: false,
          reason: reason.value,
          status: status.value,
          availableReasons: TouchpointReason.values.where((r) => r != TouchpointReason.newReleaseLoan).toList(),
          availableStatuses: [
            TouchpointStatus.interested,
            TouchpointStatus.undecided,
            TouchpointStatus.notInterested,
            TouchpointStatus.completed,
            TouchpointStatus.followUpNeeded,
            TouchpointStatus.incomplete,
          ],
          onReasonChanged: (r) => reason.value = r,
          onStatusChanged: (s) => status.value = s,
          showErrors: showErrors,
        ),
        NotesCard(controller: remarks, showError: showErrors),
        PhotoCard(
          photoPath: photoPath.value,
          onPhotoTaken: (path) => photoPath.value = path,
          showError: showErrors,
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Check what method signature `visitCreationServiceProvider` exposes**

```bash
grep -n "createVisit\|VisitCreation" imu_flutter/lib/shared/providers/app_providers.dart imu_flutter/lib/services/visit/visit_creation_service.dart 2>/dev/null | head -20
```

If the `createVisit` signature differs from above, update `handleSubmit` to match the actual service method signature.

- [ ] **Step 3: Run the full test suite**

```bash
flutter test
```
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/record_forms/presentation/widgets/record_visit_bottom_sheet.dart
git commit -m "feat: add RecordVisitBottomSheet with editable reason and status fields"
```

---

## Task 11: RecordLoanReleaseBottomSheet (thin wrapper)

**Files:**
- Create: `lib/features/record_forms/presentation/widgets/record_loan_release_bottom_sheet.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/features/record_forms/presentation/widgets/record_loan_release_bottom_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/schedule_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/loan_details_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/details_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/notes_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/photo_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/unified_action_bottom_sheet.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart' show releaseCreationServiceProvider;
import 'package:imu_flutter/core/utils/app_notification.dart';

class RecordLoanReleaseBottomSheet extends HookConsumerWidget {
  final Client client;

  const RecordLoanReleaseBottomSheet({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeIn = useState<TimeOfDay?>(null);
    final timeOut = useState<TimeOfDay?>(null);
    final odometerArrival = useState<String?>(null);
    final odometerDeparture = useState<String?>(null);
    final gpsData = useState<LocationData?>(null);
    final gpsFailed = useState(false);
    final productType = useState<ProductType?>(null);
    final loanType = useState<LoanType?>(null);
    final udiController = useTextEditingController();
    final remarks = useTextEditingController();
    final photoPath = useState<String?>(null);
    final submitAttempted = useState(false);
    final isSubmitting = useState(false);

    final isFormValid = timeIn.value != null &&
        timeOut.value != null &&
        (odometerArrival.value?.isNotEmpty ?? false) &&
        (odometerDeparture.value?.isNotEmpty ?? false) &&
        gpsData.value != null &&
        !gpsFailed.value &&
        productType.value != null &&
        loanType.value != null &&
        udiController.text.trim().isNotEmpty &&
        remarks.text.trim().isNotEmpty &&
        photoPath.value != null;

    final showErrors = submitAttempted.value;

    Future<void> handleSubmit() async {
      submitAttempted.value = true;
      if (!isFormValid) return;

      isSubmitting.value = true;
      try {
        final now = DateTime.now();
        final timeInDt = DateTime(now.year, now.month, now.day, timeIn.value!.hour, timeIn.value!.minute);
        final timeOutDt = DateTime(now.year, now.month, now.day, timeOut.value!.hour, timeOut.value!.minute);
        final gps = gpsData.value!;

        final service = ref.read(releaseCreationServiceProvider);
        await service.createRelease(
          clientId: client.id!,
          timeIn: timeInDt,
          timeOut: timeOutDt,
          odometerArrival: odometerArrival.value!,
          odometerDeparture: odometerDeparture.value!,
          gpsLatitude: gps.lat,
          gpsLongitude: gps.lng,
          gpsAddress: gps.address,
          productType: productType.value!,
          loanType: loanType.value!,
          udiNumber: udiController.text.trim(),
          remarks: remarks.text.trim(),
          photo: photoPath.value != null ? File(photoPath.value!) : null,
        );

        if (context.mounted) {
          AppNotification.showSuccess(context, 'Loan release recorded successfully');
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(context, 'Failed to record loan release: $e');
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return UnifiedActionBottomSheet(
      icon: Icons.monetization_on_outlined,
      title: 'Record Loan Release',
      clientName: client.fullName,
      pensionLabel: client.pensionType.toString(),
      touchpointLabel: 'Touchpoint 7 of 7',
      submitLabel: 'Record Loan Release',
      isFormValid: isFormValid,
      isSubmitting: isSubmitting.value,
      onSubmit: handleSubmit,
      cards: [
        ScheduleCard(
          timeIn: timeIn.value,
          timeOut: timeOut.value,
          odometerArrival: odometerArrival.value,
          odometerDeparture: odometerDeparture.value,
          showErrors: showErrors,
          onTimeInChanged: (t) {
            timeIn.value = t;
            final totalMin = t.hour * 60 + t.minute + 5;
            timeOut.value = TimeOfDay(hour: (totalMin ~/ 60) % 24, minute: totalMin % 60);
          },
          onTimeOutChanged: (t) => timeOut.value = t,
          onOdometerArrivalChanged: (v) {
            odometerArrival.value = v;
            final arrival = double.tryParse(v);
            if (arrival != null) odometerDeparture.value = (arrival + 5).toStringAsFixed(0);
          },
          onOdometerDepartureChanged: (v) => odometerDeparture.value = v,
        ),
        LocationCard(
          showError: showErrors && gpsData.value == null,
          onAcquired: (data) => gpsData.value = data,
          onFailed: () => gpsFailed.value = true,
        ),
        LoanDetailsCard(
          productType: productType.value,
          loanType: loanType.value,
          udiController: udiController,
          onProductTypeChanged: (p) => productType.value = p,
          onLoanTypeChanged: (l) => loanType.value = l,
          showErrors: showErrors,
        ),
        DetailsCard(
          locked: true,
          reason: null,
          status: null,
          availableReasons: const [],
          availableStatuses: const [],
          onReasonChanged: null,
          onStatusChanged: null,
          showErrors: false,
          lockedReasonLabel: 'New Loan Release',
          lockedStatusLabel: 'Completed',
        ),
        NotesCard(controller: remarks, showError: showErrors),
        PhotoCard(
          photoPath: photoPath.value,
          onPhotoTaken: (path) => photoPath.value = path,
          showError: showErrors,
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Check the `releaseCreationServiceProvider` method signature**

```bash
grep -n "createRelease\|ReleaseCreation" imu_flutter/lib/shared/providers/app_providers.dart imu_flutter/lib/services/visit/visit_creation_service.dart 2>/dev/null | head -20
```

Adjust `handleSubmit` parameters to match the actual service method.

- [ ] **Step 3: Run the full test suite**

```bash
flutter test
```
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/record_forms/presentation/widgets/record_loan_release_bottom_sheet.dart
git commit -m "feat: add RecordLoanReleaseBottomSheet with locked reason/status and loan details"
```

---

## Task 12: Update all call sites

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart`
- Modify: `lib/features/itinerary/presentation/pages/itinerary_page.dart`
- Modify: `lib/features/my_day/presentation/pages/my_day_page.dart`

In each file, replace the old imports and `showModalBottomSheet` calls.

- [ ] **Step 1: Update imports in all three files**

Remove old imports pointing to `clients/presentation/widgets/`:
```dart
// REMOVE these lines from each file:
import 'package:imu_flutter/features/clients/presentation/widgets/record_touchpoint_bottom_sheet.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart';
```

Add new imports:
```dart
import 'package:imu_flutter/features/record_forms/presentation/widgets/record_touchpoint_bottom_sheet.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/record_visit_bottom_sheet.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/record_loan_release_bottom_sheet.dart';
```

- [ ] **Step 2: Replace the `showModalBottomSheet` for Visit in all three files**

Find: `RecordVisitOnlyBottomSheet(client: client)` (or `visit` in itinerary/my_day pages)

Replace with: `RecordVisitBottomSheet(client: client)`

Also add `isScrollControlled: true` and `useSafeArea: true` if not already present:
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (ctx) => RecordVisitBottomSheet(client: client),
);
```

Apply the same `isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent` to the Touchpoint and Release `showModalBottomSheet` calls in all three files.

- [ ] **Step 3: Verify the app compiles**

```bash
flutter build apk --debug 2>&1 | tail -20
```
Expected: Build succeeds with no errors.

- [ ] **Step 4: Run full test suite**

```bash
flutter test
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/clients/presentation/pages/client_detail_page.dart \
        lib/features/itinerary/presentation/pages/itinerary_page.dart \
        lib/features/my_day/presentation/pages/my_day_page.dart
git commit -m "refactor: update all call sites to use new unified bottom sheet widgets"
```

---

## Task 13: Delete old files

**Files to delete:**
- `lib/features/clients/presentation/widgets/client_action_bottom_sheet.dart`
- `lib/features/clients/presentation/widgets/record_touchpoint_bottom_sheet.dart`
- `lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart`
- `lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart`

- [ ] **Step 1: Verify nothing still imports the old files**

```bash
grep -r "clients/presentation/widgets/record_touchpoint_bottom_sheet\|clients/presentation/widgets/record_visit_only\|clients/presentation/widgets/record_loan_release\|clients/presentation/widgets/client_action_bottom_sheet" --include="*.dart" imu_flutter/lib/
```
Expected: No results. If any appear, fix those imports first.

- [ ] **Step 2: Delete the old files**

```bash
rm imu_flutter/lib/features/clients/presentation/widgets/client_action_bottom_sheet.dart
rm imu_flutter/lib/features/clients/presentation/widgets/record_touchpoint_bottom_sheet.dart
rm imu_flutter/lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart
rm imu_flutter/lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart
```

- [ ] **Step 3: Run full test suite one final time**

```bash
flutter test
```
Expected: All tests PASS.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: delete old bottom sheet files replaced by unified widget architecture"
```

---

## Self-Review

**Spec coverage check:**
- ✅ Unified design: All three sheets use `UnifiedActionBottomSheet`
- ✅ Grab-style card sections: `SectionCard` wrapper on all cards
- ✅ Header with client info: title, name, pension, touchpoint label
- ✅ GPS required: `LocationCard` in all three sheets, hard blocks submit
- ✅ Hybrid validation: `submitAttempted` flag + disabled submit from start
- ✅ Photo thumbnail: `PhotoCard` shows 64px thumbnail + retake
- ✅ Visit Reason/Status now editable: `DetailsCard(locked: false)` + `VisitFormData` updated
- ✅ Release Reason/Status locked: `DetailsCard(locked: true)` with lock icon
- ✅ Remarks required: `NotesCard` with `showError` and required validation
- ✅ Keyboard handling: `isScrollControlled: true` + `viewInsets.bottom` padding in base widget
- ✅ Auto-calculations: Time Out = Time In + 5 min, Odo Departure = Odo Arrival + 5
- ✅ Old files deleted: Task 13

**Placeholder scan:** No TBDs or TODOs. All code blocks are complete.

**Type consistency:**
- `LocationData` defined in `location_card.dart`, imported by all three sheets ✅
- `SectionCard` defined in `location_card.dart`, imported by all card widgets ✅
- `TouchpointReason`, `TouchpointStatus`, `ProductType`, `LoanType` from `touchpoint_form_data.dart` ✅
- `visitCreationServiceProvider`, `releaseCreationServiceProvider` from `app_providers.dart` — Task 10/11 both include a verification grep step ✅
