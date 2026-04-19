import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:imu_flutter/core/models/user_role.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/api/approvals_api_service.dart';
import 'package:imu_flutter/services/api/release_api_service.dart';
import 'package:imu_flutter/services/api/upload_api_service.dart';
import 'package:imu_flutter/services/api/visit_api_service.dart';
import 'package:imu_flutter/services/api/api_exception.dart';

/// Creates loan releases.
/// Releases require an internet connection — they are high-stakes financial
/// transactions requiring server confirmation and cannot be safely queued offline.
///
/// Role routing:
/// - Admin: direct release via POST /releases (immediate, no approval needed)
/// - Caravan/Tele: approval request via POST /approvals/loan-release-v2 (pending until admin approves)
class ReleaseCreationService {
  final ConnectivityService _connectivity;
  final ReleaseApiService _releaseApi;
  final VisitApiService _visitApi;
  final ApprovalsApiService _approvalsApi;
  final UploadApiService _uploadApi;
  final UserRole _role;

  ReleaseCreationService(
    this._connectivity,
    this._releaseApi,
    this._visitApi,
    this._approvalsApi,
    this._uploadApi,
    this._role,
  );

  Future<void> createCompleteLoanRelease({
    required String clientId,
    required String timeIn,
    required String timeOut,
    required String odometerArrival,
    required String odometerDeparture,
    required String productType,
    required String loanType,
    required String udiNumber,
    String? remarks,
    String? photoPath,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    if (!_connectivity.isOnline) {
      throw ApiException(
        message: 'Loan release requires an internet connection. Please connect and try again.',
      );
    }

    if (_role == UserRole.admin) {
      // Admin: direct release (no approval needed)
      debugPrint('ReleaseCreationService: Admin role — direct release');
      await _releaseApi.createCompleteLoanRelease(
        clientId: clientId,
        timeIn: timeIn,
        timeOut: timeOut,
        odometerArrival: odometerArrival,
        odometerDeparture: odometerDeparture,
        productType: productType,
        loanType: loanType,
        udiNumber: int.tryParse(udiNumber),
        remarks: remarks,
        photoPath: photoPath,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
    } else {
      // Caravan/Tele: submit for approval via POST /approvals/loan-release-v2
      debugPrint('ReleaseCreationService: ${_role.apiValue} role — submitting approval request');

      // Upload photo first to get a URL
      String? photoUrl;
      if (photoPath != null && photoPath.isNotEmpty) {
        final file = File(photoPath);
        final uploadResult = await _uploadApi.uploadPhoto(file);
        photoUrl = uploadResult?.url;
        debugPrint('ReleaseCreationService: Photo uploaded: $photoUrl');
      }

      await _approvalsApi.submitLoanReleaseV2(
        clientId: clientId,
        udiNumber: udiNumber,
        productType: productType,
        loanType: loanType,
        timeIn: timeIn,
        timeOut: timeOut,
        odometerIn: odometerArrival,
        odometerOut: odometerDeparture,
        latitude: latitude,
        longitude: longitude,
        address: address,
        photoUrl: photoUrl,
        remarks: remarks,
      );
    }
  }
}
