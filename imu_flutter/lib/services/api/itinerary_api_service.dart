import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Itinerary API service
/// TODO: Phase 1 - Will be updated to work with PowerSync/Supabase backend
class ItineraryApiService {
  /// Fetch itinerary for a specific date
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<List<ItineraryItem>> fetchItinerary(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      debugPrint('ItineraryApiService: fetchItinerary for $dateStr (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      return [];
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch itinerary',
        originalError: e,
      );
    }
  }

  /// Create itinerary item
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<ItineraryItem?> createItineraryItem(ItineraryItem item) async {
    try {
      debugPrint('ItineraryApiService: createItineraryItem (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase create
      return null;
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to create itinerary item',
        originalError: e,
      );
    }
  }

  /// Update itinerary item status
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<ItineraryItem?> updateItineraryStatus(String id, String status) async {
    try {
      debugPrint('ItineraryApiService: updateItineraryStatus $id -> $status (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase update
      return null;
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update itinerary item',
        originalError: e,
      );
    }
  }

  /// Fetch missed visits
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<List<ItineraryItem>> fetchMissedVisits() async {
    try {
      debugPrint('ItineraryApiService: fetchMissedVisits (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      return [];
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
  return ItineraryApiService();
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
