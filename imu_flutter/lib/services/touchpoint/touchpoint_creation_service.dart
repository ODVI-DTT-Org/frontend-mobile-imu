import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

/// Creates touchpoints by writing directly to local SQLite.
/// PowerSync CRUD queue handles delivery to the backend when online.
///
/// Flow: insert visits/calls row first (with photo path), then insert touchpoints
/// referencing it. PowerSync uploads them in order, so the visit exists before
/// the touchpoint POST reaches the backend.
class TouchpointCreationService {
  final Uuid _uuid = const Uuid();

  Future<void> createTouchpoint(
    String clientId,
    Touchpoint touchpoint, {
    File? photo,
    File? audio,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final db = await PowerSyncService.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final effectiveLat = latitude ?? touchpoint.latitude;
    final effectiveLng = longitude ?? touchpoint.longitude;
    final effectiveAddress = address ?? touchpoint.address;

    String? localPhotoPath;
    if (photo != null) localPhotoPath = await _saveFile(photo, 'photo');
    if (audio != null) await _saveFile(audio, 'audio');

    String? visitId;
    String? callId;

    if (touchpoint.type == TouchpointType.visit) {
      visitId = _uuid.v4();
      await db.execute(
        '''INSERT INTO visits
           (id, client_id, user_id, type, notes, reason, status,
            address, latitude, longitude, time_in, time_out,
            _local_photo_path, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          visitId,
          clientId,
          touchpoint.userId,
          'regular_visit',
          touchpoint.remarks,
          touchpoint.reason?.apiValue,
          touchpoint.status.apiValue,
          effectiveAddress,
          effectiveLat,
          effectiveLng,
          touchpoint.timeIn?.toIso8601String(),
          touchpoint.timeOut?.toIso8601String(),
          localPhotoPath,
          now,
        ],
      );
    } else {
      callId = _uuid.v4();
      await db.execute(
        '''INSERT INTO calls
           (id, client_id, user_id, type, notes, reason, status, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          callId,
          clientId,
          touchpoint.userId,
          'touchpoint_call',
          touchpoint.remarks,
          touchpoint.reason?.apiValue,
          touchpoint.status.apiValue,
          now,
        ],
      );
    }

    debugPrint('TouchpointCreationService: Writing touchpoint $id to SQLite');

    await db.execute(
      '''INSERT INTO touchpoints
         (id, client_id, user_id, touchpoint_number, type, date, status,
          next_visit_date, notes, is_legacy, latitude, longitude, address,
          visit_id, call_id, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        clientId,
        touchpoint.userId,
        touchpoint.touchpointNumber,
        touchpoint.type.apiValue,
        touchpoint.date.toIso8601String(),
        touchpoint.status.apiValue,
        touchpoint.nextVisitDate?.toIso8601String(),
        touchpoint.remarks,
        0,
        effectiveLat,
        effectiveLng,
        effectiveAddress,
        visitId,
        callId,
        now,
      ],
    );
  }

  Future<String> _saveFile(File file, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = '${prefix}_${_uuid.v4()}_${path.basename(file.path)}';
    final newPath = path.join(dir.path, filename);
    await file.copy(newPath);
    return newPath;
  }
}
