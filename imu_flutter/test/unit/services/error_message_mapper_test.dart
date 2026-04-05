import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/error_message_mapper.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  group('ErrorMessageMapper', () {
    group('getTitle', () {
      test('returns correct title for INVALID_CREDENTIALS', () {
        final title = ErrorMessageMapper.getTitle('INVALID_CREDENTIALS');
        expect(title, 'Sign In Failed');
      });

      test('returns correct title for TOKEN_EXPIRED', () {
        final title = ErrorMessageMapper.getTitle('TOKEN_EXPIRED');
        expect(title, 'Session Expired');
      });

      test('returns correct title for NETWORK_ERROR', () {
        final title = ErrorMessageMapper.getTitle('NETWORK_ERROR');
        expect(title, 'No Internet Connection');
      });

      test('returns correct title for VALIDATION_ERROR', () {
        final title = ErrorMessageMapper.getTitle('VALIDATION_ERROR');
        expect(title, 'Invalid Information');
      });

      test('returns correct title for FORBIDDEN', () {
        final title = ErrorMessageMapper.getTitle('FORBIDDEN');
        expect(title, 'Access Denied');
      });

      test('returns correct title for NOT_FOUND', () {
        final title = ErrorMessageMapper.getTitle('NOT_FOUND');
        expect(title, 'Not Found');
      });

      test('returns correct title for INTERNAL_SERVER_ERROR', () {
        final title = ErrorMessageMapper.getTitle('INTERNAL_SERVER_ERROR');
        expect(title, 'Server Error');
      });

      test('returns correct title for RATE_LIMIT_EXCEEDED', () {
        final title = ErrorMessageMapper.getTitle('RATE_LIMIT_EXCEEDED');
        expect(title, 'Too Many Attempts');
      });

      test('returns correct title for FILE_TOO_LARGE', () {
        final title = ErrorMessageMapper.getTitle('FILE_TOO_LARGE');
        expect(title, 'File Too Large');
      });

      test('returns correct title for SYNC_FAILED', () {
        final title = ErrorMessageMapper.getTitle('SYNC_FAILED');
        expect(title, 'Sync Failed');
      });

      test('returns default "Error" for unknown error code', () {
        final title = ErrorMessageMapper.getTitle('UNKNOWN_ERROR_CODE');
        expect(title, 'Error');
      });

      test('returns default "Error" for empty string', () {
        final title = ErrorMessageMapper.getTitle('');
        expect(title, 'Error');
      });
    });

    group('getMessage', () {
      test('returns correct message for INVALID_CREDENTIALS', () {
        final message = ErrorMessageMapper.getMessage('INVALID_CREDENTIALS');
        expect(message, 'Invalid email or password. Please try again.');
      });

      test('returns correct message for TOKEN_EXPIRED', () {
        final message = ErrorMessageMapper.getMessage('TOKEN_EXPIRED');
        expect(message, 'Your session has expired. Please sign in again.');
      });

      test('returns correct message for NETWORK_ERROR', () {
        final message = ErrorMessageMapper.getMessage('NETWORK_ERROR');
        expect(message, 'Please check your internet connection and try again.');
      });

      test('returns correct message for TIMEOUT', () {
        final message = ErrorMessageMapper.getMessage('TIMEOUT');
        expect(message, 'The request took too long. Please try again.');
      });

      test('returns correct message for VALIDATION_ERROR', () {
        final message = ErrorMessageMapper.getMessage('VALIDATION_ERROR');
        expect(message, 'Please check the highlighted fields and try again.');
      });

      test('returns correct message for INVALID_EMAIL', () {
        final message = ErrorMessageMapper.getMessage('INVALID_EMAIL');
        expect(message, 'Please enter a valid email address.');
      });

      test('returns correct message for INVALID_PHONE', () {
        final message = ErrorMessageMapper.getMessage('INVALID_PHONE');
        expect(message, 'Please enter a valid phone number.');
      });

      test('returns correct message for PASSWORD_TOO_WEAK', () {
        final message = ErrorMessageMapper.getMessage('PASSWORD_TOO_WEAK');
        expect(message, 'Your password is too weak.');
      });

      test('returns correct message for FORBIDDEN', () {
        final message = ErrorMessageMapper.getMessage('FORBIDDEN');
        expect(message, 'You don\'t have permission to perform this action.');
      });

      test('returns correct message for INTERNAL_SERVER_ERROR', () {
        final message = ErrorMessageMapper.getMessage('INTERNAL_SERVER_ERROR');
        expect(message, 'Something went wrong on our end. Please try again.');
      });

      test('returns correct message for NOT_FOUND', () {
        final message = ErrorMessageMapper.getMessage('NOT_FOUND');
        expect(message, 'The requested information could not be found.');
      });

      test('returns correct message for CONFLICT', () {
        final message = ErrorMessageMapper.getMessage('CONFLICT');
        expect(message, 'This record already exists.');
      });

      test('returns correct message for DUPLICATE_RECORD', () {
        final message = ErrorMessageMapper.getMessage('DUPLICATE_RECORD');
        expect(message, 'This entry already exists in the system.');
      });

      test('returns correct message for RATE_LIMIT_EXCEEDED', () {
        final message = ErrorMessageMapper.getMessage('RATE_LIMIT_EXCEEDED');
        expect(message, 'You\'ve made too many requests. Please wait a moment.');
      });

      test('returns correct message for FILE_TOO_LARGE', () {
        final message = ErrorMessageMapper.getMessage('FILE_TOO_LARGE');
        expect(message, 'The file is too large. Maximum size is 10MB.');
      });

      test('returns correct message for INVALID_FILE_TYPE', () {
        final message = ErrorMessageMapper.getMessage('INVALID_FILE_TYPE');
        expect(message, 'This file type is not supported.');
      });

      test('returns correct message for SYNC_FAILED', () {
        final message = ErrorMessageMapper.getMessage('SYNC_FAILED');
        expect(message, 'Unable to sync your data. Please try again.');
      });

      test('returns correct message for CONFLICT_DETECTED', () {
        final message = ErrorMessageMapper.getMessage('CONFLICT_DETECTED');
        expect(message, 'Changes conflict with server data.');
      });

      test('returns correct message for INVALID_TOUCHPOINT_TYPE', () {
        final message = ErrorMessageMapper.getMessage('INVALID_TOUCHPOINT_TYPE');
        expect(message, 'You can only create visit touchpoints.');
      });

      test('returns correct message for CLIENT_ALREADY_ASSIGNED', () {
        final message = ErrorMessageMapper.getMessage('CLIENT_ALREADY_ASSIGNED');
        expect(message, 'This client is already assigned to another agent.');
      });

      test('returns fallback message when details contain message', () {
        final message = ErrorMessageMapper.getMessage(
          'UNKNOWN_ERROR',
          details: {'message': 'Custom error from server'},
        );
        expect(message, 'Custom error from server');
      });

      test('simplifies technical error messages', () {
        final message = ErrorMessageMapper.getMessage(
          'UNKNOWN_ERROR',
          details: {'message': 'HttpException: Failed to fetch data'},
        );
        expect(message, 'Failed to fetch data');
      });

      test('removes HTTP status codes from technical messages', () {
        final message = ErrorMessageMapper.getMessage(
          'UNKNOWN_ERROR',
          details: {'message': '500 Internal Server Error occurred'},
        );
        expect(message, 'Internal Server Error occurred');
      });

      test('returns default message for unknown error without details', () {
        final message = ErrorMessageMapper.getMessage('UNKNOWN_ERROR');
        expect(message, 'An unexpected error occurred. Please try again.');
      });

      test('returns default message for unknown error with empty details', () {
        final message = ErrorMessageMapper.getMessage('UNKNOWN_ERROR', details: {});
        expect(message, 'An unexpected error occurred. Please try again.');
      });
    });

    group('getSuggestions', () {
      test('returns suggestions for INVALID_CREDENTIALS', () {
        final suggestions = ErrorMessageMapper.getSuggestions('INVALID_CREDENTIALS');
        expect(suggestions.length, greaterThan(0));
        expect(suggestions, contains('Check your email spelling'));
        expect(suggestions, contains('Reset your password if needed'));
      });

      test('returns suggestions for TOKEN_EXPIRED', () {
        final suggestions = ErrorMessageMapper.getSuggestions('TOKEN_EXPIRED');
        expect(suggestions.length, greaterThan(0));
        expect(suggestions, contains('Your session lasts 24 hours'));
        expect(suggestions, contains('Sign in to continue'));
      });

      test('returns suggestions for NETWORK_ERROR', () {
        final suggestions = ErrorMessageMapper.getSuggestions('NETWORK_ERROR');
        expect(suggestions.length, greaterThan(0));
        expect(suggestions, contains('Turn on mobile data or Wi-Fi'));
        expect(suggestions, contains('Check your signal strength'));
      });

      test('returns suggestions for VALIDATION_ERROR', () {
        final suggestions = ErrorMessageMapper.getSuggestions('VALIDATION_ERROR');
        expect(suggestions.length, greaterThan(0));
        expect(suggestions, contains('All required fields must be filled'));
        expect(suggestions, contains('Check for any formatting errors'));
      });

      test('returns suggestions for INVALID_EMAIL', () {
        final suggestions = ErrorMessageMapper.getSuggestions('INVALID_EMAIL');
        expect(suggestions.length, greaterThan(0));
        expect(suggestions, contains('Example: user@example.com'));
        expect(suggestions, contains('Check for typos'));
      });

      test('returns suggestions for PASSWORD_TOO_WEAK', () {
        final suggestions = ErrorMessageMapper.getSuggestions('PASSWORD_TOO_WEAK');
        expect(suggestions.length, greaterThan(0));
        expect(suggestions, contains('Use at least 8 characters'));
        expect(suggestions, contains('Include numbers and symbols'));
      });

      test('returns suggestions for INTERNAL_SERVER_ERROR', () {
        final suggestions = ErrorMessageMapper.getSuggestions('INTERNAL_SERVER_ERROR');
        expect(suggestions.length, greaterThan(0));
        expect(suggestions, contains('Wait a moment and retry'));
        expect(suggestions, contains('If the problem persists, contact support'));
      });

      test('returns suggestions for RATE_LIMIT_EXCEEDED', () {
        final suggestions = ErrorMessageMapper.getSuggestions('RATE_LIMIT_EXCEEDED');
        expect(suggestions.length, greaterThan(0));
        expect(suggestions, contains('Wait 60 seconds before trying again'));
        expect(suggestions, contains('Don\'t tap the button repeatedly'));
      });

      test('returns suggestions for FILE_TOO_LARGE', () {
        final suggestions = ErrorMessageMapper.getSuggestions('FILE_TOO_LARGE');
        expect(suggestions.length, greaterThan(0));
        expect(suggestions, contains('Choose a smaller file'));
        expect(suggestions, contains('Compress the image before uploading'));
      });

      test('returns suggestions for SYNC_FAILED', () {
        final suggestions = ErrorMessageMapper.getSuggestions('SYNC_FAILED');
        expect(suggestions.length, greaterThan(0));
        expect(suggestions, contains('Check your internet connection'));
        expect(suggestions, contains('Pull to refresh to retry'));
      });

      test('returns empty list for unknown error code', () {
        final suggestions = ErrorMessageMapper.getSuggestions('UNKNOWN_ERROR_CODE');
        expect(suggestions, isEmpty);
      });

      test('returns empty list for empty string', () {
        final suggestions = ErrorMessageMapper.getSuggestions('');
        expect(suggestions, isEmpty);
      });
    });

    group('getIcon', () {
      test('returns lock icon for INVALID_CREDENTIALS', () {
        final icon = ErrorMessageMapper.getIcon('INVALID_CREDENTIALS');
        expect(icon, LucideIcons.lock);
      });

      test('returns clock icon for TOKEN_EXPIRED', () {
        final icon = ErrorMessageMapper.getIcon('TOKEN_EXPIRED');
        expect(icon, LucideIcons.clock);
      });

      test('returns wifiOff icon for NETWORK_ERROR', () {
        final icon = ErrorMessageMapper.getIcon('NETWORK_ERROR');
        expect(icon, LucideIcons.wifiOff);
      });

      test('returns timer icon for TIMEOUT', () {
        final icon = ErrorMessageMapper.getIcon('TIMEOUT');
        expect(icon, LucideIcons.timer);
      });

      test('returns alertCircle icon for VALIDATION_ERROR', () {
        final icon = ErrorMessageMapper.getIcon('VALIDATION_ERROR');
        expect(icon, LucideIcons.alertCircle);
      });

      test('returns shieldAlert icon for FORBIDDEN', () {
        final icon = ErrorMessageMapper.getIcon('FORBIDDEN');
        expect(icon, LucideIcons.shieldAlert);
      });

      test('returns server icon for INTERNAL_SERVER_ERROR', () {
        final icon = ErrorMessageMapper.getIcon('INTERNAL_SERVER_ERROR');
        expect(icon, LucideIcons.server);
      });

      test('returns gauge icon for RATE_LIMIT_EXCEEDED', () {
        final icon = ErrorMessageMapper.getIcon('RATE_LIMIT_EXCEEDED');
        expect(icon, LucideIcons.gauge);
      });

      test('returns file icon for FILE_TOO_LARGE', () {
        final icon = ErrorMessageMapper.getIcon('FILE_TOO_LARGE');
        expect(icon, LucideIcons.file);
      });

      test('returns refreshCw icon for SYNC_FAILED', () {
        final icon = ErrorMessageMapper.getIcon('SYNC_FAILED');
        expect(icon, LucideIcons.refreshCw);
      });

      test('returns default alertCircle icon for unknown error', () {
        final icon = ErrorMessageMapper.getIcon('UNKNOWN_ERROR_CODE');
        expect(icon, LucideIcons.alertCircle);
      });

      test('returns default alertCircle icon for empty string', () {
        final icon = ErrorMessageMapper.getIcon('');
        expect(icon, LucideIcons.alertCircle);
      });
    });

    group('getColor', () {
      test('returns red color for INVALID_CREDENTIALS', () {
        final color = ErrorMessageMapper.getColor('INVALID_CREDENTIALS');
        expect(color, const Color(0xFFEF4444));
      });

      test('returns orange color for TOKEN_EXPIRED', () {
        final color = ErrorMessageMapper.getColor('TOKEN_EXPIRED');
        expect(color, const Color(0xFFF59E0B));
      });

      test('returns blue color for NETWORK_ERROR', () {
        final color = ErrorMessageMapper.getColor('NETWORK_ERROR');
        expect(color, const Color(0xFF3B82F6));
      });

      test('returns blue color for TIMEOUT', () {
        final color = ErrorMessageMapper.getColor('TIMEOUT');
        expect(color, const Color(0xFF3B82F6));
      });

      test('returns amber color for VALIDATION_ERROR', () {
        final color = ErrorMessageMapper.getColor('VALIDATION_ERROR');
        expect(color, const Color(0xFFF59E0B));
      });

      test('returns purple color for FORBIDDEN', () {
        final color = ErrorMessageMapper.getColor('FORBIDDEN');
        expect(color, const Color(0xFF8B5CF6));
      });

      test('returns dark red color for INTERNAL_SERVER_ERROR', () {
        final color = ErrorMessageMapper.getColor('INTERNAL_SERVER_ERROR');
        expect(color, const Color(0xFFDC2626));
      });

      test('returns yellow color for RATE_LIMIT_EXCEEDED', () {
        final color = ErrorMessageMapper.getColor('RATE_LIMIT_EXCEEDED');
        expect(color, const Color(0xFFEAB308));
      });

      test('returns pink color for FILE_TOO_LARGE', () {
        final color = ErrorMessageMapper.getColor('FILE_TOO_LARGE');
        expect(color, const Color(0xFFEC4899));
      });

      test('returns teal color for SYNC_FAILED', () {
        final color = ErrorMessageMapper.getColor('SYNC_FAILED');
        expect(color, const Color(0xFF14B8A6));
      });

      test('returns default red color for unknown error', () {
        final color = ErrorMessageMapper.getColor('UNKNOWN_ERROR_CODE');
        expect(color, Colors.red);
      });

      test('returns default red color for empty string', () {
        final color = ErrorMessageMapper.getColor('');
        expect(color, Colors.red);
      });
    });

    group('Error Categories', () {
      test('all authentication errors have red or orange colors', () {
        final authErrors = [
          'INVALID_CREDENTIALS',
          'TOKEN_EXPIRED',
          'TOKEN_INVALID',
          'UNAUTHORIZED',
        ];

        for (final errorCode in authErrors) {
          final color = ErrorMessageMapper.getColor(errorCode);
          expect(
            color == const Color(0xFFEF4444) || color == const Color(0xFFF59E0B),
            true,
            reason: '$errorCode should have red or orange color',
          );
        }
      });

      test('all network errors have blue color', () {
        final networkErrors = [
          'NETWORK_ERROR',
          'TIMEOUT',
          'CONNECTION_ERROR',
        ];

        for (final errorCode in networkErrors) {
          final color = ErrorMessageMapper.getColor(errorCode);
          expect(color, const Color(0xFF3B82F6),
              reason: '$errorCode should have blue color');
        }
      });

      test('all validation errors have amber color', () {
        final validationErrors = [
          'VALIDATION_ERROR',
          'INVALID_INPUT',
          'INVALID_EMAIL',
          'INVALID_PHONE',
          'PASSWORD_TOO_WEAK',
        ];

        for (final errorCode in validationErrors) {
          final color = ErrorMessageMapper.getColor(errorCode);
          expect(color, const Color(0xFFF59E0B),
              reason: '$errorCode should have amber color');
        }
      });

      test('all server errors have red color', () {
        final serverErrors = [
          'INTERNAL_SERVER_ERROR',
          'SERVICE_UNAVAILABLE',
        ];

        for (final errorCode in serverErrors) {
          final color = ErrorMessageMapper.getColor(errorCode);
          expect(
            color == const Color(0xFFDC2626) ||
                color == const Color(0xFFF87171),
            true,
            reason: '$errorCode should have red color',
          );
        }
      });

      test('all sync errors have teal color', () {
        final syncErrors = [
          'SYNC_FAILED',
          'CONFLICT_DETECTED',
          'SYNC_IN_PROGRESS',
        ];

        for (final errorCode in syncErrors) {
          final color = ErrorMessageMapper.getColor(errorCode);
          expect(
            color == const Color(0xFF14B8A6) ||
                color == const Color(0xFF2DD4BF),
            true,
            reason: '$errorCode should have teal color',
          );
        }
      });
    });

    group('Integration Tests', () {
      test('returns complete error data for VALIDATION_ERROR', () {
        final title = ErrorMessageMapper.getTitle('VALIDATION_ERROR');
        final message = ErrorMessageMapper.getMessage('VALIDATION_ERROR');
        final suggestions = ErrorMessageMapper.getSuggestions('VALIDATION_ERROR');
        final icon = ErrorMessageMapper.getIcon('VALIDATION_ERROR');
        final color = ErrorMessageMapper.getColor('VALIDATION_ERROR');

        expect(title, 'Invalid Information');
        expect(message, 'Please check the highlighted fields and try again.');
        expect(suggestions, isNotEmpty);
        expect(icon, LucideIcons.alertCircle);
        expect(color, const Color(0xFFF59E0B));
      });

      test('returns complete error data for NETWORK_ERROR', () {
        final title = ErrorMessageMapper.getTitle('NETWORK_ERROR');
        final message = ErrorMessageMapper.getMessage('NETWORK_ERROR');
        final suggestions = ErrorMessageMapper.getSuggestions('NETWORK_ERROR');
        final icon = ErrorMessageMapper.getIcon('NETWORK_ERROR');
        final color = ErrorMessageMapper.getColor('NETWORK_ERROR');

        expect(title, 'No Internet Connection');
        expect(message, 'Please check your internet connection and try again.');
        expect(suggestions, isNotEmpty);
        expect(icon, LucideIcons.wifiOff);
        expect(color, const Color(0xFF3B82F6));
      });

      test('returns complete error data for FORBIDDEN', () {
        final title = ErrorMessageMapper.getTitle('FORBIDDEN');
        final message = ErrorMessageMapper.getMessage('FORBIDDEN');
        final suggestions = ErrorMessageMapper.getSuggestions('FORBIDDEN');
        final icon = ErrorMessageMapper.getIcon('FORBIDDEN');
        final color = ErrorMessageMapper.getColor('FORBIDDEN');

        expect(title, 'Access Denied');
        expect(message, 'You don\'t have permission to perform this action.');
        expect(suggestions, isNotEmpty);
        expect(icon, LucideIcons.shieldAlert);
        expect(color, const Color(0xFF8B5CF6));
      });

      test('handles all error codes without throwing exceptions', () {
        final allErrorCodes = [
          // Authentication
          'INVALID_CREDENTIALS',
          'TOKEN_EXPIRED',
          'TOKEN_INVALID',
          'UNAUTHORIZED',
          // Permissions
          'FORBIDDEN',
          'INSUFFICIENT_PERMISSIONS',
          // Validation
          'VALIDATION_ERROR',
          'INVALID_INPUT',
          'INVALID_EMAIL',
          'INVALID_PHONE',
          'PASSWORD_TOO_WEAK',
          // Network
          'NETWORK_ERROR',
          'TIMEOUT',
          'CONNECTION_ERROR',
          // Resources
          'NOT_FOUND',
          'CONFLICT',
          'DUPLICATE_RECORD',
          // Server
          'INTERNAL_SERVER_ERROR',
          'SERVICE_UNAVAILABLE',
          // Rate Limiting
          'RATE_LIMIT_EXCEEDED',
          // File Upload
          'FILE_TOO_LARGE',
          'INVALID_FILE_TYPE',
          // Sync
          'SYNC_FAILED',
          'CONFLICT_DETECTED',
          'SYNC_IN_PROGRESS',
          // Business Logic
          'INVALID_TOUCHPOINT_TYPE',
          'INVALID_STATUS_TRANSITION',
          'CLIENT_ALREADY_ASSIGNED',
        ];

        for (final errorCode in allErrorCodes) {
          expect(
            () => ErrorMessageMapper.getTitle(errorCode),
            returnsNormally,
            reason: 'getTitle should not throw for $errorCode',
          );
          expect(
            () => ErrorMessageMapper.getMessage(errorCode),
            returnsNormally,
            reason: 'getMessage should not throw for $errorCode',
          );
          expect(
            () => ErrorMessageMapper.getSuggestions(errorCode),
            returnsNormally,
            reason: 'getSuggestions should not throw for $errorCode',
          );
          expect(
            () => ErrorMessageMapper.getIcon(errorCode),
            returnsNormally,
            reason: 'getIcon should not throw for $errorCode',
          );
          expect(
            () => ErrorMessageMapper.getColor(errorCode),
            returnsNormally,
            reason: 'getColor should not throw for $errorCode',
          );
        }
      });
    });
  });
}
