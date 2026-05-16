import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imu_flutter/services/geofencing/geofencing_service.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

// Agent fixed at 14.5995° N, 120.9842° E (Manila area).
const _agentLat = 14.5995;
const _agentLng = 120.9842;

// Client ~350m north of the agent (within 400m)
const _nearLat = _agentLat + 0.00315;
const _nearLng = _agentLng;

// Client ~450m north of the agent (outside 400m)
const _farLat = _agentLat + 0.00405;
const _farLng = _agentLng;

Map<String, dynamic> _row({
  String id = 'client-1',
  double? lat = _nearLat,
  double? lng = _nearLng,
}) =>
    {
      'id': id,
      'first_name': 'Juan',
      'middle_name': '',
      'last_name': 'Dela Cruz',
      'full_address': 'Brgy. Poblacion, Manila',
      'latitude': lat,
      'longitude': lng,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockPlugin mockPlugin;
  late GeofencingService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPlugin = _MockPlugin();

    when(() => mockPlugin.show(
          any(),
          any(),
          any(),
          any(),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});

    service = GeofencingService(plugin: mockPlugin);
  });

  group('processNearbyClients — distance', () {
    test('fires notification for client within 400m with no cooldown', () async {
      await service.processNearbyClients(
        agentLat: _agentLat,
        agentLng: _agentLng,
        clientRows: [_row()],
      );

      verify(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).called(1);
    });

    test('does not fire for client beyond 400m', () async {
      await service.processNearbyClients(
        agentLat: _agentLat,
        agentLng: _agentLng,
        clientRows: [_row(lat: _farLat, lng: _farLng)],
      );

      verifyNever(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ));
    });

    test('skips client with null coordinates', () async {
      await service.processNearbyClients(
        agentLat: _agentLat,
        agentLng: _agentLng,
        clientRows: [_row(lat: null, lng: null)],
      );

      verifyNever(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ));
    });

    test('fires separate notifications for multiple nearby clients', () async {
      await service.processNearbyClients(
        agentLat: _agentLat,
        agentLng: _agentLng,
        clientRows: [
          _row(id: 'client-a'),
          // _nearLat - 0.001 ≈ agentLat + 0.00215 ≈ 239m (inside fence)
          _row(id: 'client-b', lat: _nearLat - 0.001, lng: _nearLng),
        ],
      );

      verify(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).called(2);
    });
  });

  // Area scoping is enforced at the SQL layer in _onPositionUpdate via an
  // EXISTS subquery joining user_locations → psgc → clients.psgc_id.
  // processNearbyClients receives only rows that already passed that filter.
  // These tests document the expected downstream behaviour for both outcomes.
  group('processNearbyClients — area scoping (SQL-enforced)', () {
    test('fires for client returned by area-scoped SQL', () async {
      // Simulates SQL returning one row that passed the municipality filter.
      await service.processNearbyClients(
        agentLat: _agentLat,
        agentLng: _agentLng,
        clientRows: [_row()],
      );

      verify(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).called(1);
    });

    test('fires no notification when SQL returns empty (all outside assigned area)', () async {
      // Simulates SQL returning zero rows because the EXISTS area filter
      // excluded every nearby client.
      await service.processNearbyClients(
        agentLat: _agentLat,
        agentLng: _agentLng,
        clientRows: const [],
      );

      verifyNever(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ));
    });

    test('fires only for in-fence client when area filter passes multiple rows', () async {
      // Area filter passes both rows; distance check then eliminates the far one.
      // Verifies per-row independence: one fires, one does not.
      await service.processNearbyClients(
        agentLat: _agentLat,
        agentLng: _agentLng,
        clientRows: [
          _row(id: 'near', lat: _nearLat, lng: _nearLng),
          _row(id: 'far', lat: _farLat, lng: _farLng),
        ],
      );

      verify(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).called(1);
    });
  });

  group('processNearbyClients — cooldown', () {
    test('does not fire when cooldown active (8 hours ago)', () async {
      const clientId = 'client-1';
      final eightHoursAgo = DateTime.now()
          .subtract(const Duration(hours: 8))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'geofence_cooldown_$clientId': eightHoursAgo,
      });
      service = GeofencingService(plugin: mockPlugin);

      await service.processNearbyClients(
        agentLat: _agentLat,
        agentLng: _agentLng,
        clientRows: [_row(id: clientId)],
      );

      verifyNever(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ));
    });

    test('fires when cooldown has expired (17 hours ago)', () async {
      const clientId = 'client-1';
      final seventeenHoursAgo = DateTime.now()
          .subtract(const Duration(hours: 17))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'geofence_cooldown_$clientId': seventeenHoursAgo,
      });
      service = GeofencingService(plugin: mockPlugin);

      await service.processNearbyClients(
        agentLat: _agentLat,
        agentLng: _agentLng,
        clientRows: [_row(id: clientId)],
      );

      verify(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).called(1);
    });

    test('cooldown is written before notification fires', () async {
      int? cooldownWrittenAt;
      int? notificationFiredAt;

      when(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {
        notificationFiredAt = DateTime.now().millisecondsSinceEpoch;
      });

      await service.processNearbyClients(
        agentLat: _agentLat,
        agentLng: _agentLng,
        clientRows: [_row(id: 'order-test')],
      );

      final prefs = await SharedPreferences.getInstance();
      cooldownWrittenAt = prefs.getInt('geofence_cooldown_order-test');

      expect(cooldownWrittenAt, isNotNull);
      expect(notificationFiredAt, isNotNull);
      expect(cooldownWrittenAt, lessThanOrEqualTo(notificationFiredAt!));
    });
  });

  group('isCooldownExpired', () {
    test('returns true when no key stored', () async {
      final result = await service.isCooldownExpired('never-seen');
      expect(result, isTrue);
    });

    test('returns false immediately after writeCooldown', () async {
      await service.writeCooldown('fresh-client');
      final result = await service.isCooldownExpired('fresh-client');
      expect(result, isFalse);
    });

    test('returns true when stored timestamp is 17 hours old', () async {
      final old = DateTime.now()
          .subtract(const Duration(hours: 17))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'geofence_cooldown_old': old});
      service = GeofencingService(plugin: mockPlugin);

      final result = await service.isCooldownExpired('old');
      expect(result, isTrue);
    });

    test('returns false when stored timestamp is 8 hours old', () async {
      final recent = DateTime.now()
          .subtract(const Duration(hours: 8))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'geofence_cooldown_recent': recent});
      service = GeofencingService(plugin: mockPlugin);

      final result = await service.isCooldownExpired('recent');
      expect(result, isFalse);
    });
  });

  group('writeCooldown', () {
    test('stores current timestamp in SharedPreferences', () async {
      final before = DateTime.now().millisecondsSinceEpoch;
      await service.writeCooldown('my-client');
      final after = DateTime.now().millisecondsSinceEpoch;

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt('geofence_cooldown_my-client');
      expect(stored, isNotNull);
      expect(stored, greaterThanOrEqualTo(before));
      expect(stored, lessThanOrEqualTo(after));
    });
  });
}
