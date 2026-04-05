import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/field_error_message_mapper.dart';

void main() {
  group('FieldErrorMessageMapper', () {
    group('getFieldLabel', () {
      test('returns mapped label for known fields', () {
        expect(FieldErrorMessageMapper.getFieldLabel('first_name'), 'First name');
        expect(FieldErrorMessageMapper.getFieldLabel('email'), 'Email address');
        expect(FieldErrorMessageMapper.getFieldLabel('phone_number'), 'Phone number');
        expect(FieldErrorMessageMapper.getFieldLabel('password'), 'Password');
      });

      test('generates label for unknown snake_case fields', () {
        expect(FieldErrorMessageMapper.getFieldLabel('user_name'), 'User Name');
        expect(FieldErrorMessageMapper.getFieldLabel('address_line1'), 'Address Line1');
        expect(FieldErrorMessageMapper.getFieldLabel('city_municipality'), 'City/Municipality');
      });

      test('handles empty field name', () {
        expect(FieldErrorMessageMapper.getFieldLabel(''), 'Field');
      });

      test('handles single-character field name', () {
        expect(FieldErrorMessageMapper.getFieldLabel('x'), 'X');
        expect(FieldErrorMessageMapper.getFieldLabel('id'), 'Id');
      });

      test('preserves all-caps acronyms', () {
        expect(FieldErrorMessageMapper.getFieldLabel('api_key'), 'Api Key');
        expect(FieldErrorMessageMapper.getFieldLabel('faq_url'), 'FAQ Url');
        expect(FieldErrorMessageMapper.getFieldLabel('id_field'), 'Id Field');
      });

      test('handles numbers in field names', () {
        expect(FieldErrorMessageMapper.getFieldLabel('address2'), 'Address2');
        expect(FieldErrorMessageMapper.getFieldLabel('phone_2fa_backup'), 'Phone 2fa Backup');
      });

      test('handles mixed case field names', () {
        expect(FieldErrorMessageMapper.getFieldLabel('userID'), 'Userid');
        expect(FieldErrorMessageMapper.getFieldLabel('XMLParser'), 'Xmlparser');
      });
    });

    group('getValidationMessage', () {
      test('returns specific message for known field-error combinations', () {
        expect(
          FieldErrorMessageMapper.getValidationMessage('email', 'required'),
          'Please enter your email address',
        );
        expect(
          FieldErrorMessageMapper.getValidationMessage('email', 'invalid'),
          'Please enter a valid email address (e.g., user@example.com)',
        );
        expect(
          FieldErrorMessageMapper.getValidationMessage('password', 'too_short'),
          'Password must be at least 8 characters',
        );
      });

      test('returns default message for unknown field-error combinations', () {
        expect(
          FieldErrorMessageMapper.getValidationMessage('custom_field', 'required'),
          'Please enter your Custom Field',
        );
        expect(
          FieldErrorMessageMapper.getValidationMessage('custom_field', 'invalid'),
          'Please enter a valid Custom Field',
        );
        expect(
          FieldErrorMessageMapper.getValidationMessage('custom_field', 'too_short'),
          'Custom Field is too short',
        );
      });

      test('handles edge cases in validation messages', () {
        // Single-character field name
        expect(
          FieldErrorMessageMapper.getValidationMessage('x', 'required'),
          'Please enter your X',
        );

        // Field with numbers
        expect(
          FieldErrorMessageMapper.getValidationMessage('field2', 'required'),
          'Please enter your Field2',
        );

        // All-caps field name
        expect(
          FieldErrorMessageMapper.getValidationMessage('ID', 'required'),
          'Please enter your ID',
        );
      });
    });

    group('Edge Cases', () {
      test('handles special characters in field names', () {
        expect(FieldErrorMessageMapper.getFieldLabel('field_name'), 'Field Name');
        expect(FieldErrorMessageMapper.getFieldLabel('field-name'), 'Field-name');
      });

      test('handles multiple underscores', () {
        expect(FieldErrorMessageMapper.getFieldLabel('first_name_last'), 'First Name Last');
      });

      test('handles leading/trailing underscores', () {
        expect(FieldErrorMessageMapper.getFieldLabel('_private_field'), ' Private Field');
        expect(FieldErrorMessageMapper.getFieldLabel('public_field_'), 'Public Field ');
      });

      test('handles consecutive underscores', () {
        expect(FieldErrorMessageMapper.getFieldLabel('field__name'), 'Field  Name');
      });
    });

    group('Integration', () {
      test('all common validation errors return user-friendly messages', () {
        final validationErrors = [
          'required', 'invalid', 'too_short', 'too_long', 'format'
        ];

        for (final errorCode in validationErrors) {
          final message = FieldErrorMessageMapper.getValidationMessage('email', errorCode);
          expect(message, isNotEmpty, reason: 'Should return message for $errorCode');
          expect(message.contains('Exception'), isFalse, reason: 'Should not contain technical jargon');
        }
      });

      test('all field labels are non-empty and user-friendly', () {
        final fields = [
          'first_name', 'last_name', 'email', 'phone_number', 'password',
          'street', 'barangay', 'city_municipality', 'province', 'zip_code',
          'client_type', 'product_type', 'market_type', 'pension_type',
          'touchpoint_number', 'touchpoint_type', 'reason', 'status',
          'agency_name', 'agency_code', 'contact_person', 'contact_number',
          'role', 'area', 'name', 'description', 'address', 'id', 'api_key',
        ];

        for (final field in fields) {
          final label = FieldErrorMessageMapper.getFieldLabel(field);
          expect(label, isNotEmpty, reason: 'Should return label for $field');
        }
      });
    });
  });
}
