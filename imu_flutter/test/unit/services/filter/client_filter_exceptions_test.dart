// test/unit/services/filter/client_filter_exceptions_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/filter/client_filter_exceptions.dart';

void main() {
  group('ClientFilterExceptions', () {
    group('PowerSyncUnavailableException', () {
      test('toString returns formatted message without original error', () {
        final exception = PowerSyncUnavailableException('Database not initialized');

        expect(
          exception.toString(),
          'PowerSyncUnavailableException: Database not initialized',
        );
      });

      test('toString includes original error when provided', () {
        final originalError = Exception('Connection failed');
        final exception = PowerSyncUnavailableException(
          'Database not initialized',
          originalError,
        );

        expect(
          exception.toString(),
          'PowerSyncUnavailableException: Database not initialized (caused by: Exception: Connection failed)',
        );
      });

      test('implements Exception interface', () {
        final exception = PowerSyncUnavailableException('Test');
        expect(exception, isA<Exception>());
      });
    });

    group('FilterOptionsLoadException', () {
      test('toString returns formatted message without original error', () {
        final exception = FilterOptionsLoadException('API request failed');

        expect(
          exception.toString(),
          'FilterOptionsLoadException: API request failed',
        );
      });

      test('toString includes original error when provided', () {
        final originalError = Exception('Network error');
        final exception = FilterOptionsLoadException(
          'Failed to load options',
          originalError,
        );

        expect(
          exception.toString(),
          'FilterOptionsLoadException: Failed to load options (caused by: Exception: Network error)',
        );
      });

      test('implements Exception interface', () {
        final exception = FilterOptionsLoadException('Test');
        expect(exception, isA<Exception>());
      });
    });

    group('InvalidFilterValueException', () {
      test('toString returns formatted message without extra details', () {
        final exception = InvalidFilterValueException('Invalid enum value');

        expect(
          exception.toString(),
          'InvalidFilterValueException: Invalid enum value',
        );
      });

      test('toString includes filter type when provided', () {
        final exception = InvalidFilterValueException(
          'Invalid enum value',
          filterType: 'client_type',
        );

        expect(
          exception.toString(),
          'InvalidFilterValueException: Invalid enum value (filter: client_type)',
        );
      });

      test('toString includes invalid value when provided', () {
        final exception = InvalidFilterValueException(
          'Invalid enum value',
          invalidValue: 'INVALID_TYPE',
        );

        expect(
          exception.toString(),
          'InvalidFilterValueException: Invalid enum value (value: INVALID_TYPE)',
        );
      });

      test('toString includes both filter type and invalid value', () {
        final exception = InvalidFilterValueException(
          'Invalid enum value',
          filterType: 'market_type',
          invalidValue: 'URBAN',
        );

        expect(
          exception.toString(),
          'InvalidFilterValueException: Invalid enum value (filter: market_type) (value: URBAN)',
        );
      });

      test('implements Exception interface', () {
        final exception = InvalidFilterValueException('Test');
        expect(exception, isA<Exception>());
      });
    });
  });
}
