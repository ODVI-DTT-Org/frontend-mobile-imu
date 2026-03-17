import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';

/// Repository for touchpoint operations using Hive
/// TODO: Phase 2 - Will be updated to use PowerSync
class TouchpointRepository {
  final HiveService _hiveService;

  TouchpointRepository(this._hiveService);

  /// Watch all touchpoints for a client
  Stream<List<Touchpoint>> watchTouchpoints(String clientId) async* {
    // For now, emit the current list and update on changes
    // TODO: Phase 2 - Implement real-time updates with PowerSync
    final touchpoints = await getTouchpoints(clientId);
    yield touchpoints;
  }

  /// Get touchpoints for a client (one-time fetch)
  Future<List<Touchpoint>> getTouchpoints(String clientId) async {
    final data = _hiveService.getTouchpointsForClient(clientId);
    return data.map((json) => Touchpoint.fromJson(json)).toList();
  }

  /// Create a new touchpoint
  Future<Touchpoint> createTouchpoint(Touchpoint touchpoint) async {
    final data = touchpoint.toJson();
    await _hiveService.addTouchpoint(data);
    return touchpoint;
  }

  /// Update an existing touchpoint
  Future<Touchpoint> updateTouchpoint(Touchpoint touchpoint) async {
    final data = touchpoint.toJson();
    await _hiveService.updateTouchpoint(data);
    return touchpoint;
  }

  /// Delete a touchpoint
  Future<void> deleteTouchpoint(String clientId, String touchpointId) async {
    // TODO: Implement with HiveService
    // For now, just remove from local storage
  }
}

/// Provider for touchpoint repository
final touchpointRepositoryProvider = Provider<TouchpointRepository>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return TouchpointRepository(hiveService);
});
