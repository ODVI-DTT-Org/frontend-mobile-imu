import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/services/error_logging_helper.dart';

/// Itinerary item model for scheduled visits
class ItineraryItem {
  final String id;
  final String clientId;
  final String clientName;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final String status; // pending, in_progress, completed, cancelled
  final String priority; // low, normal, high
  final int? touchpointNumber;
  final String? touchpointType;
  final String? notes;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? assignedByName;

  // Previous touchpoint info
  final int? previousTouchpointNumber; // Last completed touchpoint number
  final String? previousTouchpointReason; // Last completed touchpoint reason
  final String? previousTouchpointType; // Last completed touchpoint type (visit/call)
  final DateTime? previousTouchpointDate; // Last completed touchpoint date

  ItineraryItem({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.scheduledDate,
    this.scheduledTime,
    required this.status,
    this.priority = 'normal',
    this.touchpointNumber,
    this.touchpointType,
    this.notes,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.assignedByName,
    this.previousTouchpointNumber,
    this.previousTouchpointReason,
    this.previousTouchpointType,
    this.previousTouchpointDate,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    // Handle client name from expand object or from flat fields
    // Using "LastName, FirstName MiddleName" format for consistency
    String clientName = '';
    if (json['expand'] != null && json['expand']['client_id'] != null) {
      final client = json['expand']['client_id'] as Map<String, dynamic>;
      final lastName = client['last_name'] ?? '';
      final firstName = client['first_name'] ?? '';
      final middleName = client['middle_name'] ?? '';
      clientName = '$lastName, $firstName${middleName.isNotEmpty ? ' $middleName' : ''}'.trim();
    } else if (json['client_first_name'] != null || json['client_last_name'] != null) {
      final lastName = json['client_last_name'] ?? '';
      final firstName = json['client_first_name'] ?? '';
      clientName = '$lastName, $firstName'.trim();
    } else if (json['client_name'] != null) {
      clientName = json['client_name'];
    }

    // Get address from expand or flat field
    String? address;
    if (json['expand'] != null && json['expand']['client_id'] != null) {
      final client = json['expand']['client_id'] as Map<String, dynamic>;
      address = client['address'];
    }
    if (address == null) {
      address = json['address'];
    }

    // Parse scheduled date - convert UTC timestamps to local time
    // Backend can send either:
    // 1. Simple date format: "2026-03-27" (already local date)
    // 2. ISO timestamp format: "2026-03-26T16:00:00.000Z" (UTC time - need to convert)
    final scheduledDateStr = json['scheduled_date'];
    DateTime scheduledDate;

    if (scheduledDateStr.contains('T')) {
      // ISO timestamp format - parse as UTC then convert to local
      final parsedDate = DateTime.parse(scheduledDateStr); // This creates a UTC DateTime
      final localDate = parsedDate.toLocal(); // Convert to local timezone
      // Create a local DateTime from the LOCAL date components
      scheduledDate = DateTime(localDate.year, localDate.month, localDate.day);
    } else {
      // Simple date format - parse directly as local
      final dateParts = scheduledDateStr.split('-');
      scheduledDate = DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
      );
    }

    debugPrint('[ItineraryItem] Parsing date: $scheduledDateStr -> $scheduledDate (UTC: ${scheduledDate.toUtc()}, Local: ${DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day)})');

    // Validate and parse previous touchpoint number (must be 1-7)
    final previousTouchpointNumber = json['previous_touchpoint_number'] as int?;
    int? validatedPreviousNumber;
    if (previousTouchpointNumber != null) {
      if (previousTouchpointNumber >= 1 && previousTouchpointNumber <= 7) {
        validatedPreviousNumber = previousTouchpointNumber;
      } else {
        debugPrint('[ItineraryItem] Invalid previous touchpoint number: $previousTouchpointNumber (must be 1-7), ignoring');
      }
    }

    return ItineraryItem(
      id: json['id'] ?? '',
      clientId: json['client_id'] ?? '',
      clientName: clientName,
      scheduledDate: scheduledDate,
      scheduledTime: json['scheduled_time'],
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'normal',
      touchpointNumber: json['touchpoint_number'],
      touchpointType: json['touchpoint_type'],
      notes: json['notes'],
      address: address,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdAt: DateTime.parse(json['created'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updated'] ?? json['updated_at'])
          : null,
      createdBy: json['created_by'],
      assignedByName: (json['expand'] != null && json['expand']['created_by'] != null)
          ? json['expand']['created_by']['name'] as String?
          : null,
      previousTouchpointNumber: validatedPreviousNumber,
      previousTouchpointReason: json['previous_touchpoint_reason'],
      previousTouchpointType: json['previous_touchpoint_type'],
      previousTouchpointDate: json['previous_touchpoint_date'] != null
          ? DateTime.parse(json['previous_touchpoint_date'])
          : null,
    );
  }

  /// Create from PowerSync row (SELECT i.*, c.first_name, c.last_name FROM itineraries i LEFT JOIN clients c ...)
  factory ItineraryItem.fromPowerSync(Map<String, dynamic> row) {
    final firstName = row['first_name'] as String? ?? '';
    final lastName = row['last_name'] as String? ?? '';
    final clientName = '$lastName, $firstName'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), '');

    final scheduledDateStr = row['scheduled_date'] as String? ?? DateTime.now().toIso8601String();
    DateTime scheduledDate;
    if (scheduledDateStr.contains('T')) {
      final parsed = DateTime.parse(scheduledDateStr);
      final local = parsed.toLocal();
      scheduledDate = DateTime(local.year, local.month, local.day);
    } else {
      final parts = scheduledDateStr.split('-');
      scheduledDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }

    return ItineraryItem(
      id: row['id'] as String,
      clientId: row['client_id'] as String? ?? '',
      clientName: clientName,
      scheduledDate: scheduledDate,
      scheduledTime: row['scheduled_time'] as String?,
      status: row['status'] as String? ?? 'pending',
      priority: row['priority'] as String? ?? 'normal',
      notes: row['notes'] as String?,
      address: null,
      latitude: null,
      longitude: null,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    // Format date as YYYY-MM-DD using local date components (not UTC)
    final dateStr = '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}';
    return {
      'id': id,
      'client_id': clientId,
      'scheduled_date': dateStr,
      'scheduled_time': scheduledTime,
      'status': status,
      'priority': priority,
      'notes': notes,
    };
  }

  ItineraryItem copyWith({
    String? id,
    String? clientId,
    String? clientName,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? status,
    String? priority,
    int? touchpointNumber,
    String? touchpointType,
    String? notes,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? assignedByName,
    int? previousTouchpointNumber,
    String? previousTouchpointReason,
    String? previousTouchpointType,
    DateTime? previousTouchpointDate,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      touchpointNumber: touchpointNumber ?? this.touchpointNumber,
      touchpointType: touchpointType ?? this.touchpointType,
      notes: notes ?? this.notes,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      assignedByName: assignedByName ?? this.assignedByName,
      previousTouchpointNumber: previousTouchpointNumber ?? this.previousTouchpointNumber,
      previousTouchpointReason: previousTouchpointReason ?? this.previousTouchpointReason,
      previousTouchpointType: previousTouchpointType ?? this.previousTouchpointType,
      previousTouchpointDate: previousTouchpointDate ?? this.previousTouchpointDate,
    );
  }
}

/// Itinerary API service
class ItineraryApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  ItineraryApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  /// Fetch itinerary for a specific date
  Future<List<ItineraryItem>> fetchItinerary(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      debugPrint('ItineraryApiService: Fetching itinerary for $dateStr...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ItineraryApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/itineraries',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'date': dateStr,
        },
      );

