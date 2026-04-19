import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

/// Creates touchpoints by writing directly to local SQLite.
/// PowerSync CRUD queue handles delivery to the backend when online.
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

    if (photo != null) await _saveFile(photo, 'photo');
    if (audio != null) await _saveFile(audio, 'audio');

    debugPrint('TouchpointCreationService: Writing touchpoint $id to SQLite');

    await db.execute(
      '''INSERT INTO touchpoints
         (id, client_id, user_id, touchpoint_number, type, date, status,
          next_visit_date, notes, is_legacy, latitude, longitude, address, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
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
        latitude,
        longitude,
        address,
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
