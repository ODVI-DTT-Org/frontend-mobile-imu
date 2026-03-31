import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/auth/data/services/network_state_service.dart';

void main() {
  // Initialize Flutter test binding for tests that use platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkStateService', () {
    late NetworkStateService networkService;

    setUp(() {
      networkService = NetworkStateService();
    });

    tearDown(() {
      networkService.dispose();
    });

    group('Initialization', () {
      test('should have unknown status initially', () {
        expect(networkService.currentStatus, equals(NetworkStatus.unknown));
      });

      test('should initialize with connectivity check', () async {
        await networkService.initialize();

        expect(networkService.currentStatus, isNot(equals(NetworkStatus.unknown)));
      });

      test('should start polling when requested', () async {
        await networkService.initialize(startPolling: true);

        // Wait a bit for polling to occur
        await Future.delayed(const Duration(milliseconds: 100));

        // Should have checked status at least once
        expect(networkService.currentStatus, isNot(equals(NetworkStatus.unknown)));
      });
    });

    group('Connectivity Checking', () {
      test('should check connectivity', () async {
        final isOnline = await networkService.checkConnectivity();

        expect(isOnline, isTrue); // Mock always returns true
      });

      test('should return detailed check result', () async {
        final result = await networkService.checkConnectivityDetailed();

        expect(result.isOnline, isTrue);
        expect(result.status, equals(NetworkStatus.online));
        expect(result.checkedAt, isNotNull);
      });

      test('should emit status changes on stream', () async {
        final statuses = <NetworkStatus>[];
        final subscription = networkService.statusStream.listen(statuses.add);

        await networkService.checkConnectivity();

        expect(statuses, isNotEmpty);
        expect(statuses.last, equals(NetworkStatus.online));

        await subscription.cancel();
      });
    });

    group('Status Properties', () {
      test('should reflect online status', () async {
        await networkService.initialize();

        expect(networkService.isOnline, isTrue);
        expect(networkService.isOffline, isFalse);
      });

      test('should reflect offline status when set', () {
        networkService.setNetworkStatus(NetworkStatus.offline);

        expect(networkService.isOnline, isFalse);
        expect(networkService.isOffline, isTrue);
      });
    });

    group('Status Polling', () {
      test('should start status polling', () async {
        networkService.startStatusPolling(
          interval: const Duration(milliseconds: 100),
        );

        await Future.delayed(const Duration(milliseconds: 250));

        // Should have polled at least twice
        expect(networkService.currentStatus, isNot(equals(NetworkStatus.unknown)));

        networkService.stopStatusPolling();
      });

      test('should stop status polling', () async {
        networkService.startStatusPolling(
          interval: const Duration(milliseconds: 100),
        );

        await Future.delayed(const Duration(milliseconds: 50));
        networkService.stopStatusPolling();

        final statusBefore = networkService.currentStatus;

        await Future.delayed(const Duration(milliseconds: 150));

        // Status should not have changed
        expect(networkService.currentStatus, equals(statusBefore));
      });
    });

    group('Manual Status Setting', () {
      test('should set network status for testing', () {
        final statuses = <NetworkStatus>[];
        final subscription = networkService.statusStream.listen(statuses.add);

        networkService.setNetworkStatus(NetworkStatus.offline);

        expect(networkService.currentStatus, equals(NetworkStatus.offline));
        expect(statuses.last, equals(NetworkStatus.offline));

        subscription.cancel();
      });

      test('should emit status when setting manually', () {
        final statuses = <NetworkStatus>[];
        final subscription = networkService.statusStream.listen(statuses.add);

        networkService.setNetworkStatus(NetworkStatus.online);
        networkService.setNetworkStatus(NetworkStatus.offline);
        networkService.setNetworkStatus(NetworkStatus.unknown);

        expect(statuses, equals([
          NetworkStatus.online,
          NetworkStatus.offline,
          NetworkStatus.unknown,
        ]));

        subscription.cancel();
      });
    });

    group('Constants', () {
      test('should have 30-second default polling interval', () {
        expect(
          NetworkStateService.defaultPollingInterval,
          equals(const Duration(seconds: 30)),
        );
      });
    });

    group('NetworkCheckResult', () {
      test('should create online result', () {
        final result = NetworkCheckResult.online();

        expect(result.isOnline, isTrue);
        expect(result.status, equals(NetworkStatus.online));
        expect(result.checkedAt, isNotNull);
      });

      test('should create offline result', () {
        final result = NetworkCheckResult.offline(reason: 'No connection');

        expect(result.isOnline, isFalse);
        expect(result.status, equals(NetworkStatus.offline));
        expect(result.errorMessage, equals('No connection'));
      });

      test('should create unknown result', () {
        final result = NetworkCheckResult.unknown();

        expect(result.isOnline, isFalse);
        expect(result.status, equals(NetworkStatus.unknown));
      });

      test('should provide readable toString', () {
        final online = NetworkCheckResult.online();
        final offline = NetworkCheckResult.offline(reason: 'No signal');

        expect(online.toString(), contains('online'));
        expect(offline.toString(), contains('offline'));
      });
    });
  });
}
