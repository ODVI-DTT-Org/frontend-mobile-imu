import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/models/pending_touchpoint.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('PendingTouchpoint', () {
    test('should create from json', () {
      final json = {
        'id': 'pending-123',
        'clientId': 'client-456',
        'touchpoint': {
          'id': 'tp-789',
          'touchpointNumber': 1,
          'type': 'Visit',
          'reason': 'LOAN_INQUIRY',
          'status': 'Interested',
          'date': '2026-04-17T10:00:00.000Z',
          'createdAt': '2026-04-17T10:00:00.000Z',
        },
        'createdAt': '2026-04-17T10:00:00.000Z',
        'photoPath': '/path/to/photo.jpg',
        'audioPath': '/path/to/audio.mp3',
      };

      final pending = PendingTouchpoint.fromJson(json);

      expect(pending.id, 'pending-123');
      expect(pending.clientId, 'client-456');
      expect(pending.touchpoint.id, 'tp-789');
      expect(pending.photoPath, '/path/to/photo.jpg');
      expect(pending.audioPath, '/path/to/audio.mp3');
    });

    test('should serialize to json', () {
      final touchpoint = Touchpoint(
        id: 'tp-789',
        clientId: 'client-456',
        touchpointNumber: 1,
        type: TouchpointType.visit,
        date: DateTime.utc(2026, 4, 17, 10, 0, 0),
        createdAt: DateTime.utc(2026, 4, 17, 10, 0, 0),
        reason: TouchpointReason.loanInquiry,
        status: TouchpointStatus.interested,
      );

      final pending = PendingTouchpoint(
        id: 'pending-123',
        clientId: 'client-456',
        touchpoint: touchpoint,
        createdAt: DateTime.utc(2026, 4, 17, 10, 0, 0),
        photoPath: '/path/to/photo.jpg',
        audioPath: '/path/to/audio.mp3',
      );

      final json = pending.toJson();

      expect(json['id'], 'pending-123');
      expect(json['clientId'], 'client-456');
      expect(json['photoPath'], '/path/to/photo.jpg');
      expect(json['audioPath'], '/path/to/audio.mp3');
    });
  });
}
