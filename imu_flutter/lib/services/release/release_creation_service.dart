import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/api/release_api_service.dart';
import 'package:imu_flutter/services/api/visit_api_service.dart';
import 'pending_release_service.dart';

/// Creates loan releases: online → REST API, offline → Hive pending queue
class ReleaseCreationService {
  final ConnectivityService _connectivity;
  final ReleaseApiService _releaseApi;
  final VisitApiService _visitApi;
  final PendingReleaseService _pending;
  final Uuid _uuid = const Uuid();

  ReleaseCreationService(
      this._connectivity, this._releaseApi, this._visitApi, this._pending);

  Future<void> createCompleteLoanRelease({
    required String clientId,
    required String timeIn,
    required String timeOut,
    required String odometerArrival,
    required String odometerDeparture,
    required String productType,
    required String loanType,
    int? udiNumber,
    String? remarks,
    String? photoPath,
  }) async {
    if (_connectivity.isOnline) {
      debugPrint('ReleaseCreationService: Online - calling API');
      await _releaseApi.createCompleteLoanRelease(
        clientId: clientId,
        timeIn: timeIn,
        timeOut: timeOut,
        odometerArrival: odometerArrival,
        odometerDeparture: odometerDeparture,
        productType: productType,
        loanType: loanType,
        udiNumber: udiNumber,
        remarks: remarks,
        photoPath: photoPath,
      );
    } else {
      debugPrint('ReleaseCreationService: Offline - storing locally');
      final savedPhotoPath = photoPath != null
          ? await _saveFileForOffline(File(photoPath))
          : null;
      await _pending.addPendingRelease(
        clientId: clientId,
        timeIn: timeIn,
        timeOut: timeOut,
        odometerArrival: odometerArrival,
        odometerDeparture: odometerDeparture,
        productType: productType,
        loanType: loanType,
        udiNumber: udiNumber,
        remarks: remarks,
        photoPath: savedPhotoPath,
      );
    }
  }

  Future<String> _saveFileForOffline(File file) async {
    if (!await file.exists()) return file.path;
    final dir = await getTemporaryDirectory();
    final filename = 'pending_release_${_uuid.v4()}_${path.basename(file.path)}';
    final newPath = path.join(dir.path, filename);
    await file.copy(newPath);
    return newPath;
  }
}
