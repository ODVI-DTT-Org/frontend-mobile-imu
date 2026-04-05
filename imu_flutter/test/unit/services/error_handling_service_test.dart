import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/error_handling_service.dart';
import 'package:imu_flutter/services/api/api_exception.dart';

void main() {
  group('ErrorHandlingService', () {
    group('handleError', () {
      test('creates AppError from ApiException', () {
        final service = ErrorHandlingService();

        final apiException = ApiException.networkError();
        service.handleError(apiException);

        expect(service.state, isNotNull);
        expect(service.state!.message, contains('internet'));
        expect(service.state!.code, 'NETWORK_ERROR');
        expect(service.state!.severity, ErrorSeverity.error);
      });

      test('creates AppError from generic exception', () {
        final service = ErrorHandlingService();

        final exception = Exception('Generic error');
        service.handleError(exception);

        expect(service.state, isNotNull);
        expect(service.state!.message, 'Exception: Generic error');
        expect(service.state!.severity, ErrorSeverity.error);
      });

      test('sets severity to critical for 500+ status codes', () {
        final service = ErrorHandlingService();

        final apiException = ApiException.serverError();
        service.handleError(apiException);

        expect(service.state, isNotNull);
        expect(service.state!.severity, ErrorSeverity.critical);
      });

      test('sets severity to error for 4xx status codes', () {
        final service = ErrorHandlingService();

        final apiException = ApiException.unauthorized();
        service.handleError(apiException);

        expect(service.state, isNotNull);
        expect(service.state!.severity, ErrorSeverity.error);
      });

      test('sets severity to error for network errors (status code 0)', () {
        final service = ErrorHandlingService();

        final apiException = ApiException.networkError();
        service.handleError(apiException);

        expect(service.state, isNotNull);
        expect(service.state!.severity, ErrorSeverity.error);
      });

      test('updates state with new error when called multiple times', () {
        final service = ErrorHandlingService();

        service.handleError(ApiException.networkError());
        final firstError = service.state;
        expect(firstError!.code, 'NETWORK_ERROR');

        service.handleError(ApiException.timeoutError());
        final secondError = service.state;
        expect(secondError!.code, 'TIMEOUT');
        expect(secondError, isNot(equals(firstError)));
      });

      test('includes timestamp in AppError', () {
        final service = ErrorHandlingService();

        final before = DateTime.now();
        service.handleError(ApiException.networkError());
        final after = DateTime.now();

        expect(service.state, isNotNull);
        expect(
          service.state!.timestamp.isAfter(before.subtract(const Duration(seconds: 1))) ||
              service.state!.timestamp.isAtSameMomentAs(before),
          true,
        );
        expect(
          service.state!.timestamp.isBefore(after.add(const Duration(seconds: 1))) ||
              service.state!.timestamp.isAtSameMomentAs(after),
          true,
        );
      });

      test('stores original error in AppError', () {
        final service = ErrorHandlingService();

        final originalError = ApiException.networkError();
        service.handleError(originalError);

        expect(service.state, isNotNull);
        expect(service.state!.originalError, equals(originalError));
      });
    });

    group('clearError', () {
      test('sets state to null when error exists', () {
        final service = ErrorHandlingService();

        service.handleError(ApiException.networkError());
        expect(service.state, isNotNull);

        service.clearError();
        expect(service.state, isNull);
      });

      test('sets state to null when no error exists', () {
        final service = ErrorHandlingService();

        expect(service.state, isNull);
        service.clearError();
        expect(service.state, isNull);
      });

      test('can set new error after clearing', () {
        final service = ErrorHandlingService();

        service.handleError(ApiException.networkError());
        service.clearError();
        expect(service.state, isNull);

        service.handleError(ApiException.timeoutError());
        expect(service.state, isNotNull);
        expect(service.state!.code, 'TIMEOUT');
      });
    });

    group('getUserMessage', () {
      test('returns mapped message for ApiException with error code', () {
        final service = ErrorHandlingService();

        final apiException = ApiException.networkError();
        final message = service.getUserMessage(apiException);

        expect(message, contains('internet'));
      });

      test('returns contextual message when userAction is provided', () {
        final service = ErrorHandlingService();

        final apiException = ApiException.networkError();
        final message = service.getUserMessage(
          apiException,
          userAction: 'login',
        );

        expect(message, contains('sign in'));
        expect(message, contains('internet'));
      });

      test('returns fallback message for ApiException without error code', () {
        final service = ErrorHandlingService();

        final apiException = ApiException(
          message: 'Custom error',
          statusCode: 500,
        );
        final message = service.getUserMessage(apiException);

        expect(message, 'An unexpected error occurred. Please try again.');
      });

      test('returns fallback message for non-ApiException errors', () {
        final service = ErrorHandlingService();

        final exception = Exception('Generic error');
        final message = service.getUserMessage(exception);

        expect(message, 'An unexpected error occurred. Please try again.');
      });

      test('uses contextualizer for known action-error combinations', () {
        final service = ErrorHandlingService();

        final apiException = ApiException(
          message: 'Invalid credentials',
          errorCode: 'INVALID_CREDENTIALS',
          statusCode: 401,
        );
        final message = service.getUserMessage(
          apiException,
          userAction: 'login',
        );

        expect(message, contains('Invalid email or password'));
      });

      test('falls back to generic contextual message when contextualizer returns generic', () {
        final service = ErrorHandlingService();

        final apiException = ApiException.networkError();
        final message = service.getUserMessage(
          apiException,
          userAction: 'unknown_action',
        );

        // Contextualizer returns generic message for unknown actions
        expect(message, isNotNull);
        expect(message, contains('complete this action'));
        expect(message, contains('connection'));
      });
    });

    group('getErrorSuggestions', () {
      test('returns suggestions for ApiException with error code', () {
        final service = ErrorHandlingService();

        final apiException = ApiException.networkError();
        final suggestions = service.getErrorSuggestions(apiException);

        expect(suggestions, isNotEmpty);
        expect(suggestions, anyElement(contains('mobile data')));
        expect(suggestions, anyElement(contains('Wi-Fi')));
      });

      test('returns empty list for ApiException without error code', () {
        final service = ErrorHandlingService();

        final apiException = ApiException(
          message: 'Custom error',
          statusCode: 500,
        );
        final suggestions = service.getErrorSuggestions(apiException);

        expect(suggestions, isEmpty);
      });

      test('returns empty list for non-ApiException errors', () {
        final service = ErrorHandlingService();

        final exception = Exception('Generic error');
        final suggestions = service.getErrorSuggestions(exception);

        expect(suggestions, isEmpty);
      });

      test('returns suggestions for VALIDATION_ERROR', () {
        final service = ErrorHandlingService();

        final apiException = ApiException.validationError({});
        final suggestions = service.getErrorSuggestions(apiException);

        expect(suggestions, isNotEmpty);
        expect(suggestions, anyElement(contains('required fields')));
      });

      test('returns suggestions for INVALID_CREDENTIALS', () {
        final service = ErrorHandlingService();

        final apiException = ApiException(
          message: 'Invalid credentials',
          errorCode: 'INVALID_CREDENTIALS',
          statusCode: 401,
        );
        final suggestions = service.getErrorSuggestions(apiException);

        expect(suggestions, isNotEmpty);
        expect(suggestions, anyElement(contains('email')));
      });
    });

    group('getErrorSeverity', () {
      test('returns critical for 500 status code', () {
        final severity = ErrorHandlingService.getErrorSeverity(
          ApiException.serverError(),
        );
        expect(severity, ErrorSeverity.critical);
      });

      test('returns critical for 503 status code', () {
        final apiException = ApiException(
          message: 'Service unavailable',
          statusCode: 503,
          errorCode: 'SERVICE_UNAVAILABLE',
        );
        final severity = ErrorHandlingService.getErrorSeverity(apiException);
        expect(severity, ErrorSeverity.critical);
      });

      test('returns error for 400 status code', () {
        final severity = ErrorHandlingService.getErrorSeverity(
          ApiException.validationError({}),
        );
        expect(severity, ErrorSeverity.error);
      });

      test('returns error for 401 status code', () {
        final severity = ErrorHandlingService.getErrorSeverity(
          ApiException.unauthorized(),
        );
        expect(severity, ErrorSeverity.error);
      });

      test('returns error for 403 status code', () {
        final severity = ErrorHandlingService.getErrorSeverity(
          ApiException.forbidden(),
        );
        expect(severity, ErrorSeverity.error);
      });

      test('returns error for 404 status code', () {
        final severity = ErrorHandlingService.getErrorSeverity(
          ApiException.notFound(),
        );
        expect(severity, ErrorSeverity.error);
      });

      test('returns error for network errors (status code 0)', () {
        final severity = ErrorHandlingService.getErrorSeverity(
          ApiException.networkError(),
        );
        expect(severity, ErrorSeverity.error);
      });

      test('returns error for non-ApiException errors', () {
        final severity = ErrorHandlingService.getErrorSeverity(
          Exception('Generic error'),
        );
        expect(severity, ErrorSeverity.error);
      });

      test('returns error for ApiException without status code', () {
        final apiException = ApiException(
          message: 'Custom error',
        );
        final severity = ErrorHandlingService.getErrorSeverity(apiException);
        expect(severity, ErrorSeverity.error);
      });
    });

    group('AppError factory', () {
      test('creates AppError from ApiException with all fields', () {
        final apiException = ApiException.networkError();

        final appError = AppError.fromException(apiException);

        expect(appError.message, contains('internet'));
        expect(appError.code, 'NETWORK_ERROR');
        expect(appError.severity, ErrorSeverity.error);
        expect(appError.originalError, equals(apiException));
        expect(appError.timestamp, isNotNull);
        expect(appError.stackTrace, isNull);
      });

      test('creates AppError from generic exception', () {
        final exception = Exception('Generic error');

        final appError = AppError.fromException(exception);

        expect(appError.message, 'Exception: Generic error');
        expect(appError.code, isNull);
        expect(appError.severity, ErrorSeverity.error);
        expect(appError.originalError, equals(exception));
        expect(appError.timestamp, isNotNull);
      });

      test('sets critical severity for 500+ errors', () {
        final apiException = ApiException.serverError();

        final appError = AppError.fromException(apiException);

        expect(appError.severity, ErrorSeverity.critical);
      });

      test('sets error severity for 4xx errors', () {
        final apiException = ApiException.unauthorized();

        final appError = AppError.fromException(apiException);

        expect(appError.severity, ErrorSeverity.error);
      });
    });

    group('StateNotifier integration', () {
      test('notifies listeners when error is set', () {
        final service = ErrorHandlingService();

        var notified = false;
        final listener = service.addListener((_) {
          notified = true;
        });

        service.handleError(ApiException.networkError());

        expect(notified, true);
        listener(); // Remove listener
      });

      test('notifies listeners when error is cleared', () {
        final service = ErrorHandlingService();
        service.handleError(ApiException.networkError());

        var notified = false;
        final listener = service.addListener((_) {
          notified = true;
        });

        service.clearError();

        expect(notified, true);
        listener(); // Remove listener
      });

      test('notifies listeners when error changes', () {
        final service = ErrorHandlingService();
        service.handleError(ApiException.networkError());

        var notified = false;
        final listener = service.addListener((_) {
          notified = true;
        });

        service.handleError(ApiException.timeoutError());

        expect(notified, true);
        listener(); // Remove listener
      });
    });

    group('Integration with ErrorMessageMapper', () {
      test('all error codes return user-friendly messages', () {
        final service = ErrorHandlingService();

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
        ];

        for (final errorCode in errorCodes) {
          final apiException = ApiException(
            message: 'Test error',
            errorCode: errorCode,
          );
          final message = service.getUserMessage(apiException);

          expect(
            message,
            isNotEmpty,
            reason: 'Should return message for $errorCode',
          );
          expect(
            message,
            isNot(contains('Test error')),
            reason: 'Should use mapped message for $errorCode',
          );
        }
      });

      test('all error codes return suggestions', () {
        final service = ErrorHandlingService();

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
        ];

        for (final errorCode in errorCodes) {
          final apiException = ApiException(
            message: 'Test error',
            errorCode: errorCode,
          );
          final suggestions = service.getErrorSuggestions(apiException);

          expect(
            suggestions,
            isNotEmpty,
            reason: 'Should return suggestions for $errorCode',
          );
        }
      });
    });

    group('Edge Cases', () {
      test('handles null error gracefully in getUserMessage', () {
        final service = ErrorHandlingService();

        final message = service.getUserMessage(null);

        expect(message, 'An unexpected error occurred. Please try again.');
      });

      test('handles empty error message in getUserMessage', () {
        final service = ErrorHandlingService();

        final apiException = ApiException(
          message: '',
          errorCode: 'NETWORK_ERROR',
          statusCode: 0,
        );
        final message = service.getUserMessage(apiException);

        expect(message, isNotEmpty);
      });

      test('handles ApiException with null error code', () {
        final service = ErrorHandlingService();

        final apiException = ApiException(
          message: 'Custom error',
          errorCode: null,
        );
        final message = service.getUserMessage(apiException);

        expect(message, 'An unexpected error occurred. Please try again.');
      });

      test('handles special characters in error message', () {
        final service = ErrorHandlingService();

        final apiException = ApiException(
          message: 'Error with special chars: @#\$%^&*()',
          errorCode: null,
        );
        final appError = AppError.fromException(apiException);

        expect(appError.message, contains('@#\$%^&*()'));
      });
    });
  });
}
