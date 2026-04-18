import 'package:powersync/powersync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/sync/powersync_service.dart' show powerSyncDatabaseProvider;
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
    final results = await db.getAll(
      'SELECT * FROM addresses WHERE client_id = ? ORDER BY is_primary DESC, created_at ASC',
      [clientId],
    );
    return results.map((row) => Address.fromSyncMap(row)).toList();
  }

  @override
  Future<Address?> getPrimaryAddress(String clientId) async {
    final result = await db.get(
      'SELECT * FROM addresses WHERE client_id = ? AND is_primary = 1',
      [clientId],
    );
    if (result == null) return null;
    return Address.fromSyncMap(result);
  }

  @override
  Future<Address> createAddress(String clientId, Map<String, dynamic> data) async {
    final id = const Uuid().v4();

    await db.execute(
      'INSERT INTO addresses (id, client_id, type, street, barangay, city, province, postal_code, latitude, longitude, is_primary) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
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
      ],
    );

    final result = await db.get('SELECT * FROM addresses WHERE id = ?', [id]);
    if (result == null) throw Exception('Failed to create address');
    return Address.fromSyncMap(result);
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
    return Address.fromSyncMap(result);
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    await db.execute('DELETE FROM addresses WHERE id = ?', [addressId]);
  }

  @override
  Future<Address> setPrimary(String addressId) async {
    final address = await db.get('SELECT client_id FROM addresses WHERE id = ?', [addressId]);
    if (address == null) throw Exception('Address not found');

    await db.execute('UPDATE addresses SET is_primary = 0 WHERE client_id = ?', [address['client_id']]);
    await db.execute('UPDATE addresses SET is_primary = 1 WHERE id = ?', [addressId]);

    final result = await db.get('SELECT * FROM addresses WHERE id = ?', [addressId]);
    if (result == null) throw Exception('Failed to set primary address');
    return Address.fromSyncMap(result);
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
