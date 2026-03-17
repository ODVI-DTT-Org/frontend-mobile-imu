import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';
import 'package:imu_flutter/core/utils/logger.dart';

/// Itinerary model for scheduled visits
class Itinerary {
  final String id;
  final String? caravanId;
  final String? clientId;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final String? status;
  final String? priority;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Itinerary({
    required this.id,
    this.caravanId,
    this.clientId,
    this.scheduledDate,
    this.scheduledTime,
    this.status,
    this.priority,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from API format
  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] ?? '',
      caravanId: json['caravan_id'] ?? json['caravanId'],
      clientId: json['client_id'] ?? json['clientId'],
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : json['scheduledDate'] != null
              ? DateTime.parse(json['scheduledDate'])
              : null,
      scheduledTime: json['scheduled_time'] ?? json['scheduledTime'],
      status: json['status'],
      priority: json['priority'],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : null,
    );
  }

  /// Convert to API format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caravan_id': caravanId,
      'client_id': clientId,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'scheduled_time': scheduledTime,
      'status': status,
      'priority': priority,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Repository for itinerary operations using Hive
/// TODO: Phase 2 - Will be updated to use PowerSync
class ItineraryRepository {
  final HiveService _hiveService;

  ItineraryRepository(this._hiveService);

  /// Watch all itineraries with real-time updates
  Stream<List<Itinerary>> watchItineraries() async* {
    // For now, emit the current list and update on changes
    // TODO: Phase 2 - Implement real-time updates with PowerSync
    final itineraries = await getItineraries();
    yield itineraries;
  }

  /// Watch itineraries for a specific caravan
  Stream<List<Itinerary>> watchCaravanItineraries(String caravanId) async* {
    final itineraries = await getCaravanItineraries(caravanId);
    yield itineraries;
  }

  /// Watch itineraries for a specific date
  Stream<List<Itinerary>> watchDateItineraries(DateTime date) async* {
    final itineraries = await getDateItineraries(date);
    yield itineraries;
  }

  /// Get all itineraries (one-time fetch)
  Future<List<Itinerary>> getItineraries() async {
    // TODO: Phase 2 - Implement with PowerSync
    // For now, return mock/empty list
    return [];
  }

  /// Get itineraries for a specific caravan
  Future<List<Itinerary>> getCaravanItineraries(String caravanId) async {
    // TODO: Phase 2 - Implement with PowerSync
    return [];
  }

  /// Get itineraries for a specific date
  Future<List<Itinerary>> getDateItineraries(DateTime date) async {
    // TODO: Phase 2 - Implement with PowerSync
    return [];
  }
}

/// Provider for itinerary repository
final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ItineraryRepository(hiveService);
});
