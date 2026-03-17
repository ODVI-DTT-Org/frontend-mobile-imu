import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';
import '../../../../core/utils/logger.dart';

/// Repository for client CRUD operations using Hive
/// TODO: Phase 2 - Will be updated to use PowerSync
class ClientRepository {
  final HiveService _hiveService;
  final _uuid = const Uuid();

  ClientRepository(this._hiveService);

  /// Watch all clients with real-time updates
  Stream<List<Client>> watchClients() async* {
    // For now, emit the current list and update on changes
    // TODO: Phase 2 - Implement real-time updates with PowerSync
    final clients = await getClients();
    yield clients;
  }

  /// Watch single client by ID
  Stream<Client?> watchClient(String id) async* {
    // TODO: Phase 2 - Implement real-time updates with PowerSync
    final client = await getClient(id);
    yield client;
  }

  /// Get all clients (one-time fetch)
  Future<List<Client>> getClients() async {
    final data = _hiveService.getAllClients();
    return data.map((json) => Client.fromJson(json)).toList();
  }

  /// Get client by ID (one-time fetch)
  Future<Client?> getClient(String id) async {
    final data = _hiveService.getClient(id);
    if (data == null) return null;
    return Client.fromJson(data);
  }

  /// Create a new client (offline-first)
  Future<Client> createClient(Client client) async {
    final id = client.id ?? _uuid.v4();
    final now = DateTime.now();

    final newClient = client.copyWith(
      id: id,
      createdAt: client.createdAt ?? now,
      updatedAt: now,
    );

    await _hiveService.addClient(newClient.toJson());
    logDebug('Created client: $id');
    return newClient;
  }

  /// Update an existing client (offline-first)
  Future<Client> updateClient(Client client) async {
    if (client.id == null) {
      throw ArgumentError('Client ID is required for update');
    }

    final now = DateTime.now();
    final updatedClient = client.copyWith(updatedAt: now);

    await _hiveService.updateClient(client.id!, updatedClient.toJson());
    logDebug('Updated client: ${client.id}');
    return updatedClient;
  }

  /// Delete a client (offline-first)
  Future<void> deleteClient(String id) async {
    await _hiveService.deleteClient(id);
    logDebug('Deleted client: $id');
  }

  /// Toggle client starred status
  Future<void> toggleStar(String id) async {
    final client = await getClient(id);
    if (client == null) return;

    final updatedClient = client.copyWith(isStarred: !client.isStarred);
    await _hiveService.updateClient(id, updatedClient.toJson());
    logDebug('Toggled star for client: $id');
  }

  /// Search clients by name
  Stream<List<Client>> searchClients(String query) async* {
    // TODO: Phase 2 - Implement real-time search with PowerSync
    final clients = await getClients();
    if (query.isEmpty) {
      yield clients;
      return;
    }

    final searchQuery = query.toLowerCase();
    final filtered = clients.where((c) {
      return c.firstName.toLowerCase().contains(searchQuery) ||
          c.lastName.toLowerCase().contains(searchQuery);
    }).toList();
    yield filtered;
  }

  /// Get clients by type
  Stream<List<Client>> watchClientsByType(String clientType) async* {
    // TODO: Phase 2 - Implement with PowerSync
    final clients = await getClients();
    final filtered = clients.where((c) => c.clientType.name == clientType).toList();
    yield filtered;
  }

  /// Get starred clients
  Stream<List<Client>> watchStarredClients() async* {
    // TODO: Phase 2 - Implement with PowerSync
    final clients = await getClients();
    final filtered = clients.where((c) => c.isStarred).toList();
    yield filtered;
  }
}

/// Provider for client repository
final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ClientRepository(hiveService);
});
