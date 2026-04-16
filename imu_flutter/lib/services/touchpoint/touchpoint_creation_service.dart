import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/api/touchpoint_api_service.dart';
import 'package:imu_flutter/services/touchpoint/pending_touchpoint_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Service for creating touchpoints with online/offline logic
/// - Online: Calls backend API directly
/// - Offline: Stores in PendingTouchpointService for later sync
class TouchpointCreationService {
  final ConnectivityService _connectivity;
  final TouchpointApiService _api;
  final PendingTouchpointService _pending;
  final Uuid _uuid = const Uuid();

  TouchpointCreationService(
    this._connectivity,
    this._api,
    this._pending,
  );

  /// Create a touchpoint
  /// - If online: Calls backend API directly
  /// - If offline: Stores in pending_touchpoints Hive box
  Future<void> createTouchpoint(
    String clientId,
    Touchpoint touchpoint, {
    File? photo,
    File? audio,
  }) async {
    if (_connectivity.isOnline) {
      // Online: Call backend API directly
      debugPrint('TouchpointCreationService: Online - calling API');

      if (photo != null) {
        // Use FormData endpoint for photo upload
        await _api.createTouchpointWithPhoto(touchpoint, photoFile: photo);
      } else {
        // Use JSON endpoint for touchpoint without photo
        // Note: audio-only uploads need to be handled separately
        await _api.createTouchpoint(touchpoint);
      }
    } else {
      // Offline: Store in pending_touchpoints Hive box
      debugPrint('TouchpointCreationService: Offline - storing locally');

      // Save photo/audio to cache directory
      final photoPath = photo != null
        ? await _saveFileForOffline(photo)
        : null;
      final audioPath = audio != null
        ? await _saveFileForOffline(audio)
        : null;

      await _pending.addPendingTouchpoint(
        clientId,
        touchpoint,
        photoPath: photoPath,
        audioPath: audioPath,
      );
    }
  }

  /// Save file to temporary directory for offline storage
  Future<String> _saveFileForOffline(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final filename = 'pending_${_uuid.v4()}_${file.path.split(Platform.pathSeparator).last}';
      final newPath = path.join(dir.path, filename);
      await file.copy(newPath);
      debugPrint('TouchpointCreationService: Saved file for offline: $newPath');
      return newPath;
    } catch (e) {
      debugPrint('TouchpointCreationService: Failed to save file for offline: $e');
      rethrow;
    }
  }
}
