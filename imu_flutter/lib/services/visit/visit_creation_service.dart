import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

/// Creates visits by writing directly to local SQLite.
/// PowerSync CRUD queue handles delivery to the backend when online.
class VisitCreationService {
  final Uuid _uuid = const Uuid();

  Future<void> createVisit({
    required String clientId,
    required String timeIn,
    required String timeOut,
    required String odometerArrival,
    required String odometerDeparture,
    File? photoFile,
    String? notes,
    String type = 'regular_visit',
  }) async {
    final db = await PowerSyncService.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final savedPhotoPath = photoFile != null ? await _saveFile(photoFile) : null;

    debugPrint('VisitCreationService: Writing visit $id to SQLite');

    await db.execute(
      '''INSERT INTO visits
         (id, client_id, user_id, type, time_in, time_out,
          odometer_arrival, odometer_departure, _local_photo_path, notes, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        clientId,
        null, // user_id filled by backend from JWT
        type,
        timeIn,
        timeOut,
        odometerArrival,
        odometerDeparture,
        savedPhotoPath,
        notes,
        now,
      ],
    );
  }

  Future<String> _saveFile(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = 'visit_${_uuid.v4()}_${path.basename(file.path)}';
    final newPath = path.join(dir.path, filename);
    await file.copy(newPath);
    return newPath;
  }
}