      debugPrint('ItineraryApiService: Response status: ${response.statusCode}');
      debugPrint('ItineraryApiService: Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        debugPrint('ItineraryApiService: Got ${items.length} itinerary items from API');

        if (items.isNotEmpty) {
          debugPrint('ItineraryApiService: First item: ${items[0]}');
        }

        return items.map((item) {
          final itineraryData = item as Map<String, dynamic>;
          debugPrint('ItineraryApiService: Parsing item: $itineraryData');
          return ItineraryItem.fromJson(itineraryData);
        }).toList();
      } else {
        debugPrint('ItineraryApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch itinerary: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ItineraryApiService: DioException - ${e.message}');
      debugPrint('ItineraryApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch itinerary',
        originalError: e,
      );
    }
  }

  /// Fetch all itineraries
  Future<List<ItineraryItem>> fetchItineraries({
    int page = 1,
    int perPage = 20,
    String? clientId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      debugPrint('ItineraryApiService: Fetching itineraries...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ItineraryApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/itineraries',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'page': page,
          'perPage': perPage,
          if (clientId != null) 'client_id': clientId,
          if (status != null) 'status': status,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        debugPrint('ItineraryApiService: Got ${items.length} itineraries from API');

        return items.map((item) {
          final itineraryData = item as Map<String, dynamic>;
          return ItineraryItem.fromJson(itineraryData);
        }).toList();
      } else {
        debugPrint('ItineraryApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch itineraries: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ItineraryApiService: DioException - ${e.message}');
      debugPrint('ItineraryApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch itineraries',
        originalError: e,
      );
    }
  }

  /// Fetch single itinerary by ID
  Future<ItineraryItem?> fetchItineraryById(String id) async {
    try {
      debugPrint('ItineraryApiService: Fetching itinerary $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ItineraryApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/itineraries/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final itineraryData = response.data as Map<String, dynamic>;
        debugPrint('ItineraryApiService: Got itinerary: ${itineraryData['id']}');
        return ItineraryItem.fromJson(itineraryData);
      } else {
        debugPrint('ItineraryApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch itinerary: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ItineraryApiService: DioException - ${e.message}');
      debugPrint('ItineraryApiService: Response - ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        return null; // Itinerary not found
      }
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch itinerary',
        originalError: e,
      );
    }
  }

  /// Create itinerary item
  Future<ItineraryItem?> createItinerary({
    required String clientId,
    required DateTime scheduledDate,
    String? scheduledTime,
    String status = 'pending',
    String priority = 'normal',
    String? notes,
  }) async {
    try {
      debugPrint('ItineraryApiService: Creating itinerary item...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ItineraryApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Format date as YYYY-MM-DD using local date components (not UTC)
      final dateStr = '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}';
      debugPrint('ItineraryApiService: Sending scheduled_date: $dateStr (from DateTime: $scheduledDate)');

      final requestData = {
        'client_id': clientId,
        'scheduled_date': dateStr,
        if (scheduledTime != null) 'scheduled_time': scheduledTime,
        'status': status,
        'priority': priority,
        if (notes != null) 'notes': notes,
      };

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/itineraries',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 201) {
        final itineraryData = response.data as Map<String, dynamic>;
        debugPrint('ItineraryApiService: Itinerary created successfully: ${itineraryData['id']}');
        return ItineraryItem.fromJson(itineraryData);
      } else {
        debugPrint('ItineraryApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to create itinerary item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ItineraryApiService: DioException - ${e.message}');
      debugPrint('ItineraryApiService: Response - ${e.response?.data}');

      // Extract the actual error message from the response
      String errorMessage = 'Failed to create itinerary item';
      if (e.response?.data != null) {
        final responseData = e.response!.data as Map<String, dynamic>;
        errorMessage = responseData['message'] ?? errorMessage;
      }

      ErrorLoggingHelper.logCriticalError(
        operation: 'add client to itinerary',
        error: e,
        stackTrace: StackTrace.current,
        context: {'clientId': clientId, 'date': scheduledDate.toIso8601String()},
      );

      throw ApiException(
        message: errorMessage,
        originalError: e,
      );
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      ErrorLoggingHelper.logCriticalError(
        operation: 'add client to itinerary',
        error: e,
        stackTrace: StackTrace.current,
        context: {'clientId': clientId, 'date': scheduledDate.toIso8601String()},
      );
      throw ApiException(
        message: 'Failed to create itinerary item',
        originalError: e,
      );
    }
  }

  /// Add client to My Day (today's itinerary)
  Future<Map<String, dynamic>> addToMyDay({
    required String clientId,
    String? scheduledTime,
    int? priority,
    String? notes,
  }) async {
    try {
      debugPrint('ItineraryApiService: Adding client to My Day...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ItineraryApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final requestData = {
        'client_id': clientId,
        if (scheduledTime != null) 'scheduled_time': scheduledTime,
        if (priority != null) 'priority': priority,
        if (notes != null) 'notes': notes,
      };

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/my-day/add-client',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 200) {
        debugPrint('ItineraryApiService: Client added to My Day successfully');
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('ItineraryApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to add client to My Day: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ItineraryApiService: DioException - ${e.message}');
      debugPrint('ItineraryApiService: Response - ${e.response?.data}');

      // Extract error message from backend response
      String errorMessage = 'Network error: ${e.message}';
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data.containsKey('message')) {
          errorMessage = data['message'].toString();
        } else if (data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        }
      }

      throw ApiException(
        message: errorMessage,
        originalError: e,
      );
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to add client to My Day',
        originalError: e,
      );
    }
  }

  /// Update itinerary item
  Future<ItineraryItem?> updateItinerary({
    required String id,
    String? clientId,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? status,
    String? priority,
    String? notes,
  }) async {
    try {
      debugPrint('ItineraryApiService: Updating itinerary $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ItineraryApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final requestData = {
        if (clientId != null) 'client_id': clientId,
        if (scheduledDate != null) 'scheduled_date': '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}',
        if (scheduledTime != null) 'scheduled_time': scheduledTime,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (notes != null) 'notes': notes,
      };

      final response = await _dio.put(
        '${AppConfig.postgresApiUrl}/itineraries/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 200) {
        final itineraryData = response.data as Map<String, dynamic>;
        debugPrint('ItineraryApiService: Itinerary updated successfully: ${itineraryData['id']}');
        return ItineraryItem.fromJson(itineraryData);
      } else {
        debugPrint('ItineraryApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to update itinerary item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ItineraryApiService: DioException - ${e.message}');
      debugPrint('ItineraryApiService: Response - ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        return null; // Itinerary not found
      }
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update itinerary item',
        originalError: e,
      );
    }
  }

  /// Update itinerary item status
  Future<ItineraryItem?> updateItineraryStatus(String id, String status) async {
    return updateItinerary(id: id, status: status);
  }

  /// Delete itinerary item
  Future<void> deleteItinerary(String id) async {
    try {
      debugPrint('ItineraryApiService: Deleting itinerary $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ItineraryApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.delete(
        '${AppConfig.postgresApiUrl}/itineraries/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('ItineraryApiService: Itinerary deleted successfully');
      } else {
        debugPrint('ItineraryApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to delete itinerary item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ItineraryApiService: DioException - ${e.message}');
      debugPrint('ItineraryApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ItineraryApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to delete itinerary item',
        originalError: e,
      );
    }
  }

  /// Fetch missed visits
  Future<List<ItineraryItem>> fetchMissedVisits() async {
    try {
      debugPrint('ItineraryApiService: Fetching missed visits...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ItineraryApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final today = DateTime.now();
      final localToday = DateTime(today.year, today.month, today.day);
      final pastDate = today.subtract(const Duration(days: 30));
      final dateStr = '${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}-${pastDate.day.toString().padLeft(2, '0')}';

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/itineraries',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'start_date': dateStr,
          'end_date': '${localToday.year}-${localToday.month.toString().padLeft(2, '0')}-${localToday.day.toString().padLeft(2, '0')}',
          'status': 'pending',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        debugPrint('ItineraryApiService: Got ${items.length} missed visits from API');

        return items.map((item) {
          final itineraryData = item as Map<String, dynamic>;
          return ItineraryItem.fromJson(itineraryData);
        }).toList();
      } else {
        debugPrint('ItineraryApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch missed visits: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ItineraryApiService: DioException - ${e.message}');
      debugPrint('ItineraryApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
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
  final jwtAuth = ref.watch(jwtAuthProvider);
  return ItineraryApiService(authService: jwtAuth);
});

/// Provider for today's itinerary (fetches wider range for Yesterday/Today/Tomorrow tabs)
/// Fetches from yesterday to 7 days ahead to support all tabs
final todayItineraryProvider = FutureProvider<List<ItineraryItem>>((ref) async {
  final itineraryApi = ref.watch(itineraryApiServiceProvider);

  // Fetch a wider range: yesterday to 7 days ahead
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));
  final nextWeek = now.add(const Duration(days: 7));

  final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  final nextWeekStr = '${nextWeek.year}-${nextWeek.month.toString().padLeft(2, '0')}-${nextWeek.day.toString().padLeft(2, '0')}';

  debugPrint('ItineraryApiService: Fetching itineraries from $yesterdayStr to $nextWeekStr');

  return await itineraryApi.fetchItineraries(
    startDate: yesterdayStr,
    endDate: nextWeekStr,
    perPage: 100, // Fetch all items in the range
  );
});

/// Provider for missed visits
final missedVisitsProvider = FutureProvider<List<ItineraryItem>>((ref) async {
  final itineraryApi = ref.watch(itineraryApiServiceProvider);
  return await itineraryApi.fetchMissedVisits();
});
