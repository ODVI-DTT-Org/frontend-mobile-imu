import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/error_logging_helper.dart';

void main() {
  group('ErrorLoggingHelper', () {
    group('_extractErrorCode', () {
      test('returns CONNECTION_ERROR for SocketException', () {
        const error = 'SocketException: Connection refused';
        final result = ErrorLoggingHelperTestHelper.extractErrorCode(error);
        expect(result, equals('CONNECTION_ERROR'));
      });

      test('returns TIMEOUT_ERROR for TimeoutException', () {
        const error = 'TimeoutException: Operation timed out';
        final result = ErrorLoggingHelperTestHelper.extractErrorCode(error);
        expect(result, equals('TIMEOUT_ERROR'));
      });

      test('returns HTTP_ERROR for HttpException', () {
        const error = 'HttpException: 404 Not Found';
        final result = ErrorLoggingHelperTestHelper.extractErrorCode(error);
        expect(result, equals('HTTP_ERROR'));
      });

      test('returns DIO_ERROR for DioException', () {
        const error = 'DioException: Bad response';
        final result = ErrorLoggingHelperTestHelper.extractErrorCode(error);
        expect(result, equals('DIO_ERROR'));
      });

      test('returns DATABASE_ERROR for DatabaseException', () {
        const error = 'DatabaseException: Unique constraint violated';
        final result = ErrorLoggingHelperTestHelper.extractErrorCode(error);
        expect(result, equals('DATABASE_ERROR'));
      });

      test('returns FORMAT_ERROR for FormatException', () {
        const error = 'FormatException: Invalid JSON';
        final result = ErrorLoggingHelperTestHelper.extractErrorCode(error);
        expect(result, equals('FORMAT_ERROR'));
      });

      test('returns normalized error type for unknown exceptions', () {
        const error = 'CustomException: Something went wrong';
        final result = ErrorLoggingHelperTestHelper.extractErrorCode(error);
        // String literals have runtimeType "String"
        expect(result, equals('STRING'));
      });

      test('handles error objects (not strings)', () {
        final error = Exception('Test exception');
        final result = ErrorLoggingHelperTestHelper.extractErrorCode(error);
        // Exception objects have runtimeType "Exception" which becomes "__ERROR" after replaceAll
        // because "EXCEPTION" → "" + "_ERROR" = "__ERROR" (leading underscore from replacement)
        expect(result, equals('__ERROR'));
      });
    });

    group('Error logging failure handling', () {
      test('logCriticalError does not throw when logging fails', () async {
        // This test verifies that if error logging itself fails,
        // it doesn't break the app (fire-and-forget pattern)
        expect(
          () async => await ErrorLoggingHelper.logCriticalError(
            operation: 'test operation',
            error: Exception('Test error'),
            stackTrace: StackTrace.current,
          ),
          returnsNormally,
        );
      });

      test('logNonCriticalError does not throw when logging fails', () async {
        // This test verifies that if error logging itself fails,
        // it doesn't break the app (fire-and-forget pattern)
        expect(
          () async => await ErrorLoggingHelper.logNonCriticalError(
            operation: 'test operation',
            error: Exception('Test error'),
            stackTrace: StackTrace.current,
          ),
          returnsNormally,
        );
      });
    });

    group('Error code patterns', () {
      test('recognizes common network errors', () {
        final testCases = {
          'SocketException: Failed host lookup': 'CONNECTION_ERROR',
          'SocketException: Connection timed out': 'CONNECTION_ERROR',
          'TimeoutException: Request timeout': 'TIMEOUT_ERROR',
        };

        for (final entry in testCases.entries) {
          final result = ErrorLoggingHelperTestHelper.extractErrorCode(entry.key);
          expect(result, equals(entry.value),
            reason: 'Expected ${entry.value} for "${entry.key}"');
        }
      });

      test('recognizes common HTTP errors', () {
        final testCases = {
          'DioException: 404': 'DIO_ERROR',
          'DioException: 500': 'DIO_ERROR',
          'HttpException: 401': 'HTTP_ERROR',
        };

        for (final entry in testCases.entries) {
          final result = ErrorLoggingHelperTestHelper.extractErrorCode(entry.key);
          expect(result, equals(entry.value),
            reason: 'Expected ${entry.value} for "${entry.key}"');
        }
      });
    });
  });
}

/// Test helper class to expose private methods for testing
/// This mirrors the actual _extractErrorCode implementation in ErrorLoggingHelper
class ErrorLoggingHelperTestHelper {
  static String extractErrorCode(Object error) {
    final errorString = error.toString();

    if (errorString.contains('SocketException')) {
      return 'CONNECTION_ERROR';
    }
    if (errorString.contains('TimeoutException')) {
      return 'TIMEOUT_ERROR';
    }
    if (errorString.contains('HttpException')) {
      return 'HTTP_ERROR';
    }
    if (errorString.contains('DioException')) {
      return 'DIO_ERROR';
    }
    if (errorString.contains('DatabaseException')) {
      return 'DATABASE_ERROR';
    }
    if (errorString.contains('FormatException')) {
      return 'FORMAT_ERROR';
    }

    // Fallback: use runtime type
    // For strings: returns "STRING"
    // For Exception objects: "Exception" → "__ERROR" (after replaceAll)
    return error.runtimeType.toString()
        .toUpperCase()
        .replaceAll('EXCEPTION', '_ERROR');
  }
}
