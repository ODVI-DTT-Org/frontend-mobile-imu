import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:imu_flutter/services/api/pocketbase_client.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Touchpoint API service for PocketBase backend
class TouchpointApiService {
  final PocketBase _pb;

  TouchpointApiService({required PocketBase pb}) : _pb = pb;

  /// Fetch touchpoints for a specific client
  Future<List<Touchpoint>> fetchTouchpoints(String clientId, {
    int page = 1,
    int perPage = 50,
    String? sort,
    String? expand,
  }) async {
    try {
      debugPrint('TouchpointApiService: Fetching touchpoints for client $clientId');

      final result = await _pb.collection('touchpoints').getList(
        page: page,
        perPage: perPage,
        filter: 'client = "$clientId"',
        sort: sort,
        expand: expand ?? 'client',
      );

      debugPrint('TouchpointApiService: Fetched ${result.items.length} touchpoints');

      return result.items.map((item) => _mapToTouchpoint(item)).toList();
    } on ClientException catch (e) {
      debugPrint('TouchpointApiService: Error fetching touchpoints - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('TouchpointApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch touchpoints',
        originalError: e,
      );
    }
  }

  /// Fetch single touchpoint
  Future<Touchpoint> fetchTouchpoint(String id) async {
    try {
      debugPrint('TouchpointApiService: Fetching touchpoint $id');

      final result = await _pb.collection('touchpoints').getOne(id);

      debugPrint('TouchpointApiService: Fetched touchpoint ${result.id}');

      return _mapToTouchpoint(result);
    } on ClientException catch (e) {
      debugPrint('TouchpointApiService: Error fetching touchpoint - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('TouchpointApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch touchpoint',
        originalError: e,
      );
    }
  }

  /// Create touchpoint
  Future<Touchpoint> createTouchpoint(Touchpoint touchpoint) async {
    try {
      debugPrint('TouchpointApiService: Creating touchpoint');

      final result = await _pb.collection('touchpoints').create(body: {
        'client_id': touchpoint.clientId,
        'touchpoint_number': touchpoint.touchpointNumber,
        'type': touchpoint.type.name,
        'reason': touchpoint.reason.name,
        'date': touchpoint.date.toIso8601String(),
        'remarks': touchpoint.remarks,
        'photo_path': touchpoint.photoPath,
        'latitude': touchpoint.latitude,
        'longitude': touchpoint.longitude,
        'created_at': touchpoint.createdAt.toIso8601String(),
        'created_via': 'mobile_app',
      });

      debugPrint('TouchpointApiService: Created touchpoint ${result.id}');

      return _mapToTouchpoint(result);
    } on ClientException catch (e) {
      debugPrint('TouchpointApiService: Error creating touchpoint - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('TouchpointApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to create touchpoint',
        originalError: e,
      );
    }
  }

  /// Update touchpoint
  Future<Touchpoint> updateTouchpoint(Touchpoint touchpoint) async {
    try {
      debugPrint('TouchpointApiService: Updating touchpoint ${touchpoint.id}');

      final result = await _pb.collection('touchpoints').update(touchpoint.id, body: {
        'remarks': touchpoint.remarks,
        'photo_path': touchpoint.photoPath,
        'latitude': touchpoint.latitude,
        'longitude': touchpoint.longitude,
      });

      debugPrint('TouchpointApiService: Updated touchpoint ${result.id}');

      return _mapToTouchpoint(result);
    } on ClientException catch (e) {
      debugPrint('TouchpointApiService: Error updating touchpoint - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('TouchpointApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update touchpoint',
        originalError: e,
      );
    }
  }

  /// Delete touchpoint
  Future<void> deleteTouchpoint(String id) async {
    try {
      debugPrint('TouchpointApiService: Deleting touchpoint $id');

      await _pb.collection('touchpoints').delete(id);

      debugPrint('TouchpointApiService: Deleted touchpoint $id');
    } on ClientException catch (e) {
      debugPrint('TouchpointApiService: Error deleting touchpoint - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('TouchpointApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to delete touchpoint',
        originalError: e,
      );
    }
  }

  /// Map PocketBase record to Touchpoint model
  Touchpoint _mapToTouchpoint(RecordModel record) {
    final data = record.data;

    return Touchpoint(
      id: record.id,
      clientId: data['client_id'] as String? ?? '',
      touchpointNumber: data['touchpoint_number'] as int? ?? 1,
      type: TouchpointType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TouchpointType.visit,
      ),
      reason: TouchpointReason.values.firstWhere(
        (e) => e.name == data['reason'],
        orElse: () => TouchpointReason.interested,
      ),
      date: data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
      address: data['address'] as String?,
      remarks: data['remarks'] as String?,
      photoPath: data['photo_path'] as String?,
      latitude: data['latitude'] as double?,
      longitude: data['longitude'] as double?,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }
}

/// Provider for TouchpointApiService
final touchpointApiServiceProvider = Provider<TouchpointApiService>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return TouchpointApiService(pb: pb);
});
