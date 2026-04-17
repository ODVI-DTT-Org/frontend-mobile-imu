import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/api/visit_api_service.dart';
import 'pending_visit_service.dart';

/// Creates visits: online → REST API, offline → Hive pending queue
class VisitCreationService {
  final ConnectivityService _connectivity;
  final VisitApiService _api;
  final PendingVisitService _pending;
  final Uuid _uuid = const Uuid();

  VisitCreationService(this._connectivity, this._api, this._pending);

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
    if (_connectivity.isOnline) {
      debugPrint('VisitCreationService: Online - calling API');
      await _api.createVisit(
        clientId: clientId,
        timeIn: timeIn,
        timeOut: timeOut,
        odometerArrival: odometerArrival,
        odometerDeparture: odometerDeparture,
        photoFile: photoFile,
        notes: notes,
        type: type,
      );
    } else {
      debugPrint('VisitCreationService: Offline - storing locally');
      final savedPhotoPath = photoFile != null ? await _saveFileForOffline(photoFile) : null;
      await _pending.addPendingVisit(
        clientId: clientId,
        timeIn: timeIn,
        timeOut: timeOut,
        odometerArrival: odometerArrival,
        odometerDeparture: odometerDeparture,
        photoPath: savedPhotoPath,
        notes: notes,
        type: type,
      );
    }
  }

  Future<String> _saveFileForOffline(File file) async {
    final dir = await getTemporaryDirectory();
    final filename = 'pending_visit_${_uuid.v4()}_${path.basename(file.path)}';
    final newPath = path.join(dir.path, filename);
    await file.copy(newPath);
    return newPath;
  }
}
