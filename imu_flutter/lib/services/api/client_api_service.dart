import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';

/// Client API service
class ClientApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  ClientApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  /// Fetch clients from the REST API
  Future<List<Client>> fetchClients({
    int page = 1,
    int perPage = 200,
    String? filter,
    String? sort,
    String? expand,
  }) async {
    try {
      debugPrint('ClientApiService: Fetching clients from REST API...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ClientApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

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
          if (filter != null) 'filter': filter,
          if (sort != null) 'sort': sort,
          if (expand != null) 'expand': expand,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        debugPrint('ClientApiService: Got ${items.length} clients from API');

        return items.map((item) {
          final clientData = item as Map<String, dynamic>;
          debugPrint('ClientApiService: Processing client: ${clientData['first_name']} ${clientData['last_name']}');
          // Use fromRow to handle snake_case from API
          return Client.fromRow(clientData);
        }).toList();
      } else {
        debugPrint('ClientApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch clients: ${response.statusCode}');
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
        message: 'Failed to fetch clients',
        originalError: e,
      );
    }
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
          // Use fromRow to handle snake_case from API
          return Client.fromRow(clientData);
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
        return Client.fromRow(clientData);
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
        // Use fromRow to handle snake_case from API
        return Client.fromRow(clientData);
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
        if (client.productType != ProductType.sssPensioner) 'product_type': _getProductTypeValue(client.productType),
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

      if (response.statusCode == 201) {
        final clientData = response.data as Map<String, dynamic>;
        debugPrint('ClientApiService: Client created successfully: ${clientData['first_name']} ${clientData['last_name']}');
        return Client.fromRow(clientData);
      } else {
        debugPrint('ClientApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to create client: ${response.statusCode}');
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
        if (client.productType != ProductType.sssPensioner) 'product_type': _getProductTypeValue(client.productType),
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
        debugPrint('ClientApiService: Client updated successfully: ${clientData['first_name']} ${clientData['last_name']}');
        return Client.fromRow(clientData);
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

  /// Delete a client
  Future<void> deleteClient(String id) async {
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
        debugPrint('ClientApiService: Client deleted successfully');
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
        return Client.fromRow(clientData);
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

  /// Helper to convert ProductType enum to API value
  String _getProductTypeValue(ProductType type) {
    switch (type) {
      case ProductType.sssPensioner:
        return 'PENSION_LOAN';
      case ProductType.gsisPensioner:
        return 'GSIS_PENSION_LOAN';
      case ProductType.private:
        return 'CASH_LOAN';
    }
  }
}

/// Provider for ClientApiService
final clientApiServiceProvider = Provider<ClientApiService>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  return ClientApiService(authService: jwtAuth);
});
