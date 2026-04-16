import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Time auto-calculation: +5 minutes', () {
    test('9:00 AM should become 9:05 AM', () {
      final timeIn = TimeOfDay(hour: 9, minute: 0);
      final totalMinutes = timeIn.hour * 60 + timeIn.minute;
      final newTotalMinutes = totalMinutes + 5;
      final newHour = (newTotalMinutes ~/ 60) % 24;
      final newMinute = newTotalMinutes % 60;
      final timeOut = TimeOfDay(hour: newHour, minute: newMinute);

      expect(timeOut.hour, equals(9));
      expect(timeOut.minute, equals(5));
      print('✅ 9:00 AM -> 9:05 AM: ${timeOut.hour}:${timeOut.minute}');
    });

    test('11:57 PM should become 12:02 AM', () {
      final timeIn = TimeOfDay(hour: 23, minute: 57);
      final totalMinutes = timeIn.hour * 60 + timeIn.minute;
      final newTotalMinutes = totalMinutes + 5;
      final newHour = (newTotalMinutes ~/ 60) % 24;
      final newMinute = newTotalMinutes % 60;
      final timeOut = TimeOfDay(hour: newHour, minute: newMinute);

      expect(timeOut.hour, equals(0));
      expect(timeOut.minute, equals(2));
      print('✅ 11:57 PM -> 12:02 AM: ${timeOut.hour}:${timeOut.minute}');
    });

    test('1:30 PM should become 1:35 PM', () {
      final timeIn = TimeOfDay(hour: 13, minute: 30);
      final totalMinutes = timeIn.hour * 60 + timeIn.minute;
      final newTotalMinutes = totalMinutes + 5;
      final newHour = (newTotalMinutes ~/ 60) % 24;
      final newMinute = newTotalMinutes % 60;
      final timeOut = TimeOfDay(hour: newHour, minute: newMinute);

      expect(timeOut.hour, equals(13));
      expect(timeOut.minute, equals(35));
      print('✅ 1:30 PM -> 1:35 PM: ${timeOut.hour}:${timeOut.minute}');
    });
  });
}
