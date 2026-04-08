import 'package:powersync/powersync.dart';
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
      'SELECT a.*, p.region, p.province, p.municipality, p.barangay '
      'FROM addresses a '
      'LEFT JOIN psgc p ON a.psgc_id = p.id '
      'WHERE a.client_id = ? AND a.deleted_at IS NULL '
      'ORDER BY a.is_primary DESC, a.created_at ASC',
      [clientId],
    );

    return results.map((row) => Address.fromSyncMap(row)).toList();
  }

  @override
  Future<Address?> getPrimaryAddress(String clientId) async {
    final result = await db.get(
      'SELECT a.*, p.region, p.province, p.municipality, p.barangay '
      'FROM addresses a '
      'LEFT JOIN psgc p ON a.psgc_id = p.id '
      'WHERE a.client_id = ? AND a.is_primary = 1 AND a.deleted_at IS NULL',
      [clientId],
    );

    if (result == null) return null;
    return Address.fromSyncMap(result);
  }

  @override
  Future<Address> createAddress(String clientId, Map<String, dynamic> data) async {
    final id = db.generateUUID();

    await db.execute(
      'INSERT INTO addresses (id, client_id, psgc_id, label, street_address, postal_code, latitude, longitude, is_primary) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        id,
        clientId,
        data['psgc_id'],
        data['label'],
        data['street_address'],
        data['postal_code'],
        data['latitude'],
        data['longitude'],
        data['is_primary'] == true ? 1 : 0,
      ],
    );

    // Fetch the created record with PSGC data
    final result = await db.get(
      'SELECT a.*, p.region, p.province, p.municipality, p.barangay '
      'FROM addresses a '
      'LEFT JOIN psgc p ON a.psgc_id = p.id '
      'WHERE a.id = ?',
      [id],
    );

    if (result == null) {
      throw Exception('Failed to create address');
    }

    return Address.fromSyncMap(result);
  }

  @override
  Future<Address> updateAddress(String addressId, Map<String, dynamic> data) async {
    final updates = <String>[];
    final values = <dynamic>[];
    int paramIndex = 1;

    data.forEach((key, value) {
      if (value != null) {
        updates.add('$key = ?');
        values.add(value);
        paramIndex++;
      }
    });

    if (updates.isEmpty) {
      throw Exception('No fields to update');
    }

    values.add(addressId);

    await db.execute(
      'UPDATE addresses SET ${updates.join(', ')} WHERE id = ?',
      values,
    );

    // Fetch the updated record with PSGC data
    final result = await db.get(
      'SELECT a.*, p.region, p.province, p.municipality, p.barangay '
      'FROM addresses a '
      'LEFT JOIN psgc p ON a.psgc_id = p.id '
      'WHERE a.id = ?',
      [addressId],
    );

    if (result == null) {
      throw Exception('Failed to update address');
    }

    return Address.fromSyncMap(result);
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    await db.execute(
      'UPDATE addresses SET deleted_at = datetime("now") WHERE id = ?',
      [addressId],
    );
  }

  @override
  Future<Address> setPrimary(String addressId) async {
    // First get the address to get client_id
    final address = await db.get(
      'SELECT client_id FROM addresses WHERE id = ?',
      [addressId],
    );

    if (address == null) {
      throw Exception('Address not found');
    }

    // Unset all primaries for this client
    await db.execute(
      'UPDATE addresses SET is_primary = 0 WHERE client_id = ?',
      [address['client_id']],
    );

    // Set this as primary
    await db.execute(
      'UPDATE addresses SET is_primary = 1 WHERE id = ?',
      [addressId],
    );

    // Fetch the updated record
    final result = await db.get(
      'SELECT a.*, p.region, p.province, p.municipality, p.barangay '
      'FROM addresses a '
      'LEFT JOIN psgc p ON a.psgc_id = p.id '
      'WHERE a.id = ?',
      [addressId],
    );

    if (result == null) {
      throw Exception('Failed to set primary address');
    }

    return Address.fromSyncMap(result);
  }
}
