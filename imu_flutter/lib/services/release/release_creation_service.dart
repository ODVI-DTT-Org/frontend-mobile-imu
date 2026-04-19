import 'package:flutter/foundation.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/api/release_api_service.dart';
import 'package:imu_flutter/services/api/visit_api_service.dart';
import 'package:imu_flutter/services/api/api_exception.dart';

/// Creates loan releases.
/// Releases require an internet connection — they are high-stakes financial
/// transactions requiring server confirmation and cannot be safely queued offline.
class ReleaseCreationService {
  final ConnectivityService _connectivity;
  final ReleaseApiService _releaseApi;
  final VisitApiService _visitApi;

  ReleaseCreationService(this._connectivity, this._releaseApi, this._visitApi);

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
    double? latitude,
    double? longitude,
  }) async {
    if (!_connectivity.isOnline) {
      throw ApiException(
        message: 'Loan release requires an internet connection. Please connect and try again.',
      );
    }

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
      latitude: latitude,
      longitude: longitude,
    );
  }
}
