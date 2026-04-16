import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Time ISO 8601 format', () {
    String formatTimeOfDay(TimeOfDay time) {
      // Create DateTime with today's date and the TimeOfDay time
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      // Return ISO 8601 format string (backend expects this format)
      return dateTime.toIso8601String();
    }

    test('9:00 AM should format to ISO 8601', () {
      final time = TimeOfDay(hour: 9, minute: 0);
      final formatted = formatTimeOfDay(time);

      // Should be in ISO 8601 format: YYYY-MM-DDTHH:MM:SS.mmmmmm
      expect(formatted, contains('T09:00:00'));
      expect(formatted, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T09:00:00')));

      print('✅ 9:00 AM -> $formatted');
    });

    test('3:46 PM should format to ISO 8601', () {
      final time = TimeOfDay(hour: 15, minute: 46);
      final formatted = formatTimeOfDay(time);

      // Should be in ISO 8601 format: YYYY-MM-DDTHH:MM:SS.mmmmmm
      expect(formatted, contains('T15:46:00'));
      expect(formatted, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T15:46:00')));

      print('✅ 3:46 PM -> $formatted');
    });

    test('11:57 PM should format to ISO 8601', () {
      final time = TimeOfDay(hour: 23, minute: 57);
      final formatted = formatTimeOfDay(time);

      // Should be in ISO 8601 format: YYYY-MM-DDTHH:MM:SS.mmmmmm
      expect(formatted, contains('T23:57:00'));
      expect(formatted, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T23:57:00')));

      print('✅ 11:57 PM -> $formatted');
    });

    test('ISO 8601 string can be parsed back to DateTime', () {
      final time = TimeOfDay(hour: 14, minute: 30);
      final formatted = formatTimeOfDay(time);

      // Parse the ISO 8601 string back to DateTime
      final parsed = DateTime.parse(formatted);

      expect(parsed.hour, equals(14));
      expect(parsed.minute, equals(30));
      expect(parsed.second, equals(0));

      print('✅ ISO 8601 round-trip: $formatted -> ${parsed.hour}:${parsed.minute}');
    });
  });
}
