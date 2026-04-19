import 'package:powersync/powersync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/sync/powersync_service.dart' show powerSyncDatabaseProvider;
import '../../../../services/local_storage/hive_service.dart';
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
    // Primary: Hive cache
    final hive = HiveService();
    final clientJson = hive.getClient(clientId);
    if (clientJson != null) {
      final phonesJson = clientJson['phone_numbers'] as List? ?? [];
      if (phonesJson.isNotEmpty) {
        return phonesJson
            .map((p) => PhoneNumber.fromJson(p as Map<String, dynamic>))
            .toList();
      }
    }
    // Fallback: PowerSync SQLite (locally-created phone numbers when Hive is empty)
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
    final phones = await getPhoneNumbers(clientId);
    try {
      return phones.firstWhere((p) => p.isPrimary);
    } catch (_) {
      return phones.isNotEmpty ? phones.first : null;
    }
  }

  @override
  Future<PhoneNumber> createPhoneNumber(String clientId, Map<String, dynamic> data) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    await db.execute(
      'INSERT INTO phone_numbers (id, client_id, label, number, is_primary, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [
        id,
        clientId,
        data['label'],
        data['number'],
        data['is_primary'] == true ? 1 : 0,
        now,
      ],
    );

    final result = await db.get('SELECT * FROM phone_numbers WHERE id = ?', [id]);
    if (result == null) throw Exception('Failed to create phone number');
    final created = PhoneNumber.fromSyncMap(result);

    await _addPhoneToHive(clientId, created);

    return created;
  }

  @override
  Future<PhoneNumber> updatePhoneNumber(String phoneId, Map<String, dynamic> data) async {
    final updates = <String>[];
    final values = <dynamic>[];

    data.forEach((key, value) {
      if (value != null) {
        updates.add('$key = ?');
        values.add(value);
      }
    });

    if (updates.isEmpty) throw Exception('No fields to update');
    values.add(phoneId);

    await db.execute(
      'UPDATE phone_numbers SET ${updates.join(', ')} WHERE id = ?',
      values,
    );

    final result = await db.get('SELECT * FROM phone_numbers WHERE id = ?', [phoneId]);
    if (result == null) throw Exception('Failed to update phone number');
    final updated = PhoneNumber.fromSyncMap(result);

    await _updatePhoneInHive(updated.clientId, updated);

    return updated;
  }

  @override
  Future<void> deletePhoneNumber(String phoneId) async {
    final row = await db.get('SELECT client_id FROM phone_numbers WHERE id = ?', [phoneId]);
    await db.execute(
      'UPDATE phone_numbers SET deleted_at = datetime("now") WHERE id = ?',
      [phoneId],
    );
    if (row != null) {
      await _removePhoneFromHive(row['client_id'] as String, phoneId);
    }
  }

  @override
  Future<PhoneNumber> setPrimary(String phoneId) async {
    final row = await db.get('SELECT client_id FROM phone_numbers WHERE id = ?', [phoneId]);
    if (row == null) throw Exception('Phone number not found');
    final clientId = row['client_id'] as String;

    await db.execute('UPDATE phone_numbers SET is_primary = 0 WHERE client_id = ?', [clientId]);
    await db.execute('UPDATE phone_numbers SET is_primary = 1 WHERE id = ?', [phoneId]);

    final result = await db.get('SELECT * FROM phone_numbers WHERE id = ?', [phoneId]);
    if (result == null) throw Exception('Failed to set primary phone number');
    final updated = PhoneNumber.fromSyncMap(result);

    await _setPrimaryPhoneInHive(clientId, phoneId);

    return updated;
  }

  // ── Hive helpers ──────────────────────────────────────────────────────────

  Future<void> _addPhoneToHive(String clientId, PhoneNumber phone) async {
    final hive = HiveService();
    final clientJson = hive.getClient(clientId);
    if (clientJson == null) return;
    final updated = Map<String, dynamic>.from(clientJson);
    final phones = List<Map<String, dynamic>>.from(
      (updated['phone_numbers'] as List? ?? []).map((p) => Map<String, dynamic>.from(p as Map)),
    );
    phones.add(phone.toJson());
    updated['phone_numbers'] = phones;
    await hive.saveClient(updated);
  }

  Future<void> _updatePhoneInHive(String clientId, PhoneNumber phone) async {
    final hive = HiveService();
    final clientJson = hive.getClient(clientId);
    if (clientJson == null) return;
    final updated = Map<String, dynamic>.from(clientJson);
    final phones = (updated['phone_numbers'] as List? ?? [])
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();
    final idx = phones.indexWhere((p) => p['id'] == phone.id);
    if (idx >= 0) {
      phones[idx] = phone.toJson();
    } else {
      phones.add(phone.toJson());
    }
    updated['phone_numbers'] = phones;
    await hive.saveClient(updated);
  }

  Future<void> _removePhoneFromHive(String clientId, String phoneId) async {
    final hive = HiveService();
    final clientJson = hive.getClient(clientId);
    if (clientJson == null) return;
    final updated = Map<String, dynamic>.from(clientJson);
    final phones = (updated['phone_numbers'] as List? ?? [])
        .map((p) => Map<String, dynamic>.from(p as Map))
        .where((p) => p['id'] != phoneId)
        .toList();
    updated['phone_numbers'] = phones;
    await hive.saveClient(updated);
  }

  Future<void> _setPrimaryPhoneInHive(String clientId, String primaryPhoneId) async {
    final hive = HiveService();
    final clientJson = hive.getClient(clientId);
    if (clientJson == null) return;
    final updated = Map<String, dynamic>.from(clientJson);
    final phones = (updated['phone_numbers'] as List? ?? [])
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();
    for (final p in phones) {
      p['is_primary'] = p['id'] == primaryPhoneId;
    }
    updated['phone_numbers'] = phones;
    await hive.saveClient(updated);
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
