import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Client API service
/// TODO: Phase 1 - Will be updated to work with PowerSync/Supabase backend
class ClientApiService {
  /// Fetch clients with pagination
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<List<Client>> fetchClients({
    int page = 1,
    int perPage = 50,
    String? filter,
    String? sort,
    String? expand,
  }) async {
    try {
      debugPrint('ClientApiService: fetchClients called (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      // For now, return empty list - the app will use local Hive data
      return [];
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch clients',
        originalError: e,
      );
    }
  }

  /// Fetch single client by ID
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<Client?> fetchClient(String id) async {
    try {
      debugPrint('ClientApiService: fetchClient called for $id (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      return null;
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch client',
        originalError: e,
      );
    }
  }

  /// Create a new client
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<Client?> createClient(Client client) async {
    try {
      debugPrint('ClientApiService: createClient called for ${client.fullName} (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase create
      return null;
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to create client',
        originalError: e,
      );
    }
  }

  /// Update an existing client
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<Client?> updateClient(Client client) async {
    try {
      debugPrint('ClientApiService: updateClient called for ${client.id} (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase update
      return null;
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update client',
        originalError: e,
      );
    }
  }

  /// Delete a client
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<void> deleteClient(String id) async {
    try {
      debugPrint('ClientApiService: deleteClient called for $id (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase delete
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to delete client',
        originalError: e,
      );
    }
  }
}

/// Provider for ClientApiService
final clientApiServiceProvider = Provider<ClientApiService>((ref) {
  return ClientApiService();
});
