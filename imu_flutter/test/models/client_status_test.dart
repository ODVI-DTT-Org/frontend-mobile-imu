import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/models/client_status.dart';

void main() {
  group('ClientStatus', () {
    test('should create instance with required fields', () {
      const status = ClientStatus(inItinerary: true, loanReleased: false);
      expect(status.inItinerary, true);
      expect(status.loanReleased, false);
    });

    test('copyWith should override specified fields', () {
      const status1 = ClientStatus(inItinerary: true, loanReleased: false);
      final status2 = status1.copyWith(inItinerary: false);
      expect(status2.inItinerary, false);
      expect(status2.loanReleased, false);
    });

    test('fromJson should create instance from JSON', () {
      final json = {'inItinerary': true, 'loanReleased': true};
      final status = ClientStatus.fromJson(json);
      expect(status.inItinerary, true);
      expect(status.loanReleased, true);
    });

    test('toJson should convert to JSON', () {
      const status = ClientStatus(inItinerary: false, loanReleased: true);
      final json = status.toJson();
      expect(json, {'inItinerary': false, 'loanReleased': true});
    });

    test('fromJson should handle missing fields with defaults', () {
      final json = <String, dynamic>{};
      final status = ClientStatus.fromJson(json);
      expect(status.inItinerary, false);
      expect(status.loanReleased, false);
    });
  });
}
