// test/features/activity/activity_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/features/activity/data/repositories/activity_repository.dart';

void main() {
  group('ActivityRepository.subtypeFromTouchpoint', () {
    test('Visit type maps to touchpointVisit', () {
      expect(
        ActivityRepository.subtypeFromTouchpoint('Visit'),
        ActivitySubtype.touchpointVisit,
      );
    });

    test('Call type maps to touchpointCall', () {
      expect(
        ActivityRepository.subtypeFromTouchpoint('Call'),
        ActivitySubtype.touchpointCall,
      );
    });

    test('unknown type defaults to touchpointVisit', () {
      expect(
        ActivityRepository.subtypeFromTouchpoint('unknown'),
        ActivitySubtype.touchpointVisit,
      );
    });
  });

  group('ActivityRepository.statusFromApproval', () {
    test('pending maps to pending', () {
      expect(ActivityRepository.statusFromApproval('pending'), ActivityStatus.pending);
    });
    test('approved maps to approved', () {
      expect(ActivityRepository.statusFromApproval('approved'), ActivityStatus.approved);
    });
    test('rejected maps to rejected', () {
      expect(ActivityRepository.statusFromApproval('rejected'), ActivityStatus.rejected);
    });
    test('unknown defaults to pending', () {
      expect(ActivityRepository.statusFromApproval('unknown'), ActivityStatus.pending);
    });
  });

  group('ActivityRepository.statusFromRelease', () {
    test('approved maps to approved', () {
      expect(ActivityRepository.statusFromRelease('approved'), ActivityStatus.approved);
    });

    test('disbursed maps to completed', () {
      expect(ActivityRepository.statusFromRelease('disbursed'), ActivityStatus.completed);
    });

    test('pending remains pending', () {
      expect(ActivityRepository.statusFromRelease('pending'), ActivityStatus.pending);
    });
  });

  group('ActivityRepository.touchpointMetadataFromRow', () {
    test('includes full visit fields for touchpoint detail', () {
      final metadata = ActivityRepository.touchpointMetadataFromRow({
        'type': 'Visit',
        'touchpoint_number': 2,
        'date': '2026-05-19',
        'visit_reason': 'Collection',
        'visit_notes': 'Client paid',
        'visit_status': 'completed',
        'time_in': '08:00',
        'time_out': '08:30',
        'odometer_arrival': '100',
        'odometer_departure': '110',
        'visit_address': 'Cebu City',
        'photo_url': 'https://example.com/photo.jpg',
      });

      expect(metadata['touchpointNumber'], 2);
      expect(metadata['reason'], 'Collection');
      expect(metadata['notes'], 'Client paid');
      expect(metadata['timeIn'], '08:00');
      expect(metadata['odometerDeparture'], '110');
      expect(metadata['address'], 'Cebu City');
      expect(metadata['photoUrl'], 'https://example.com/photo.jpg');
    });
  });

  group('ActivityRepository.activityFromPendingRelease', () {
    test('maps a queued release to pending loan release activity', () {
      final queuedAt = DateTime(2026, 5, 19, 10);
      final item = ActivityRepository.activityFromPendingRelease(
        {
          'id': 'queue-1',
          'clientId': 'client-1',
          'udiNumber': 'UDI-123',
          'remarks': 'Release notes',
          'queuedAt': queuedAt.toIso8601String(),
        },
        clientName: 'Dela Cruz, Juan',
      );

      expect(item.id, 'queue-1');
      expect(item.type, ActivityType.approval);
      expect(item.subtype, ActivitySubtype.loanRelease);
      expect(item.status, ActivityStatus.pending);
      expect(item.source, ActivitySource.pendingReleaseQueue);
      expect(item.clientName, 'Dela Cruz, Juan');
      expect(item.detail, 'UDI-123');
      expect(item.createdAt, queuedAt);
      expect(item.metadata['remarks'], 'Release notes');
    });
  });

  group('ActivityRepository.activityFromRelease', () {
    test('maps completed backend release to read-only loan release activity', () {
      final createdAt = DateTime(2026, 5, 19, 11);
      final item = ActivityRepository.activityFromRelease(
        {
          'id': 'release-1',
          'client_id': 'client-1',
          'visit_id': 'visit-1',
          'product_type': 'BFP_PENSION',
          'loan_type': 'NEW',
          'udi_number': 98765,
          'remarks': 'Released',
          'status': 'disbursed',
          'created_at': createdAt.toIso8601String(),
        },
        clientName: 'Dela Cruz, Juan',
        visitMetadata: {
          'timeIn': '09:00',
          'timeOut': '09:30',
        },
      );

      expect(item.id, 'release-1');
      expect(item.subtype, ActivitySubtype.loanRelease);
      expect(item.status, ActivityStatus.completed);
      expect(item.detail, '98765');
      expect(item.clientName, 'Dela Cruz, Juan');
      expect(item.metadata['productType'], 'BFP_PENSION');
      expect(item.metadata['timeIn'], '09:00');
    });
  });

  // Regression: pending caravan/tele loan-release approvals were invisible in
  // the activity feed because fetchApprovals filtered the date window with
  // SQLite `datetime()`, which returns NULL for PowerSync-replicated
  // timestamptz strings (e.g. a bare `+00` offset) — silently dropping the row.
  // The window is now filtered in Dart via these helpers.
  group('ActivityRepository.parseTimestamp', () {
    test('parses PowerSync timestamptz formats that SQLite datetime() drops', () {
      expect(ActivityRepository.parseTimestamp('2026-05-20 09:00:00+00'), isNotNull);
      expect(ActivityRepository.parseTimestamp('2026-05-20 09:00:00.123456Z'), isNotNull);
      expect(ActivityRepository.parseTimestamp('2026-05-20T09:00:00.000Z'), isNotNull);
    });

    test('returns null for null or unparseable input', () {
      expect(ActivityRepository.parseTimestamp(null), isNull);
      expect(ActivityRepository.parseTimestamp('not-a-date'), isNull);
    });
  });

  group('ActivityRepository.isWithinWindow', () {
    final to = DateTime.utc(2026, 5, 21, 12);
    final from = to.subtract(const Duration(days: 7));
    DateTime? at(String raw) => ActivityRepository.parseTimestamp(raw);

    test('includes a replicated pending approval inside the window', () {
      expect(ActivityRepository.isWithinWindow(at('2026-05-21 11:00:00+00'), from, to), isTrue);
    });

    test('excludes timestamps before the window start', () {
      expect(ActivityRepository.isWithinWindow(at('2026-05-10 11:00:00+00'), from, to), isFalse);
    });

    test('excludes timestamps after the window end', () {
      expect(ActivityRepository.isWithinWindow(at('2026-05-21 13:00:00+00'), from, to), isFalse);
    });

    test('excludes rows with null/unparseable created_at', () {
      expect(ActivityRepository.isWithinWindow(null, from, to), isFalse);
      expect(ActivityRepository.isWithinWindow(at('not-a-date'), from, to), isFalse);
    });
  });
}
