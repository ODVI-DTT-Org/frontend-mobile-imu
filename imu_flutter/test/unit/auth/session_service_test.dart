import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/auth/session_service.dart';

void main() {
  group('SessionService', () {
    late SessionService sessionService;

    setUp(() {
      sessionService = SessionService();
    });

    tearDown(() {
      sessionService.dispose();
    });

    group('Session Lifecycle', () {
      test('should start session with current time', () async {
        final beforeStart = DateTime.now();
        sessionService.startSession();
        final afterStart = DateTime.now();

        expect(sessionService.sessionStartTime, isNotNull);
        // Session start time should be between beforeStart and afterStart
        expect(sessionService.sessionStartTime!.isAtSameMomentAs(beforeStart) ||
               sessionService.sessionStartTime!.isAfter(beforeStart), isTrue);
        expect(sessionService.sessionStartTime!.isAtSameMomentAs(afterStart) ||
               sessionService.sessionStartTime!.isBefore(afterStart), isTrue);
      });

      test('should be active after starting session', () {
        sessionService.startSession();

        expect(sessionService.isSessionActive, isTrue);
      });

      test('should not be active initially', () {
        expect(sessionService.isSessionActive, isFalse);
      });

      test('should end session and clear state', () {
        sessionService.startSession();
        sessionService.endSession();

        expect(sessionService.sessionStartTime, isNull);
        expect(sessionService.isSessionActive, isFalse);
      });
    });

    group('Activity Tracking', () {
      test('should record last activity time', () {
        sessionService.startSession();
        final beforeActivity = DateTime.now();
        sessionService.recordActivity();
        final afterActivity = DateTime.now();

        expect(sessionService.lastActivityTime, isNotNull);
        // Activity time should be between beforeActivity and afterActivity
        expect(sessionService.lastActivityTime!.isAtSameMomentAs(beforeActivity) ||
               sessionService.lastActivityTime!.isAfter(beforeActivity), isTrue);
        expect(sessionService.lastActivityTime!.isAtSameMomentAs(afterActivity) ||
               sessionService.lastActivityTime!.isBefore(afterActivity), isTrue);
      });

      test('should update activity time on multiple calls', () async {
        sessionService.startSession();
        sessionService.recordActivity();
        final firstActivity = sessionService.lastActivityTime;

        await Future.delayed(const Duration(milliseconds: 10));
        sessionService.recordActivity();
        final secondActivity = sessionService.lastActivityTime;

        expect(secondActivity!.isAfter(firstActivity!), isTrue);
      });
    });

    group('Session Expiry', () {
      test('should calculate session age correctly', () async {
        sessionService.startSession();
        await Future.delayed(const Duration(milliseconds: 100));

        final age = sessionService.sessionAge;
        expect(age, isNotNull);
        expect(age!.inMilliseconds, greaterThanOrEqualTo(100));
      });

      test('should return null for session age when not active', () {
        final age = sessionService.sessionAge;
        expect(age, isNull);
      });

      test('should calculate remaining session time', () {
        sessionService.startSession();
        final remaining = sessionService.getRemainingSessionTime();

        expect(remaining, isNotNull);
        // Should be close to 8 hours (7-8 hours due to execution time)
        expect(remaining!.inHours, greaterThanOrEqualTo(7));
        expect(remaining!.inHours, lessThanOrEqualTo(8));
      });

      test('should return null for remaining time when not active', () {
        final remaining = sessionService.getRemainingSessionTime();
        expect(remaining, isNull);
      });

      test('should not be expired immediately after starting', () {
        sessionService.startSession();
        expect(sessionService.isSessionExpired(), isFalse);
      });

      test('should have max session duration of 8 hours', () {
        expect(SessionService.maxSessionDuration, equals(const Duration(hours: 8)));
      });
    });

    group('Constants', () {
      test('should have max session duration of 8 hours', () {
        expect(SessionService.maxSessionDuration, equals(const Duration(hours: 8)));
      });
    });
  });
}
