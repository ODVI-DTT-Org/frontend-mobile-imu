import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/logger.dart';
import '../models/client_model.dart';
import '../../../../services/sync/powersync_service.dart';

/// Repository for client CRUD operations using PowerSync
class ClientRepository {
  final PowerSyncDatabase _db;
  final _uuid = const Uuid();

  ClientRepository(this._db) : _uuid = const Uuid();

  /// Watch all clients with real-time updates
  Stream<List<Client>> watchClients() {
    return _db.watch(
      'SELECT * FROM clients ORDER BY created_at DESC',
    ).map((rows) => rows.map(Client.fromRow).toList());
  }

  /// Watch single client by ID
  Stream<Client?> watchClient(String id) {
    return _db.watch(
      'SELECT * FROM clients WHERE id = ?',
      [id],
    ).map((rows) {
      if (rows.isEmpty) return null;
      return Client.fromRow(rows.first);
    });
  }

  /// Get all clients (one-time fetch)
  Future<List<Client>> getClients() async {
    final rows = await _db.getAll(
      'SELECT * FROM clients ORDER BY created_at DESC',
    );
    return rows.map(Client.fromRow).toList();
  }

  /// Get client by ID (one-time fetch)
  Future<Client?> getClient(String id) async {
    final row = await _db.getOptional(
      'SELECT * FROM clients WHERE id = ?',
      [id],
    );
    if (row == null) return null;
    return Client.fromRow(row);
  }

  /// Create a new client (offline-first)
  Future<Client> createClient(Client client) async {
    final id = client.id ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.execute(
      '''INSERT INTO clients (
        id, first_name, last_name, middle_name, birth_date, email, phone,
        agency_name, department, position, employment_status, payroll_date, tenure,
        client_type, product_type, market_type, pension_type, pan, facebook_link, remarks,
        agency_id, caravan_id, is_starred, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, now, now)''',
      [
        id,
        client.firstName,
        client.lastName,
        client.middleName,
        client.birthDate,
        client.email,
        client.phone,
        client.agencyName,
        client.department
        client.position,
        client.employmentStatus,
        client.payrollDate,
        client.tenure,
        client.clientType,
        client.productType,
        client.marketType,
        client.pensionType,
        client.pan,
        client.facebookLink,
        client.remarks,
        client.agencyId,
        client.caravanId,
        client.isStarred ? 1 : 0,
        now,
        now,
      ],
    );

    logDebug('Created client: $id');
    return client.copyWith(id: id);
  }

  /// Update an existing client (offline-first)
  Future<Client> updateClient(Client client) async {
    if (client.id == null) {
      throw ArgumentError('Client ID is required for update');
    }

    final now = DateTime.now().toIso8601String();

    await _db.execute(
      '''UPDATE clients SET
        first_name = ?, last_name = ?, middle_name = ?, birth_date = ?,
        email = ?, phone = ?, agency_name = ?, department = ?, position = ?,
        employment_status = ?, payroll_date = ?, tenure = ?, client_type = ?,
        product_type = ?, market_type = ?, pension_type = ?, pan = ?,
        facebook_link = ?, remarks = ?, agency_id = ?, caravan_id = ?,
        is_starred = ?, updated_at = ?
      WHERE id = ?''',
      [
        client.firstName,
        client.lastName,
        client.middleName,
        client.birthDate,
        client.email,
        client.phone,
        client.agencyName,
        client.department
        client.position,
        client.employmentStatus,
        client.payrollDate
        client.tenure,
        client.clientType,
        client.productType,
        client.marketType,
        client.pensionType,
        client.pan,
        client.facebookLink,
        client.remarks,
        client.agencyId,
        client.caravanId,
        client.isStarred ? 1 : 0,
        now,
        client.id,
      ],
    );

    logDebug('Updated client: ${client.id}');
    return client.copyWith(updatedAt: DateTime.parse(now));
  }

  /// Delete a client (offline-first)
  Future<void> deleteClient(String id) async {
    await _db.execute('DELETE FROM clients WHERE id = ?', [id]);
    logDebug('Deleted client: $id');
  }

  /// Toggle client starred status
  Future<void> toggleStar(String id) async {
    await _db.execute(
      'UPDATE clients SET is_starred = NOT is_starred WHERE id = ?',
      [id],
    );
    logDebug('Toggled star for client: $id');
  }

  /// Search clients by name
  Stream<List<Client>> searchClients(String query) {
    final searchQuery = '%$query%';
    return _db.watch(
      'SELECT * FROM clients WHERE first_name LIKE ? OR last_name LIKE ? ORDER BY created_at DESC',
      [searchQuery, searchQuery],
    ).map((rows) => rows.map(Client.fromRow).toList());
  }

  /// Get clients by type
  Stream<List<Client>> watchClientsByType(String clientType) {
    return _db.watch(
      'SELECT * FROM clients WHERE client_type = ? ORDER BY created_at DESC',
      [clientType],
    ).map((rows) => rows.map(Client.fromRow).toList());
  }

  /// Get starred clients
  Stream<List<Client>> watchStarredClients() {
    return _db.watch(
      'SELECT * FROM clients WHERE is_starred = 1 ORDER BY created_at DESC',
    ).map((rows) => rows.map(Client.fromRow).toList());
  }
}

/// Provider for client repository
final clientRepositoryProvider = FutureProvider<ClientRepository>((ref) async {
  final db = await ref.watch(powerSyncDatabaseProvider.future);
  return ClientRepository(db);
});
