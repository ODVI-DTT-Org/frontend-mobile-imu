import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../features/visits/data/models/missed_visit_model.dart';
import '../../features/clients/data/models/client_model.dart';
import '../auth/jwt_auth_service.dart';
import '../auth/auth_service.dart' show jwtAuthProvider;

class MissedVisitsResponse {
  final List<MissedVisit> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
  final Map<MissedVisitPriority, int> counts;

  const MissedVisitsResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
    required this.counts,
  });
}

class MissedVisitsApiService {
  final JwtAuthService _authService;

  MissedVisitsApiService(this._authService);

  Future<MissedVisitsResponse> fetchMissedVisits({
    int page = 1,
    int limit = 20,
    MissedVisitPriority? priority,
  }) async {
    final token = _authService.accessToken;
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (priority != null) 'priority': priority.name,
    };

    final uri = Uri.parse('${AppConfig.postgresApiUrl}/visits/missed')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch missed visits: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final rawItems = (json['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    final rawCounts = json['counts'] as Map<String, dynamic>;

    final items = rawItems.map((item) {
      final touchpointTypeStr = (item['touchpoint_type'] as String?)?.toLowerCase();
      final touchpointType = touchpointTypeStr == 'call'
          ? TouchpointType.call
          : TouchpointType.visit;
      final sourceStr = item['source'] as String?;
      final source = sourceStr == 'missedItinerary'
          ? MissedVisitSource.missedItinerary
          : MissedVisitSource.overdueClient;
      final scheduledDate = item['scheduled_date'] != null
          ? DateTime.tryParse(item['scheduled_date'] as String) ?? DateTime.now()
          : DateTime.now();
      final createdAt = item['created_at'] != null
          ? DateTime.tryParse(item['created_at'] as String) ?? DateTime.now()
          : DateTime.now();

      return MissedVisit(
        id: item['id'] as String,
        clientId: item['client_id'] as String,
        clientName: item['client_name'] as String? ?? '',
        touchpointNumber: (item['touchpoint_number'] as num?)?.toInt() ?? 1,
        touchpointType: touchpointType,
        scheduledDate: scheduledDate,
        createdAt: createdAt,
        primaryPhone: item['primary_phone'] as String?,
        primaryAddress: item['primary_address'] as String?,
        source: source,
        itineraryId: item['itinerary_id'] as String?,
      );
    }).toList();

    return MissedVisitsResponse(
      items: items,
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      hasMore: json['has_more'] as bool,
      counts: {
        MissedVisitPriority.high: (rawCounts['high'] as num?)?.toInt() ?? 0,
        MissedVisitPriority.medium: (rawCounts['medium'] as num?)?.toInt() ?? 0,
        MissedVisitPriority.low: (rawCounts['low'] as num?)?.toInt() ?? 0,
      },
    );
  }
}

final missedVisitsApiServiceProvider = Provider<MissedVisitsApiService>((ref) {
  final authService = ref.read(jwtAuthProvider);
  return MissedVisitsApiService(authService);
});
