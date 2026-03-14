import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:imu_flutter/services/api/pocketbase_client.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Itinerary item model for scheduled visits
class ItineraryItem {
  final String id;
  final String clientId;
  final String clientName;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final String status; // scheduled, completed, missed, rescheduled
  final int touchpointNumber;
  final String touchpointType;
  final String? notes;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ItineraryItem({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.scheduledDate,
    this.scheduledTime,
    required this.status,
    required this.touchpointNumber,
    required this.touchpointType,
    this.notes,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.updatedAt,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] ?? '',
      clientId: json['client_id'] ?? '',
      clientName: json['client_name'] ?? json['expand']?['client']?['first_name'] ?? '',
      scheduledDate: DateTime.parse(json['scheduled_date']),
      scheduledTime: json['scheduled_time'],
      status: json['status'] ?? 'scheduled',
      touchpointNumber: json['touchpoint_number'] ?? 1,
      touchpointType: json['touchpoint_type'] ?? 'visit',
      notes: json['notes'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdAt: DateTime.parse(json['created']),
      updatedAt: json['updated'] != null ? DateTime.parse(json['updated']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'client_name': clientName,
      'scheduled_date': scheduledDate.toIso8601String(),
      'scheduled_time': scheduledTime,
      'status': status,
      'touchpoint_number': touchpointNumber,
      'touchpoint_type': touchpointType,
      'notes': notes,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'created': createdAt.toIso8601String(),
      'updated': updatedAt?.toIso8601String(),
    };
  }
}

/// Itinerary API service for PocketBase backend
class ItineraryApiService {
  final PocketBase _pb;

  ItineraryApiService({required PocketBase pb}) : _pb = pb;

  /// Fetch itinerary for a specific date
  Future<List<ItineraryItem>> fetchItinerary(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      debugPrint('ItineraryApiService: Fetching itinerary for $dateStr');

      final result = await _pb.collection('itinerary').getList(
        page: 1,
        perPage: 100,
        filter: 'scheduled_date >= "$dateStr 00:00:00" && scheduled_date <= "$dateStr 23:59:59"',
        sort: 'scheduled_time',
        expand: 'client',
      );

      debugPrint('ItineraryApiService: Fetched ${result.items.length} items');

      return result.items.map((item) => ItineraryItem.fromJson({
        ...item.data,
        'id': item.id,
        'created': item.created,
        'updated': item.updated,
      })).toList();
    } on ClientException catch (e) {
      debugPrint('ItineraryApiService: Error fetching itinerary - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch itinerary',
        originalError: e,
      );
    }
  }

  /// Create itinerary item
  Future<ItineraryItem> createItineraryItem(ItineraryItem item) async {
    try {
      debugPrint('ItineraryApiService: Creating itinerary item');

      final result = await _pb.collection('itinerary').create(body: {
        'client': item.clientId,
        'scheduled_date': item.scheduledDate.toIso8601String(),
        'scheduled_time': item.scheduledTime,
        'status': item.status,
        'touchpoint_number': item.touchpointNumber,
        'touchpoint_type': item.touchpointType,
        'notes': item.notes,
      });

      debugPrint('ItineraryApiService: Created itinerary item ${result.id}');

      return ItineraryItem.fromJson({
        ...result.data,
        'id': result.id,
        'created': result.created,
        'updated': result.updated,
      });
    } on ClientException catch (e) {
      debugPrint('ItineraryApiService: Error creating itinerary item - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to create itinerary item',
        originalError: e,
      );
    }
  }

  /// Update itinerary item status
  Future<ItineraryItem> updateItineraryStatus(String id, String status) async {
    try {
      debugPrint('ItineraryApiService: Updating itinerary item $id status to $status');

      final result = await _pb.collection('itinerary').update(id, body: {
        'status': status,
      });

      return ItineraryItem.fromJson({
        ...result.data,
        'id': result.id,
        'created': result.created,
        'updated': result.updated,
      });
    } on ClientException catch (e) {
      debugPrint('ItineraryApiService: Error updating itinerary item - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update itinerary item',
        originalError: e,
      );
    }
  }

  /// Fetch missed visits
  Future<List<ItineraryItem>> fetchMissedVisits() async {
    try {
      debugPrint('ItineraryApiService: Fetching missed visits');

      final result = await _pb.collection('itinerary').getList(
        page: 1,
        perPage: 100,
        filter: 'status = "missed"',
        sort: '-scheduled_date',
        expand: 'client',
      );

      return result.items.map((item) => ItineraryItem.fromJson({
        ...item.data,
        'id': item.id,
        'created': item.created,
        'updated': item.updated,
      })).toList();
    } on ClientException catch (e) {
      debugPrint('ItineraryApiService: Error fetching missed visits - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch missed visits',
        originalError: e,
      );
    }
  }
}

/// Provider for ItineraryApiService
final itineraryApiServiceProvider = Provider<ItineraryApiService>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return ItineraryApiService(pb: pb);
});

/// Provider for today's itinerary
final todayItineraryProvider = FutureProvider<List<ItineraryItem>>((ref) async {
  final itineraryApi = ref.watch(itineraryApiServiceProvider);
  return await itineraryApi.fetchItinerary(DateTime.now());
});

/// Provider for missed visits
final missedVisitsProvider = FutureProvider<List<ItineraryItem>>((ref) async {
  final itineraryApi = ref.watch(itineraryApiServiceProvider);
  return await itineraryApi.fetchMissedVisits();
});
