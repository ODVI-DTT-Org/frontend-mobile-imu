// test/unit/services/gps_capture_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/gps/gps_capture_service.dart';

void main() {
  group('GPSCaptureService', () {
    test('should capture location with address', () async {
      // This test will fail until we implement the service
      final service = GPSCaptureService();
      final location = await service.captureLocation();

      expect(location.latitude, isNotNull);
      expect(location.longitude, isNotNull);
      expect(location.address, isNotEmpty);
    });

    test('should throw GPSRequiredException when GPS disabled', () async {
      final service = GPSCaptureService();

      // Mock GPS disabled scenario
      expect(
        () => service.captureLocation(),
        throwsA(isA<GPSRequiredException>()),
      );
    });
  });
}
