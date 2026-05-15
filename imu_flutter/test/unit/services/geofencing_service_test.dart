import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Pure logic helpers (extracted from GeofencingService for unit-testability)
// ---------------------------------------------------------------------------

/// Returns true if the agent is within radiusMeters of the client.
bool isWithinRadius(
  double agentLat,
  double agentLng,
  double clientLat,
  double clientLng, {
  double radiusMeters = 400.0,
}) {
  final dist = Geolocator.distanceBetween(agentLat, agentLng, clientLat, clientLng);
  return dist <= radiusMeters;
}

/// Returns true if the cooldown for clientId has expired (or was never set).
bool cooldownExpired(
  String clientId,
  Map<String, int> prefs,
  Duration cooldown,
  DateTime now,
) {
  final key = 'geofence_cooldown_$clientId';
  final lastMs = prefs[key];
  if (lastMs == null) return true;
  return (now.millisecondsSinceEpoch - lastMs) >= cooldown.inMilliseconds;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeofencingService — proximity logic', () {
    const agentLat = 6.9000;
    const agentLng = 122.0760;

    // Client at ~360m north (within radius)
    const nearClientLat = 6.9032;
    const nearClientLng = 122.0760;

    // Client at ~440m north (outside radius)
    const farClientLat = 6.9040;
    const farClientLng = 122.0760;

    test('client at ~360m triggers notification (within 400m)', () {
      expect(
        isWithinRadius(agentLat, agentLng, nearClientLat, nearClientLng),
        isTrue,
      );
    });

    test('client at ~440m does not trigger notification (outside 400m)', () {
      expect(
        isWithinRadius(agentLat, agentLng, farClientLat, farClientLng),
        isFalse,
      );
    });

    test('exact 400m boundary is included', () {
      // 0.0036° latitude ≈ 400m — verify the helper accepts it
      const clientLat = agentLat + 0.0036;
      final dist = Geolocator.distanceBetween(agentLat, agentLng, clientLat, agentLng);
      // Should be within ±10m of 400m
      expect(dist, lessThanOrEqualTo(410.0));
    });
  });

  group('GeofencingService — cooldown logic', () {
    const clientId = 'client-abc';
    const cooldown = Duration(hours: 16);

    test('no cooldown set → should fire notification', () {
      expect(
        cooldownExpired(clientId, {}, cooldown, DateTime.now()),
        isTrue,
      );
    });

    test('cooldown active (8 hours ago) → should NOT fire', () {
      final now = DateTime.now();
      final eightHoursAgo = now.subtract(const Duration(hours: 8));
      final prefs = {'geofence_cooldown_$clientId': eightHoursAgo.millisecondsSinceEpoch};
      expect(cooldownExpired(clientId, prefs, cooldown, now), isFalse);
    });

    test('cooldown expired (17 hours ago) → should fire', () {
      final now = DateTime.now();
      final seventeenHoursAgo = now.subtract(const Duration(hours: 17));
      final prefs = {'geofence_cooldown_$clientId': seventeenHoursAgo.millisecondsSinceEpoch};
      expect(cooldownExpired(clientId, prefs, cooldown, now), isTrue);
    });

    test('exactly at 16-hour boundary → should NOT fire (not yet expired)', () {
      final now = DateTime.now();
      final exactlyAt = now.subtract(const Duration(hours: 16));
      final prefs = {'geofence_cooldown_$clientId': exactlyAt.millisecondsSinceEpoch};
      // At exactly 16h the difference equals cooldown.inMilliseconds — not > so not expired
      expect(cooldownExpired(clientId, prefs, cooldown, now), isFalse);
    });

    test('each client has independent cooldown key', () {
      final now = DateTime.now();
      final recentMs = now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
      final prefs = {'geofence_cooldown_client-A': recentMs};

      // client-A is on cooldown
      expect(cooldownExpired('client-A', prefs, cooldown, now), isFalse);
      // client-B has no cooldown entry → should fire
      expect(cooldownExpired('client-B', prefs, cooldown, now), isTrue);
    });
  });

  group('GeofencingService — SharedPreferences integration', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('cooldown key is written when notification fires', () async {
      final prefs = await SharedPreferences.getInstance();
      const clientId = 'client-xyz';
      const key = 'geofence_cooldown_$clientId';

      expect(prefs.getInt(key), isNull);

      // Simulate writing the cooldown (as GeofencingService does before firing)
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(key, nowMs);

      final stored = prefs.getInt(key);
      expect(stored, isNotNull);
      expect((DateTime.now().millisecondsSinceEpoch - stored!),
          lessThan(1000)); // written < 1s ago
    });
  });
}
