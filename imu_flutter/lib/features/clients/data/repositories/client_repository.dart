import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/services/search/fuzzy_search_service.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';
import '../../../../core/utils/logger.dart';

/// Repository for client CRUD operations using PowerSync
class ClientRepository {
  final _uuid = const Uuid();

  /// Watch all clients with real-time updates from PowerSync
  Stream<List<Client>> watchClients() async* {
    try {
      final db = await PowerSyncService.database;
      await for (final row in db.watch('SELECT * FROM clients')) {
        final clients = row.map(Client.fromRow).toList();
        yield clients;
      }
    } catch (e) {
      logError('Error watching clients', e);
      yield [];
    }
  }

  /// Watch single client by ID
  Stream<Client?> watchClient(String id) async* {
    try {
      final db = await PowerSyncService.database;
      await for (final row in db.watch(
        'SELECT * FROM clients WHERE id = ?',
        parameters: [id],
      )) {
        yield row.isNotEmpty ? Client.fromRow(row.first) : null;
      }
    } catch (e) {
      logError('Error watching client $id', e);
      yield null;
    }
  }

  /// Get all clients (one-time fetch)
  Future<List<Client>> getClients() async {
    try {
      final db = await PowerSyncService.database;
      final results = await db.getAll('SELECT * FROM clients');
      return results.map(Client.fromRow).toList();
    } catch (e) {
      logError('Error getting clients', e);
      return [];
    }
  }

  /// Get client by ID — Hive first (has embedded addresses/phones), SQLite fallback
  Future<Client?> getClient(String id) async {
    try {
      final cached = HiveService().getClient(id);
      if (cached != null) return Client.fromJson(cached);

      final db = await PowerSyncService.database;
      final results = await db.getAll(
        'SELECT * FROM clients WHERE id = ?',
        [id],
      );
      return results.isNotEmpty ? Client.fromRow(results.first) : null;
    } catch (e) {
      logError('Error getting client $id', e);
      return null;
    }
  }

  /// Search clients by query
  Future<List<Client>> searchClients(String searchQuery) async {
    try {
      final db = await PowerSyncService.database;
      final results = await db.getAll(
        '''SELECT * FROM clients
           WHERE first_name LIKE ?
           OR last_name LIKE ?
           OR email LIKE ?
           OR phone LIKE ?''',
        ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%', '%$searchQuery%'],
      );
      return results.map(Client.fromRow).toList();
    } catch (e) {
      logError('Error searching clients', e);
      return [];
    }
  }

  /// Search assigned clients using fuzzy name matching (offline)
  /// Uses FuzzySearchService for typo-tolerant local search
  Future<List<Client>> searchAssignedClients(String searchQuery) async {
    try {
      // Prefer Hive cache (has embedded addresses/phones + is the primary read source)
      final hive = HiveService();
      final rawClients = hive.getAllClients();
      final allClients = rawClients.isNotEmpty
          ? rawClients.map((json) => Client.fromJson(json)).toList()
          : (await (await PowerSyncService.database).getAll('SELECT * FROM clients'))
              .map(Client.fromRow)
              .toList();

      // Use fuzzy search for offline matching
      final fuzzyService = FuzzySearchService(allClients);
      return fuzzyService.searchByName(searchQuery);
    } catch (e) {
      logError('Error searching assigned clients', e);
      return [];
    }
  }

  /// Get clients by type
  Stream<List<Client>> watchClientsByType(String clientType) async* {
    try {
      final db = await PowerSyncService.database;
      await for (final row in db.watch(
        'SELECT * FROM clients WHERE client_type = ?',
        parameters: [clientType],
      )) {
        yield row.map(Client.fromRow).toList();
      }
    } catch (e) {
      logError('Error watching clients by type', e);
      yield [];
    }
  }

  /// Get starred clients
  Stream<List<Client>> watchStarredClients() async* {
    try {
      final db = await PowerSyncService.database;
      await for (final row in db.watch(
        'SELECT * FROM clients WHERE is_starred = 1',
      )) {
        yield row.map(Client.fromRow).toList();
      }
    } catch (e) {
      logError('Error watching starred clients', e);
      yield [];
    }
  }

