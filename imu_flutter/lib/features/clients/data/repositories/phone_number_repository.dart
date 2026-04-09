import 'package:powersync/powersync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/sync/powersync_service.dart' show powerSyncDatabaseProvider;
import '../models/phone_number_model.dart';

abstract class PhoneNumberRepository {
  Future<List<PhoneNumber>> getPhoneNumbers(String clientId);
  Future<PhoneNumber?> getPrimaryPhone(String clientId);
  Future<PhoneNumber> createPhoneNumber(String clientId, Map<String, dynamic> data);
  Future<PhoneNumber> updatePhoneNumber(String phoneId, Map<String, dynamic> data);
  Future<void> deletePhoneNumber(String phoneId);
  Future<PhoneNumber> setPrimary(String phoneId);
}

class PowerSyncPhoneNumberRepository implements PhoneNumberRepository {
  final PowerSyncDatabase db;

  PowerSyncPhoneNumberRepository(this.db);

  @override
  Future<List<PhoneNumber>> getPhoneNumbers(String clientId) async {
    final results = await db.getAll(
      'SELECT * FROM phone_numbers '
      'WHERE client_id = ? AND deleted_at IS NULL '
      'ORDER BY is_primary DESC, created_at ASC',
      [clientId],
    );

    return results.map((row) => PhoneNumber.fromSyncMap(row)).toList();
  }

  @override
  Future<PhoneNumber?> getPrimaryPhone(String clientId) async {
    final result = await db.get(
      'SELECT * FROM phone_numbers '
      'WHERE client_id = ? AND is_primary = 1 AND deleted_at IS NULL',
      [clientId],
    );

    if (result == null) return null;
    return PhoneNumber.fromSyncMap(result);
  }

  @override
  Future<PhoneNumber> createPhoneNumber(String clientId, Map<String, dynamic> data) async {
    final id = const Uuid().v4();

    await db.execute(
      'INSERT INTO phone_numbers (id, client_id, label, number, is_primary) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        id,
        clientId,
        data['label'],
        data['number'],
        data['is_primary'] == true ? 1 : 0,
      ],
    );

    // Fetch the created record
    final result = await db.get(
      'SELECT * FROM phone_numbers WHERE id = ?',
      [id],
    );

    if (result == null) {
      throw Exception('Failed to create phone number');
    }

    return PhoneNumber.fromSyncMap(result);
  }

  @override
  Future<PhoneNumber> updatePhoneNumber(String phoneId, Map<String, dynamic> data) async {
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

    values.add(phoneId);

    await db.execute(
      'UPDATE phone_numbers SET ${updates.join(', ')} WHERE id = ?',
      values,
    );

    // Fetch the updated record
    final result = await db.get(
      'SELECT * FROM phone_numbers WHERE id = ?',
      [phoneId],
    );

    if (result == null) {
      throw Exception('Failed to update phone number');
    }

    return PhoneNumber.fromSyncMap(result);
  }

  @override
  Future<void> deletePhoneNumber(String phoneId) async {
    await db.execute(
      'UPDATE phone_numbers SET deleted_at = datetime("now") WHERE id = ?',
      [phoneId],
    );
  }

  @override
  Future<PhoneNumber> setPrimary(String phoneId) async {
    // First get the phone to get client_id
    final phone = await db.get(
      'SELECT client_id FROM phone_numbers WHERE id = ?',
      [phoneId],
    );

    if (phone == null) {
      throw Exception('Phone number not found');
    }

    // Unset all primaries for this client
    await db.execute(
      'UPDATE phone_numbers SET is_primary = 0 WHERE client_id = ?',
      [phone['client_id']],
    );

    // Set this as primary
    await db.execute(
      'UPDATE phone_numbers SET is_primary = 1 WHERE id = ?',
      [phoneId],
    );

    // Fetch the updated record
    final result = await db.get(
      'SELECT * FROM phone_numbers WHERE id = ?',
      [phoneId],
    );

    if (result == null) {
      throw Exception('Failed to set primary phone number');
    }

    return PhoneNumber.fromSyncMap(result);
  }
}

// Provider for PhoneNumberRepository
final phoneNumberRepositoryProvider = Provider<PhoneNumberRepository>((ref) {
  final db = ref.watch(powerSyncDatabaseProvider).value;
  if (db == null) {
    throw Exception('PowerSync database not initialized');
  }
  return PowerSyncPhoneNumberRepository(db);
});
