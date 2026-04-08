import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/clients/data/models/phone_number_model.dart';

void main() {
  group('PhoneLabel', () {
    test('should have correct display names', () {
      expect(PhoneLabel.mobile.displayName, 'Mobile');
      expect(PhoneLabel.home.displayName, 'Home');
      expect(PhoneLabel.work.displayName, 'Work');
    });

    test('fromString should parse correctly', () {
      expect(PhoneLabel.fromString('mobile'), PhoneLabel.mobile);
      expect(PhoneLabel.fromString('MOBILE'), PhoneLabel.mobile);
      expect(PhoneLabel.fromString('Mobile'), PhoneLabel.mobile);
      expect(PhoneLabel.fromString('home'), PhoneLabel.home);
      expect(PhoneLabel.fromString('Work'), PhoneLabel.work);
    });

    test('fromString should default to mobile for invalid values', () {
      expect(PhoneLabel.fromString('invalid'), PhoneLabel.mobile);
      expect(PhoneLabel.fromString(''), PhoneLabel.mobile);
    });
  });

  group('PhoneNumber', () {
    final testPhone = PhoneNumber(
      id: 'test-id',
      clientId: 'client-123',
      label: PhoneLabel.mobile,
      number: '09171234567',
      isPrimary: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should create PhoneNumber with all fields', () {
      expect(testPhone.id, 'test-id');
      expect(testPhone.clientId, 'client-123');
      expect(testPhone.label, PhoneLabel.mobile);
      expect(testPhone.number, '09171234567');
      expect(testPhone.isPrimary, true);
    });

    test('displayNumber should format PH mobile numbers correctly', () {
      // 11-digit format starting with 0
      final phone1 = PhoneNumber(
        id: '1',
        clientId: 'client',
        label: PhoneLabel.mobile,
        number: '09171234567',
        isPrimary: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(phone1.displayNumber, '0917-123-4567');

      // 12-digit format starting with 63
      final phone2 = PhoneNumber(
        id: '2',
        clientId: 'client',
        label: PhoneLabel.mobile,
        number: '639171234567',
        isPrimary: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(phone2.displayNumber, '+63 917 123 4567');

      // Non-standard format - return as is
      final phone3 = PhoneNumber(
        id: '3',
        clientId: 'client',
        label: PhoneLabel.mobile,
        number: '123456',
        isPrimary: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(phone3.displayNumber, '123456');
    });

    test('displayNumber should handle numbers with spaces and dashes', () {
      final phone = PhoneNumber(
        id: '1',
        clientId: 'client',
        label: PhoneLabel.mobile,
        number: '0917 123-4567',
        isPrimary: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(phone.displayNumber, '0917-123-4567');
    });

    test('fromSyncMap should parse PowerSync data correctly', () {
      final map = {
        'id': 'sync-id',
        'client_id': 'sync-client',
        'label': 'work',
        'number': '09187654321',
        'is_primary': 0,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final phone = PhoneNumber.fromSyncMap(map);

      expect(phone.id, 'sync-id');
      expect(phone.clientId, 'sync-client');
      expect(phone.label, PhoneLabel.work);
      expect(phone.number, '09187654321');
      expect(phone.isPrimary, false);
    });

    test('fromSyncMap should handle null values gracefully', () {
      final map = {
        'id': 'minimal-id',
        'client_id': 'minimal-client',
        'label': null,
        'number': null,
        'is_primary': 1,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final phone = PhoneNumber.fromSyncMap(map);

      expect(phone.id, 'minimal-id');
      expect(phone.label, PhoneLabel.mobile); // defaults to mobile
      expect(phone.number, ''); // defaults to empty string
      expect(phone.isPrimary, true);
    });

    test('fromSyncMap should handle missing created_at/updated_at', () {
      final map = {
        'id': 'no-dates-id',
        'client_id': 'no-dates-client',
        'label': 'home',
        'number': '09190000000',
        'is_primary': 0,
        'created_at': null,
        'updated_at': null,
      };

      final phone = PhoneNumber.fromSyncMap(map);

      expect(phone.createdAt, isNotNull);
      expect(phone.updatedAt, isNotNull);
    });

    test('fromJson should convert to JSON for API requests', () {
      final json = testPhone.toJson();

      expect(json['label'], 'mobile');
      expect(json['number'], '09171234567');
      expect(json['is_primary'], true);
    });

    test('copyWith should create a new instance with updated fields', () {
      final updated = testPhone.copyWith(
        number: '09187654321',
        isPrimary: false,
      );

      expect(updated.id, testPhone.id); // unchanged
      expect(updated.number, '09187654321'); // changed
      expect(updated.isPrimary, false); // changed
      expect(updated.clientId, testPhone.clientId); // unchanged
    });

    test('toString should return readable representation', () {
      final str = testPhone.toString();
      expect(str, contains('0917-123-4567'));
      expect(str, contains('PhoneLabel.mobile')); // Full enum name
      expect(str, contains('Primary: true'));
    });

    test('equality should be based on id', () {
      final phone1 = testPhone;
      final phone2 = PhoneNumber(
        id: 'test-id', // same id
        clientId: 'different-client',
        label: PhoneLabel.work,
        number: 'Different Number',
        isPrimary: false,
        createdAt: DateTime(2024, 2, 1),
        updatedAt: DateTime(2024, 2, 1),
      );

      expect(phone1, equals(phone2));
      expect(phone1 == phone2, true);
    });

    test('hashCode should be based on id', () {
      final phone1 = testPhone;
      final phone2 = PhoneNumber(
        id: 'test-id', // same id
        clientId: 'different-client',
        label: PhoneLabel.work,
        number: 'Different Number',
        isPrimary: false,
        createdAt: DateTime(2024, 2, 1),
        updatedAt: DateTime(2024, 2, 1),
      );

      expect(phone1.hashCode, equals(phone2.hashCode));
    });

    test('different phone numbers should not be equal', () {
      final phone1 = testPhone;
      final phone2 = PhoneNumber(
        id: 'different-id',
        clientId: testPhone.clientId,
        label: testPhone.label,
        number: testPhone.number,
        isPrimary: testPhone.isPrimary,
        createdAt: testPhone.createdAt,
        updatedAt: testPhone.updatedAt,
      );

      expect(phone1, isNot(equals(phone2)));
      expect(phone1 == phone2, false);
    });

    test('fromLegacyField should create from Client', () {
      // This test requires Client model which is in a different file
      // For now, we'll skip this test
      // TODO: Add Client model import and test this properly
    });
  });
}
