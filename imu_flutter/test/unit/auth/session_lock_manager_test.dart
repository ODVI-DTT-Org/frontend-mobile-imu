import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/auth/session_lock_manager.dart';
import 'package:imu_flutter/services/auth/session_service.dart';

void main() {
  group('SessionLockManager', () {
    late SessionLockManager lockManager;
    late SessionService sessionService;

    setUp(() {
      // SessionService is a singleton, don't create new instances
      sessionService = SessionService();
      lockManager = SessionLockManager(sessionService: sessionService);
    });

    tearDown(() {
      // Only dispose lockManager, not the singleton SessionService
      lockManager.dispose();
      // Note: SessionService is a singleton and will persist across tests
    });

    group('Lock State Management', () {
      test('should not be locked initially', () {
        expect(lockManager.isLocked, isFalse);
      });

      test('should lock when lock() is called', () {
        lockManager.lock();
        expect(lockManager.isLocked, isTrue);
        // Cleanup
        lockManager.unlock();
      });

      test('should unlock when unlock() is called', () {
        lockManager.lock();
        lockManager.unlock();
        expect(lockManager.isLocked, isFalse);
      });

      test('should reset timer on unlock', () {
        sessionService.startSession();
        lockManager.lock();
        lockManager.unlock();

        expect(lockManager.isLocked, isFalse);
        expect(lockManager.timeUntilLock, isNotNull);
      });
    });

    group('Activity Tracking', () {
      test('should record activity and reset timer', () {
        sessionService.startSession();
        lockManager.startMonitoring();

        final timeBefore = lockManager.timeUntilLock;
        lockManager.recordActivity();
        final timeAfter = lockManager.timeUntilLock;

        expect(timeBefore, isNotNull);
        expect(timeAfter, isNotNull);
        // Time should be reset (close to 15 minutes, allow 14-15 minutes)
        expect(timeAfter!.inMinutes, greaterThanOrEqualTo(14));
        expect(timeAfter!.inMinutes, lessThanOrEqualTo(15));
        // Cleanup
        lockManager.stopMonitoring();
      });

      test('should not record activity when locked', () {
        sessionService.startSession();
        lockManager.lock();
        final timeBefore = lockManager.timeUntilLock;

        lockManager.recordActivity();
        final timeAfter = lockManager.timeUntilLock;

        // Timer should not be reset when locked
        expect(timeAfter, isNull);
        // Cleanup
        lockManager.unlock();
      });
    });

    group('Monitoring', () {
      test('should start monitoring when startMonitoring is called', () {
        sessionService.startSession();
        lockManager.startMonitoring();

        expect(lockManager.timeUntilLock, isNotNull);
        // Cleanup
        lockManager.stopMonitoring();
      });

      test('should stop monitoring when stopMonitoring is called', () {
        sessionService.startSession();
        lockManager.startMonitoring();
        lockManager.stopMonitoring();

        expect(lockManager.timeUntilLock, isNull);
      });

      test('should return null for timeUntilLock when not monitoring', () {
        sessionService.startSession();
        // Don't start monitoring
        expect(lockManager.timeUntilLock, isNull);
      });
    });

    group('Lock Triggers', () {
      test('should not lock immediately after monitoring starts', () {
        sessionService.startSession();
        lockManager.startMonitoring();

        expect(lockManager.shouldLock(), isFalse);
        // Cleanup
        lockManager.stopMonitoring();
      });

      test('should have inactivity lock duration of 15 minutes', () {
        expect(SessionLockManager.inactivityLockDuration, equals(const Duration(minutes: 15)));
      });

      test('should not lock when there is recent activity', () {
        sessionService.startSession();
        lockManager.startMonitoring();

        // Record activity
        sessionService.recordActivity();

        // Should not lock
        expect(lockManager.shouldLock(), isFalse);
        // Cleanup
        lockManager.stopMonitoring();
      });
    });

    group('Constants', () {
      test('should have inactivity lock duration of 15 minutes', () {
        expect(SessionLockManager.inactivityLockDuration, equals(const Duration(minutes: 15)));
      });
    });
  });
}
