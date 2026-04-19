import 'package:powersync/powersync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/sync/powersync_service.dart' show powerSyncDatabaseProvider;
import '../../../../services/local_storage/hive_service.dart';
import '../models/address_model.dart';

abstract class AddressRepository {
  Future<List<Address>> getAddresses(String clientId);
  Future<Address?> getPrimaryAddress(String clientId);
  Future<Address> createAddress(String clientId, Map<String, dynamic> data);
  Future<Address> updateAddress(String addressId, Map<String, dynamic> data);
  Future<void> deleteAddress(String addressId);
  Future<Address> setPrimary(String addressId);
}

class PowerSyncAddressRepository implements AddressRepository {
  final PowerSyncDatabase db;

  PowerSyncAddressRepository(this.db);

  @override
  Future<List<Address>> getAddresses(String clientId) async {
    // Primary: Hive cache (has server-side addresses with full PSGC data)
    final hive = HiveService();
    final clientJson = hive.getClient(clientId);
    if (clientJson != null) {
      final addressesJson = clientJson['addresses'] as List? ?? [];
      if (addressesJson.isNotEmpty) {
        return addressesJson
            .map((a) => Address.fromJson(a as Map<String, dynamic>))
            .toList();
      }
    }
    // Fallback: PowerSync SQLite (locally-created addresses when Hive cache is empty)
    final results = await db.getAll(
      'SELECT * FROM addresses WHERE client_id = ? ORDER BY is_primary DESC, created_at ASC',
      [clientId],
    );
    return results.map((row) => Address.fromSyncMap(row)).toList();
  }

  @override
  Future<Address?> getPrimaryAddress(String clientId) async {
    final addresses = await getAddresses(clientId);
    try {
      return addresses.firstWhere((a) => a.isPrimary);
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  @override
  Future<Address> createAddress(String clientId, Map<String, dynamic> data) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    await db.execute(
      'INSERT INTO addresses (id, client_id, type, street, barangay, city, province, postal_code, latitude, longitude, is_primary, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        id,
        clientId,
        data['type'] ?? data['label'],
        data['street'] ?? data['street_address'],
        data['barangay'],
        data['city'] ?? data['municipality'],
        data['province'],
        data['postal_code'],
        data['latitude'],
        data['longitude'],
        data['is_primary'] == true ? 1 : 0,
        now,
      ],
    );

    final result = await db.get('SELECT * FROM addresses WHERE id = ?', [id]);
    if (result == null) throw Exception('Failed to create address');
    final created = Address.fromSyncMap(result);

    // Mirror to Hive client cache
    await _addAddressToHive(clientId, created);

    return created;
  }

  @override
  Future<Address> updateAddress(String addressId, Map<String, dynamic> data) async {
    final updates = <String>[];
    final values = <dynamic>[];

    data.forEach((key, value) {
      if (value != null) {
        updates.add('$key = ?');
        values.add(value);
      }
    });

    if (updates.isEmpty) throw Exception('No fields to update');
    values.add(addressId);

    await db.execute('UPDATE addresses SET ${updates.join(', ')} WHERE id = ?', values);

    final result = await db.get('SELECT * FROM addresses WHERE id = ?', [addressId]);
    if (result == null) throw Exception('Failed to update address');
    final updated = Address.fromSyncMap(result);

    // Mirror to Hive client cache
    await _updateAddressInHive(updated.clientId, updated);

    return updated;
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    // Get clientId before deleting from PowerSync
    final row = await db.get('SELECT client_id FROM addresses WHERE id = ?', [addressId]);
    await db.execute('DELETE FROM addresses WHERE id = ?', [addressId]);

    // Remove from Hive client cache
    if (row != null) {
      await _removeAddressFromHive(row['client_id'] as String, addressId);
    }
  }

  @override
  Future<Address> setPrimary(String addressId) async {
    final row = await db.get('SELECT client_id FROM addresses WHERE id = ?', [addressId]);
    if (row == null) throw Exception('Address not found');
    final clientId = row['client_id'] as String;

    await db.execute('UPDATE addresses SET is_primary = 0 WHERE client_id = ?', [clientId]);
    await db.execute('UPDATE addresses SET is_primary = 1 WHERE id = ?', [addressId]);

    final result = await db.get('SELECT * FROM addresses WHERE id = ?', [addressId]);
    if (result == null) throw Exception('Failed to set primary address');
    final updated = Address.fromSyncMap(result);

    // Update Hive cache: reset all primaries then set this one
    await _setPrimaryAddressInHive(clientId, addressId);

    return updated;
  }

  // ── Hive helpers ──────────────────────────────────────────────────────────

  Future<void> _addAddressToHive(String clientId, Address address) async {
    final hive = HiveService();
    final clientJson = hive.getClient(clientId);
    if (clientJson == null) return;
    final updated = Map<String, dynamic>.from(clientJson);
    final addresses = List<Map<String, dynamic>>.from(
      (updated['addresses'] as List? ?? []).map((a) => Map<String, dynamic>.from(a as Map)),
    );
    addresses.add(address.toJson());
    updated['addresses'] = addresses;
    await hive.saveClient(updated);
  }

  Future<void> _updateAddressInHive(String clientId, Address address) async {
    final hive = HiveService();
    final clientJson = hive.getClient(clientId);
    if (clientJson == null) return;
    final updated = Map<String, dynamic>.from(clientJson);
    final addresses = (updated['addresses'] as List? ?? [])
        .map((a) => Map<String, dynamic>.from(a as Map))
        .toList();
    final idx = addresses.indexWhere((a) => a['id'] == address.id);
    if (idx >= 0) {
      addresses[idx] = address.toJson();
    } else {
      addresses.add(address.toJson());
    }
    updated['addresses'] = addresses;
    await hive.saveClient(updated);
  }

  Future<void> _removeAddressFromHive(String clientId, String addressId) async {
    final hive = HiveService();
    final clientJson = hive.getClient(clientId);
    if (clientJson == null) return;
    final updated = Map<String, dynamic>.from(clientJson);
    final addresses = (updated['addresses'] as List? ?? [])
        .map((a) => Map<String, dynamic>.from(a as Map))
        .where((a) => a['id'] != addressId)
        .toList();
    updated['addresses'] = addresses;
    await hive.saveClient(updated);
  }

  Future<void> _setPrimaryAddressInHive(String clientId, String primaryAddressId) async {
    final hive = HiveService();
    final clientJson = hive.getClient(clientId);
    if (clientJson == null) return;
    final updated = Map<String, dynamic>.from(clientJson);
    final addresses = (updated['addresses'] as List? ?? [])
        .map((a) => Map<String, dynamic>.from(a as Map))
        .toList();
    for (final a in addresses) {
      a['is_primary'] = a['id'] == primaryAddressId;
    }
    updated['addresses'] = addresses;
    await hive.saveClient(updated);
  }
}

// Provider for AddressRepository
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final db = ref.watch(powerSyncDatabaseProvider).value;
  if (db == null) {
    throw Exception('PowerSync database not initialized');
  }
  return PowerSyncAddressRepository(db);
});
