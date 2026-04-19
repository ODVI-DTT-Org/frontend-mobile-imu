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

    testWidgets('shows red background when showError true and GPS failed', (tester) async {
      await tester.pumpWidget(_wrap(
        LocationCard(
          locationFetcher: () async => null,
          onAcquired: (_) {},
          onFailed: () {},
          showError: true,
        ),
      ));
      await tester.pumpAndSettle();
      final containers = tester.widgetList<Container>(
        find.ancestor(
          of: find.text('GPS Unavailable'),
          matching: find.byType(Container),
        ),
      );
      final hasRedBackground = containers.any((c) {
        final decoration = c.decoration as BoxDecoration?;
        return decoration?.color == const Color(0xFFFEE2E2);
      });
      expect(hasRedBackground, isTrue);
    });
  });
}