  /// Create a new client
  Future<Client> createClient(Client client) async {
    try {
      final db = await PowerSyncService.database;
      final id = (client.id == null || client.id!.isEmpty) ? _uuid.v4() : client.id!;
      final now = DateTime.now().toIso8601String();

      await db.execute(
        '''INSERT INTO clients (
          id, first_name, last_name, middle_name, birth_date, email, phone,
          agency_name, department, position, employment_status, payroll_date,
          tenure, client_type, product_type, market_type, pension_type, loan_type, pan,
          facebook_link, remarks, agency_id, psgc_id, province, municipality, region,
          barangay, udi, loan_released, loan_released_at, is_starred,
          created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          id,
          client.firstName,
          client.lastName,
          client.middleName,
          client.birthDate?.toIso8601String(),
          client.email,
          client.phone,
          client.agencyName,
          client.department,
          client.position,
          client.employmentStatus,
          client.payrollDate,
          client.tenure,
          client.clientType.name,
          client.productType.name,
          client.marketType?.name,
          client.pensionType.name,
          client.loanType?.name,
          client.pan,
          client.facebookLink,
          client.remarks,
          client.agencyId,
          client.psgcId,
          client.province,
          client.municipality,
          client.region,
          client.barangay,
          client.udi,
          client.loanReleased ? 1 : 0,
          client.loanReleasedAt?.toIso8601String(),
          client.isStarred ? 1 : 0,
          now,
          now,
        ],
      );

      logDebug('Created client: $id');
      final created = client.copyWith(id: id, createdAt: DateTime.parse(now));
      // Mirror to Hive cache so the client list shows the new entry immediately
      try {
        await HiveService().saveClient(created.toJson());
      } catch (e) {
        logError('Failed to mirror created client to Hive cache', e);
      }
      return created;
    } catch (e) {
      logError('Error creating client', e);
      rethrow;
    }
  }

  /// Update an existing client
  Future<void> updateClient(Client client) async {
    try {
      final db = await PowerSyncService.database;

      await db.execute(
        '''UPDATE clients SET
          first_name = ?, last_name = ?, middle_name = ?, birth_date = ?,
          email = ?, phone = ?, agency_name = ?, department = ?,
          position = ?, employment_status = ?, payroll_date = ?, tenure = ?,
          client_type = ?, product_type = ?, market_type = ?, pension_type = ?,
          loan_type = ?, pan = ?, facebook_link = ?, remarks = ?, agency_id = ?,
          psgc_id = ?, province = ?, municipality = ?, region = ?, barangay = ?,
          udi = ?, loan_released = ?, loan_released_at = ?,
          is_starred = ?, updated_at = ?
        WHERE id = ?''',
        [
          client.firstName,
          client.lastName,
          client.middleName,
          client.birthDate?.toIso8601String(),
          client.email,
          client.phone,
          client.agencyName,
          client.department,
          client.position,
          client.employmentStatus,
          client.payrollDate,
          client.tenure,
          client.clientType.name,
          client.productType.name,
          client.marketType?.name,
          client.pensionType.name,
          client.loanType?.name,
          client.pan,
          client.facebookLink,
          client.remarks,
          client.agencyId,
          client.psgcId,
          client.province,
          client.municipality,
          client.region,
          client.barangay,
          client.udi,
          client.loanReleased ? 1 : 0,
          client.loanReleasedAt?.toIso8601String(),
          client.isStarred ? 1 : 0,
          DateTime.now().toIso8601String(),
          client.id,
        ],
      );

      logDebug('Updated client: ${client.id}');
      // Mirror to Hive cache
      try {
        await HiveService().saveClient(client.toJson());
      } catch (e) {
        logError('Failed to mirror updated client to Hive cache', e);
      }
    } catch (e) {
      logError('Error updating client', e);
      rethrow;
    }
  }

  /// Delete a client
  Future<void> deleteClient(String id) async {
    try {
      final db = await PowerSyncService.database;
      await db.execute('DELETE FROM clients WHERE id = ?', [id]);
      logDebug('Deleted client: $id');
      // Remove from Hive cache
      try {
        await HiveService().removeClient(id);
      } catch (e) {
        logError('Failed to remove deleted client from Hive cache', e);
      }
    } catch (e) {
      logError('Error deleting client', e);
      rethrow;
    }
  }

  /// Toggle client star status
  Future<void> toggleStar(String id) async {
    try {
      final db = await PowerSyncService.database;
      await db.execute(
        'UPDATE clients SET is_starred = CASE WHEN is_starred = 1 THEN 0 ELSE 1 END WHERE id = ?',
        [id],
      );
      logDebug('Toggled star for client: $id');
    } catch (e) {
      logError('Error toggling star', e);
      rethrow;
    }
  }

  /// Get clients count
  Future<int> getClientsCount() async {
    try {
      final db = await PowerSyncService.database;
      final results = await db.get('SELECT COUNT(*) as count FROM clients');
      return results?['count'] as int? ?? 0;
    } catch (e) {
      logError('Error getting clients count', e);
      return 0;
    }
  }
}

/// Provider for client repository
final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository();
});
