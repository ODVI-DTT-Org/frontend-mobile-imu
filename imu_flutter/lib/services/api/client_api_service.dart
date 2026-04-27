import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/services/error_logging_helper.dart';

/// Client API service
class ClientApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  ClientApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  /// Fetch clients from the REST API with pagination
  Future<ClientsResponse> fetchClients({
    int page = 1,
    int perPage = 20,
    String? search,
    String? clientType,
    String? marketType,
    String? pensionType,
    String? productType,
    String? loanType,
    String? touchpointStatus,
    bool? loanReleased,
    List<String>? municipalityIds,
    List<String>? nextTouchpointNumbers,
  }) async {
    try {
      debugPrint('[CLIENT-API] Fetching clients from REST API...');
      debugPrint('[CLIENT-API] page=$page, perPage=$perPage, search=$search');

      // Get the access token with diagnostic logging
      final token = _authService.accessToken;
      debugPrint('[CLIENT-API] Access token available: ${token != null}');
      debugPrint('[CLIENT-API] Is authenticated: ${_authService.isAuthenticated}');
      debugPrint('[CLIENT-API] Current user: ${_authService.currentUser?.fullName}');

      if (token == null) {
        debugPrint('[CLIENT-API] ERROR: No access token available');
        debugPrint('[CLIENT-API] This usually means JwtAuthService.initialize() has not completed or no tokens are stored');
        throw ApiException(message: 'Not authenticated - Please login again');
      }

      debugPrint('[CLIENT-API] Making API request to /clients');
      // Make the API request
      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/clients',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'page': page,
          'perPage': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
          if (clientType != null && clientType.isNotEmpty) 'client_type': clientType,
          if (marketType != null && marketType.isNotEmpty) 'market_type': marketType,
          if (pensionType != null && pensionType.isNotEmpty) 'pension_type': pensionType,
          if (productType != null && productType.isNotEmpty) 'product_type': productType,
          if (loanType != null && loanType.isNotEmpty) 'loan_type': loanType,
          if (touchpointStatus != null && touchpointStatus.isNotEmpty) 'touchpoint_status': touchpointStatus,
          if (loanReleased == true) 'loan_released': 'true',
          if (municipalityIds != null && municipalityIds.isNotEmpty) 'municipality_ids': municipalityIds.join(','),
          if (nextTouchpointNumbers != null && nextTouchpointNumbers.isNotEmpty)
            'next_touchpoint_number': nextTouchpointNumbers,
        },
      );

      debugPrint('[CLIENT-API] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        final totalItems = data['totalItems'] as int? ?? 0;
        final totalPages = data['totalPages'] as int? ?? 0;

        debugPrint('[CLIENT-API] Got ${items.length} clients from API (page $page of $totalPages, total: $totalItems)');

        final clients = items.map((item) {
          return Client.fromJson(item as Map<String, dynamic>);
        }).toList();

        return ClientsResponse(
          items: clients,
          page: page,
          perPage: perPage,
          totalItems: totalItems,
          totalPages: totalPages,
        );
      } else {
        debugPrint('[CLIENT-API] ERROR: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch clients: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('[CLIENT-API] DioException - ${e.message}');
      debugPrint('[CLIENT-API] Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[CLIENT-API] Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch clients',
        originalError: e,
      );
    }
  }

  /// Fetch assigned clients from the REST API with area-based filtering
  /// Uses the /api/clients/assigned endpoint which automatically filters
  /// by the user's assigned territories
  Future<ClientsResponse> fetchAssignedClients({
    int page = 1,
    int perPage = 20,
    String? search,
    String? clientType,
    String? marketType,
    String? pensionType,
    String? productType,
    String? province,
    String? municipality,
  }) async {
    try {
      debugPrint('[CLIENT-API] Fetching ASSIGNED clients from REST API...');
      debugPrint('[CLIENT-API] page=$page, perPage=$perPage, search=$search');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('[CLIENT-API] ERROR: No access token available');
        throw ApiException(message: 'Not authenticated - Please login again');
      }

      debugPrint('[CLIENT-API] Making API request to /clients/assigned');
      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/clients/assigned',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'page': page,
          'perPage': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
          if (clientType != null && clientType.isNotEmpty) 'client_type': clientType,
          if (marketType != null && marketType.isNotEmpty) 'market_type': marketType,
          if (pensionType != null && pensionType.isNotEmpty) 'pension_type': pensionType,
          if (productType != null && productType.isNotEmpty) 'product_type': productType,
          if (province != null && province.isNotEmpty) 'province': province,
          if (municipality != null && municipality.isNotEmpty) 'municipality': municipality,
        },
      );

      debugPrint('[CLIENT-API] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        final totalItems = data['totalItems'] as int? ?? 0;
        final totalPages = data['totalPages'] as int? ?? 0;

        debugPrint('[CLIENT-API] Got ${items.length} assigned clients from API (page $page of $totalPages, total: $totalItems)');

        final clients = items.map((item) {
          return Client.fromJson(item as Map<String, dynamic>);
        }).toList();

        return ClientsResponse(
          items: clients,
          page: page,
          perPage: perPage,
          totalItems: totalItems,
          totalPages: totalPages,
        );
      } else {
        debugPrint('[CLIENT-API] ERROR: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch assigned clients: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('[CLIENT-API] DioException - ${e.message}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[CLIENT-API] Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch assigned clients',
        originalError: e,
      );
    }
  }

  /// Fetch ALL assigned clients using parallel page requests.
  /// Fetches page 1 first to discover totalPages, then remaining pages in
  /// concurrent batches of [_concurrency] to minimise wall-clock time.
  static const int _concurrency = 10;

  Future<List<Client>> fetchAllAssignedClients() async {
    const perPage = 500;

    // Page 1 tells us totalPages.
    final first = await fetchAssignedClients(page: 1, perPage: perPage);
    final totalPages = first.totalPages;
    debugPrint('[CLIENT-API] fetchAllAssignedClients: $totalPages pages total, fetching with concurrency=$_concurrency');

    final allClients = <Client>[...first.items];
    if (totalPages <= 1) return allClients;

    // Remaining pages in batches.
    for (int batchStart = 2; batchStart <= totalPages; batchStart += _concurrency) {
      final batchEnd = (batchStart + _concurrency - 1).clamp(batchStart, totalPages);
      final responses = await Future.wait(
        List.generate(batchEnd - batchStart + 1, (i) => batchStart + i)
            .map((p) => fetchAssignedClients(page: p, perPage: perPage)),
      );
      for (final r in responses) {
        allClients.addAll(r.items);
      }
      debugPrint('[CLIENT-API] fetchAllAssignedClients: pages $batchStart–$batchEnd/$totalPages done');
    }

    debugPrint('[CLIENT-API] fetchAllAssignedClients: ${allClients.length} clients total');
    return allClients;
  }

  /// Search unassigned clients (clients without caravan_id)
  Future<List<Client>> searchUnassignedClients({
    int page = 1,
    int perPage = 200,
    String? search,
    String? clientType,
  }) async {
    try {
      debugPrint('ClientApiService: Searching unassigned clients...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ClientApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Make the API request
      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/clients/search/unassigned',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'page': page,
          'perPage': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
          if (clientType != null && clientType != 'all') 'client_type': clientType,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        debugPrint('ClientApiService: Got ${items.length} unassigned clients from API');

        return items.map((item) {
          final clientData = item as Map<String, dynamic>;
          debugPrint('ClientApiService: Processing client: ${clientData['first_name']} ${clientData['last_name']}');
          return Client.fromJson(clientData);
        }).toList();
      } else {
        debugPrint('ClientApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to search unassigned clients: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ClientApiService: DioException - ${e.message}');
      debugPrint('ClientApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to search unassigned clients',
        originalError: e,
      );
    }
  }

  /// Assign a client to the current caravan (authenticated user)
  Future<Client?> assignClientToCaravan(String clientId) async {
    try {
      debugPrint('ClientApiService: Assigning client $clientId to current caravan...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ClientApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Get user ID from current user
      final userId = _authService.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        debugPrint('ClientApiService: No user ID found in token');
        throw ApiException(message: 'User ID not found');
      }

      // Make the API request to update client's caravan_id
      final response = await _dio.put(
        '${AppConfig.postgresApiUrl}/clients/$clientId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'caravan_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final clientData = response.data as Map<String, dynamic>;
        debugPrint('ClientApiService: Client assigned successfully: ${clientData['first_name']} ${clientData['last_name']}');
        return Client.fromJson(clientData);
      } else {
        debugPrint('ClientApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to assign client: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ClientApiService: DioException - ${e.message}');
      debugPrint('ClientApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to assign client',
        originalError: e,
      );
    }
  }

  /// Fetch single client by ID
  Future<Client?> fetchClient(String id) async {
    try {
      debugPrint('ClientApiService: Fetching client $id from REST API...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ClientApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Make the API request
      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/clients/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final clientData = response.data as Map<String, dynamic>;
        debugPrint('ClientApiService: Got client: ${clientData['first_name']} ${clientData['last_name']}');
        debugPrint('ClientApiService: Touchpoints count: ${clientData['touchpoints']?.length ?? 0}');
        // Use fromJson to properly parse touchpoints array from API
        return Client.fromJson(clientData);
      } else {
        debugPrint('ClientApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch client: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ClientApiService: DioException - ${e.message}');
      debugPrint('ClientApiService: Response - ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        return null; // Client not found
      }
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch client',
        originalError: e,
      );
    }
  }

  /// Fetch multiple clients by their IDs
  /// Used for batch fetching client data with touchpoint info
  Future<ClientsResponse> fetchClientsByIds(List<String> clientIds) async {
    if (clientIds.isEmpty) {
      return ClientsResponse(items: [], page: 1, perPage: 0, totalItems: 0, totalPages: 0);
    }

    try {
      debugPrint('ClientApiService: Fetching ${clientIds.length} clients by IDs...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ClientApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Make the API request with IDs as query parameter
      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/clients',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'ids': clientIds.join(','),
        },
      );

      debugPrint('ClientApiService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        final totalItems = data['totalItems'] as int? ?? items.length;

        debugPrint('ClientApiService: Got ${items.length} clients by IDs');

        final clients = items.map((item) {
          final clientData = item as Map<String, dynamic>;
          return Client.fromJson(clientData);
        }).toList();

        return ClientsResponse(
          items: clients,
          page: 1,
          perPage: clients.length,
          totalItems: totalItems,
          totalPages: 1,
        );
      } else {
        debugPrint('ClientApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch clients by IDs: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ClientApiService: DioException - ${e.message}');
      debugPrint('ClientApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch clients by IDs',
        originalError: e,
      );
    }
  }

  /// Create a new client
  Future<Client?> createClient(Client client) async {
    try {
      debugPrint('ClientApiService: Creating client ${client.fullName}...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ClientApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Convert Client model to API request format (snake_case)
      final requestData = {
        'first_name': client.firstName,
        'last_name': client.lastName,
        if (client.middleName != null) 'middle_name': client.middleName,
        if (client.birthDate != null) 'birth_date': client.birthDate!.toIso8601String(),
        if (client.email != null) 'email': client.email,
        if (client.phone != null) 'phone': client.phone,
        if (client.agencyName != null) 'agency_name': client.agencyName,
        if (client.department != null) 'department': client.department,
        if (client.position != null) 'position': client.position,
        if (client.employmentStatus != null) 'employment_status': client.employmentStatus,
        if (client.payrollDate != null) 'payroll_date': client.payrollDate,
        if (client.tenure != null) 'tenure': client.tenure,
        'client_type': client.clientType.name.toUpperCase(),
        if (client.productType != ProductType.bfpActive) 'product_type': _getProductTypeValue(client.productType),
        if (client.marketType != null) 'market_type': client.marketType!.name.toUpperCase(),
        'pension_type': client.pensionType.name.toUpperCase(),
        if (client.pan != null) 'pan': client.pan,
        if (client.facebookLink != null) 'facebook_link': client.facebookLink,
        if (client.remarks != null) 'remarks': client.remarks,
        if (client.agencyId != null) 'agency_id': client.agencyId,
        if (client.municipality != null) 'municipality': client.municipality,
        'is_starred': client.isStarred,
      };

      // Make the API request
      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/clients',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      // Handle successful response (could be 201 for direct creation or 200 for approval)
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        // Check if approval is required (for caravan/tele users)
        if (responseData['requires_approval'] == true) {
          debugPrint('ClientApiService: Client creation requires approval');
          // Return null to indicate approval is needed
          // The caller should check for this and show appropriate message
          return null;
        }

        // Direct creation (admin users)
        final clientData = responseData;
        debugPrint('ClientApiService: Client created successfully: ${clientData['first_name']} ${clientData['last_name']}');
        return Client.fromJson(clientData);
      } else {
        debugPrint('ClientApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to create client: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ClientApiService: DioException - ${e.message}');
      debugPrint('ClientApiService: Response - ${e.response?.data}');
      ErrorLoggingHelper.logCriticalError(
        operation: 'create client',
        error: e,
        stackTrace: StackTrace.current,
        context: {'firstName': client.firstName, 'lastName': client.lastName},
      );
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      ErrorLoggingHelper.logCriticalError(
        operation: 'create client',
        error: e,
        stackTrace: StackTrace.current,
        context: {'firstName': client.firstName, 'lastName': client.lastName},
      );
      throw ApiException(
        message: 'Failed to create client',
        originalError: e,
      );
    }
  }

  /// Update an existing client
  Future<Client?> updateClient(Client client) async {
    try {
      if (client.id == null || client.id!.isEmpty) {
        throw ApiException(message: 'Client ID is required for update');
      }

      debugPrint('ClientApiService: Updating client ${client.id}...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ClientApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Convert Client model to API request format (snake_case)
      final requestData = {
        'first_name': client.firstName,
        'last_name': client.lastName,
        if (client.middleName != null) 'middle_name': client.middleName,
        if (client.birthDate != null) 'birth_date': client.birthDate!.toIso8601String(),
        if (client.email != null) 'email': client.email,
        if (client.phone != null) 'phone': client.phone,
        if (client.agencyName != null) 'agency_name': client.agencyName,
        if (client.department != null) 'department': client.department,
        if (client.position != null) 'position': client.position,
        if (client.employmentStatus != null) 'employment_status': client.employmentStatus,
        if (client.payrollDate != null) 'payroll_date': client.payrollDate,
        if (client.tenure != null) 'tenure': client.tenure,
        'client_type': client.clientType.name.toUpperCase(),
        if (client.productType != ProductType.bfpActive) 'product_type': _getProductTypeValue(client.productType),
        if (client.marketType != null) 'market_type': client.marketType!.name.toUpperCase(),
        'pension_type': client.pensionType.name.toUpperCase(),
        if (client.pan != null) 'pan': client.pan,
        if (client.facebookLink != null) 'facebook_link': client.facebookLink,
        if (client.remarks != null) 'remarks': client.remarks,
        if (client.agencyId != null) 'agency_id': client.agencyId,
        if (client.municipality != null) 'municipality': client.municipality,
        'is_starred': client.isStarred,
      };

      // Make the API request
      final response = await _dio.put(
        '${AppConfig.postgresApiUrl}/clients/${client.id}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 200) {
        final clientData = response.data as Map<String, dynamic>;

        // Check if approval is required (caravan/tele users)
        if (clientData['requires_approval'] == true) {
          debugPrint('ClientApiService: Client edit requires approval');
          return null; // Indicates approval needed
        }

        // Admin users get full client data
        debugPrint('ClientApiService: Client updated successfully: ${clientData['first_name'] ?? 'N/A'} ${clientData['last_name'] ?? 'N/A'}');
        return Client.fromJson(clientData);
      } else {
        debugPrint('ClientApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to update client: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ClientApiService: DioException - ${e.message}');
      debugPrint('ClientApiService: Response - ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        return null; // Client not found
      }
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update client',
        originalError: e,
      );
    }
  }

  /// Delete a client. Returns true if deleted directly, false if requires approval.
  Future<bool> deleteClient(String id) async {
    try {
      debugPrint('ClientApiService: Deleting client $id...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ClientApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Make the API request
      final response = await _dio.delete(
        '${AppConfig.postgresApiUrl}/clients/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> && responseData['requires_approval'] == true) {
          debugPrint('ClientApiService: Client deletion requires approval');
          return false;
        }
        debugPrint('ClientApiService: Client deleted successfully');
        return true;
      } else {
        debugPrint('ClientApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to delete client: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ClientApiService: DioException - ${e.message}');
      debugPrint('ClientApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to delete client',
        originalError: e,
      );
    }
  }

  /// Release loan for a client
  Future<Client?> releaseLoan(String clientId) async {
    try {
      debugPrint('ClientApiService: Releasing loan for client $clientId...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ClientApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Make the API request to update loan_released and loan_released_at
      final response = await _dio.patch(
        '${AppConfig.postgresApiUrl}/clients/$clientId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'loan_released': true,
          'loan_released_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        final clientData = response.data as Map<String, dynamic>;
        debugPrint('ClientApiService: Loan released successfully for client: ${clientData['first_name']} ${clientData['last_name']}');
        return Client.fromJson(clientData);
      } else {
        debugPrint('ClientApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to release loan: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ClientApiService: DioException - ${e.message}');
      debugPrint('ClientApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to release loan',
        originalError: e,
      );
    }
  }

  /// Add an address to a client
  Future<Address?> addAddress(String clientId, Address address) async {
    try {
      debugPrint('ClientApiService: Adding address for client $clientId...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ClientApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final requestData = {
        'type': address.type.name,
        'street': address.street,
        if (address.barangay != null) 'barangay': address.barangay,
        'city': address.city,
        if (address.province != null) 'province': address.province,
        if (address.postalCode != null) 'postal_code': address.postalCode,
        'is_primary': address.isPrimary,
        if (address.latitude != null) 'latitude': address.latitude,
        if (address.longitude != null) 'longitude': address.longitude,
      };

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/clients/$clientId/addresses',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final addressData = response.data as Map<String, dynamic>;
        if (addressData['requires_approval'] == true) {
          debugPrint('ClientApiService: Address creation requires approval');
          return null;
        }
        debugPrint('ClientApiService: Address added successfully');
        return Address.fromJson(addressData);
      } else {
        debugPrint('ClientApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to add address: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ClientApiService: DioException - ${e.message}');
      debugPrint('ClientApiService: Response - ${e.response?.data}');
      ErrorLoggingHelper.logCriticalError(
        operation: 'add address',
        error: e,
        stackTrace: StackTrace.current,
        context: {'clientId': clientId},
      );
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to add address',
        originalError: e,
      );
    }
  }

  /// Add a phone number to a client
  Future<PhoneNumber?> addPhoneNumber(String clientId, PhoneNumber phone) async {
    try {
      debugPrint('ClientApiService: Adding phone number for client $clientId...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ClientApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final requestData = {
        'type': phone.type.name,
        'number': phone.number,
        if (phone.label != null) 'label': phone.label,
        'is_primary': phone.isPrimary,
      };

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/clients/$clientId/phones',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final phoneData = response.data as Map<String, dynamic>;
        if (phoneData['requires_approval'] == true) {
          debugPrint('ClientApiService: Phone number creation requires approval');
          return null;
        }
        debugPrint('ClientApiService: Phone number added successfully');
        return PhoneNumber.fromJson(phoneData);
      } else {
        debugPrint('ClientApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to add phone number: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ClientApiService: DioException - ${e.message}');
      debugPrint('ClientApiService: Response - ${e.response?.data}');
      ErrorLoggingHelper.logCriticalError(
        operation: 'add phone number',
        error: e,
        stackTrace: StackTrace.current,
        context: {'clientId': clientId},
      );
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to add phone number',
        originalError: e,
      );
    }
  }

  /// Helper to convert ProductType enum to API value
  String _getProductTypeValue(ProductType type) {
    switch (type) {
      case ProductType.bfpActive:
        return 'BFP ACTIVE';
      case ProductType.bfpPension:
        return 'BFP PENSION';
      case ProductType.pnpPension:
        return 'PNP PENSION';
      case ProductType.napolcom:
        return 'NAPOLCOM';
      case ProductType.bfpStp:
        return 'BFP STP';
    }
  }

  /// Fetch full client records by ID. Used as a last-resort fallback by
  /// the favorites tab when a favorited client is missing from local
  /// PowerSync and Hive cache. Caps at 100 IDs per request.
  Future<List<Client>> fetchClientsByIdsPost(List<String> ids) async {
    if (ids.isEmpty) return [];
    if (ids.length > 100) {
      throw ArgumentError('fetchClientsByIds: max 100 ids per request, got ${ids.length}');
    }

    final token = _authService.accessToken;
    if (token == null) {
      throw ApiException(message: 'Not authenticated - Please login again');
    }

    final response = await _dio.post(
      '${AppConfig.apiBaseUrl}/api/clients/by-ids',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
      data: jsonEncode({'ids': ids}),
    );

    if (response.statusCode == 401) {
      throw ApiException(message: 'Unauthorized', statusCode: 401);
    }
    if (response.statusCode != 200) {
      throw ApiException(
        message: 'fetchClientsByIds failed: ${response.statusCode} ${response.data}',
        statusCode: response.statusCode,
      );
    }

    final data = response.data as Map<String, dynamic>;
    final clientsJson = (data['clients'] as List<dynamic>).cast<Map<String, dynamic>>();
    return clientsJson.map(Client.fromJson).toList();
  }
}

/// Response model for paginated clients list
class ClientsResponse {
  final List<Client> items;
  final int page;
  final int perPage;
  final int totalItems;
  final int totalPages;

  ClientsResponse({
    required this.items,
    required this.page,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
  });

  @override
  String toString() {
    return 'ClientsResponse(items: ${items.length}, page: $page, perPage: $perPage, totalItems: $totalItems, totalPages: $totalPages)';
  }
}

/// Provider for ClientApiService
final clientApiServiceProvider = Provider<ClientApiService>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  return ClientApiService(authService: jwtAuth);
});
