import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/error_contextualizer.dart';

void main() {
  group('ErrorContextualizer', () {
    group('getContextualMessage - Defined Mappings', () {
      test('returns contextual message for login_INVALID_CREDENTIALS', () {
        final message = ErrorContextualizer.getContextualMessage(
          'INVALID_CREDENTIALS',
          'login',
        );
        expect(message, 'Invalid email or password. Please try again.');
      });

      test('returns contextual message for login_NETWORK_ERROR', () {
        final message = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'login',
        );
        expect(message, 'Unable to sign in. Please check your internet connection.');
      });

      test('returns contextual message for save_client_VALIDATION_ERROR', () {
        final message = ErrorContextualizer.getContextualMessage(
          'VALIDATION_ERROR',
          'save_client',
        );
        expect(message, 'Please check the client information.');
      });

      test('returns contextual message for save_client_NETWORK_ERROR', () {
        final message = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'save_client',
        );
        expect(message, 'Unable to save client. Please check your connection.');
      });

      test('returns contextual message for submit_touchpoint_INVALID_TOUCHPOINT_TYPE', () {
        final message = ErrorContextualizer.getContextualMessage(
          'INVALID_TOUCHPOINT_TYPE',
          'submit_touchpoint',
        );
        expect(message, 'You can only create visit touchpoints.');
      });

      test('returns contextual message for submit_touchpoint_NETWORK_ERROR', () {
        final message = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'submit_touchpoint',
        );
        expect(message, 'Unable to submit touchpoint. Please check your connection.');
      });

      test('returns contextual message for sync_data_NETWORK_ERROR', () {
        final message = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'sync_data',
        );
        expect(message, 'Unable to sync. Please check your internet connection.');
      });

      test('returns contextual message for sync_data_SYNC_FAILED', () {
        final message = ErrorContextualizer.getContextualMessage(
          'SYNC_FAILED',
          'sync_data',
        );
        expect(message, 'Sync failed. Please pull to refresh.');
      });

      test('returns contextual message for delete_client_FORBIDDEN', () {
        final message = ErrorContextualizer.getContextualMessage(
          'FORBIDDEN',
          'delete_client',
        );
        expect(message, 'You don\'t have permission to delete clients.');
      });

      test('returns contextual message for delete_client_NETWORK_ERROR', () {
        final message = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'delete_client',
        );
        expect(message, 'Unable to delete client. Please check your connection.');
      });
    });

    group('getContextualMessage - Generic Fallback', () {
      test('returns generic contextual message for TOKEN_EXPIRED with login', () {
        final message = ErrorContextualizer.getContextualMessage(
          'TOKEN_EXPIRED',
          'login',
        );
        // Falls back to generic contextual message
        expect(message, isNotNull);
        expect(message, contains('sign in'));
      });

      test('returns generic contextual message for VALIDATION_ERROR with unknown action', () {
        final message = ErrorContextualizer.getContextualMessage(
          'VALIDATION_ERROR',
          'unknown_action',
        );
        // Falls back to generic contextual message
        expect(message, isNotNull);
        expect(message, contains('complete this action'));
      });

      test('returns generic contextual message for NETWORK_ERROR with unknown action', () {
        final message = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'unknown_action',
        );
        // Falls back to generic contextual message
        expect(message, isNotNull);
        expect(message, contains('connection'));
      });

      test('returns generic contextual message for FORBIDDEN with unknown action', () {
        final message = ErrorContextualizer.getContextualMessage(
          'FORBIDDEN',
          'unknown_action',
        );
        // Falls back to generic contextual message
        expect(message, isNotNull);
        expect(message, contains('permission'));
      });

      test('returns generic contextual message for unknown error with known action', () {
        final message = ErrorContextualizer.getContextualMessage(
          'UNKNOWN_ERROR',
          'login',
        );
        // Falls back to generic contextual message
        expect(message, isNotNull);
        expect(message, contains('sign in'));
      });
    });

    group('Integration Tests', () {
      test('all defined contextual messages are non-null', () {
        final definedMappings = [
          ('INVALID_CREDENTIALS', 'login'),
          ('NETWORK_ERROR', 'login'),
          ('RATE_LIMIT_EXCEEDED', 'login'),
          ('VALIDATION_ERROR', 'save_client'),
          ('NETWORK_ERROR', 'save_client'),
          ('CLIENT_ALREADY_ASSIGNED', 'save_client'),
          ('VALIDATION_ERROR', 'submit_touchpoint'),
          ('INVALID_TOUCHPOINT_TYPE', 'submit_touchpoint'),
          ('NETWORK_ERROR', 'submit_touchpoint'),
          ('FILE_TOO_LARGE', 'upload_file'),
          ('NETWORK_ERROR', 'sync_data'),
          ('SYNC_FAILED', 'sync_data'),
          ('FORBIDDEN', 'delete_client'),
          ('NETWORK_ERROR', 'delete_client'),
        ];

        for (final entry in definedMappings) {
          final message = ErrorContextualizer.getContextualMessage(
            entry.$1,
            entry.$2,
          );
          expect(
            message,
            isNotNull,
            reason: '${entry.$2}_${entry.$1} should return a message',
          );
        }
      });

      test('handles all error codes without throwing exceptions', () {
        final errorCodes = [
          'INVALID_CREDENTIALS',
          'TOKEN_EXPIRED',
          'NETWORK_ERROR',
          'VALIDATION_ERROR',
          'FORBIDDEN',
          'NOT_FOUND',
          'INTERNAL_SERVER_ERROR',
          'RATE_LIMIT_EXCEEDED',
          'FILE_TOO_LARGE',
          'SYNC_FAILED',
          'UNKNOWN_ERROR',
        ];

        final actions = [
          'login',
          'save_client',
          'submit_touchpoint',
          'sync_data',
          'delete_client',
          'unknown_action',
        ];

        for (final errorCode in errorCodes) {
          for (final action in actions) {
            expect(
              () => ErrorContextualizer.getContextualMessage(errorCode, action),
              returnsNormally,
              reason: 'Should not throw for $errorCode during $action',
            );
          }
        }
      });

      test('returns consistent results for repeated calls', () {
        final message1 = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'login',
        );
        final message2 = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'login',
        );
        final message3 = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'login',
        );

        expect(message1, equals(message2));
        expect(message2, equals(message3));
      });
    });

    group('Edge Cases', () {
      test('handles empty strings', () {
        final message = ErrorContextualizer.getContextualMessage('', '');
        expect(message, isNotNull);
      });

      test('handles special characters in action', () {
        final message = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'save-client',
        );
        expect(message, isNotNull);
      });

      test('handles very long action names', () {
        final longAction = 'a' * 1000;
        final message = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          longAction,
        );
        expect(message, isNotNull);
      });

      test('is case-sensitive for action names', () {
        final message1 = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'login',
        );
        final message2 = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'LOGIN',
        );

        // Exact match returns specific message
        expect(message1, contains('sign in'));
        // Case mismatch falls back to generic
        expect(message2, isNot(equals(message1)));
      });

      test('is case-sensitive for error codes', () {
        final message1 = ErrorContextualizer.getContextualMessage(
          'NETWORK_ERROR',
          'login',
        );
        final message2 = ErrorContextualizer.getContextualMessage(
          'network_error',
          'login',
        );

        // Exact match returns specific message
        expect(message1, contains('internet'));
        // Case mismatch falls back to generic
        expect(message2, isNot(equals(message1)));
      });
    });
  });
}
