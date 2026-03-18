import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/core/utils/logger.dart';

/// Development data seeder - populates PowerSync with test data
class DevDataSeeder {
  static const _uuid = Uuid();
  static bool _hasSeeded = false;

  /// Seed development data if in dev mode and not already seeded
  static Future<void> seedIfNeeded() async {
    // Only seed in development mode
    if (AppConfig.environment != 'dev') {
      logDebug('Skipping data seed - not in dev mode');
      return;
    }

    // Only seed once per session
    if (_hasSeeded) {
      logDebug('Data already seeded this session');
      return;
    }

    try {
      final db = await PowerSyncService.database;

      // Check if data already exists
      final existingClients = await db.get('SELECT COUNT(*) as count FROM clients');
      final count = existingClients?['count'] as int? ?? 0;

      if (count > 0) {
        logDebug('Database already has $count clients - skipping seed');
        _hasSeeded = true;
        return;
      }

      logDebug('Seeding development data...');
      await _seedClients(db);
      await _seedItineraries(db);
      _hasSeeded = true;
      logDebug('Development data seeded successfully');
    } catch (e) {
      logError('Failed to seed development data', e);
    }
  }

  static Future<void> _seedClients(db) async {
    final now = DateTime.now().toIso8601String();
    final clients = [
      {
        'id': _uuid.v4(),
        'first_name': 'Juan',
        'last_name': 'Dela Cruz',
        'middle_name': 'Santos',
        'email': 'juan.delacruz@email.com',
        'phone': '+639123456789',
        'client_type': 'EXISTING',
        'product_type': 'PENSION_LOAN',
        'market_type': 'GOVERNMENT',
        'pension_type': 'GSIS',
        'agency_name': 'Philippine National Police',
        'department': 'Retirement Division',
        'position': 'Police Officer III',
        'caravan_id': 'caravan-1',
        'is_starred': 1,
      },
      {
        'id': _uuid.v4(),
        'first_name': 'Maria',
        'last_name': 'Santos',
        'middle_name': 'Reyes',
        'email': 'maria.santos@email.com',
        'phone': '+639234567890',
        'client_type': 'EXISTING',
        'product_type': 'PENSION_LOAN',
        'market_type': 'GOVERNMENT',
        'pension_type': 'SSS',
        'agency_name': 'Department of Education',
        'department': 'Human Resources',
        'position': 'Teacher III',
        'caravan_id': 'caravan-1',
        'is_starred': 0,
      },
      {
        'id': _uuid.v4(),
        'first_name': 'Pedro',
        'last_name': 'Garcia',
        'middle_name': 'Cruz',
        'email': 'pedro.garcia@email.com',
        'phone': '+639345678901',
        'client_type': 'POTENTIAL',
        'product_type': 'CASH_LOAN',
        'market_type': 'PRIVATE',
        'pension_type': 'PRIVATE',
        'agency_name': 'Metro Manila Development Authority',
        'department': 'Operations',
        'position': 'Traffic Enforcer',
        'caravan_id': 'caravan-2',
        'is_starred': 1,
      },
      {
        'id': _uuid.v4(),
        'first_name': 'Ana',
        'last_name': 'Reyes',
        'middle_name': 'Mendoza',
        'email': 'ana.reyes@email.com',
        'phone': '+639456789012',
        'client_type': 'POTENTIAL',
        'product_type': 'PENSION_LOAN',
        'market_type': 'GOVERNMENT',
        'pension_type': 'GSIS',
        'agency_name': 'Bureau of Internal Revenue',
        'department': 'Assessment',
        'position': 'Revenue Officer',
        'caravan_id': 'caravan-1',
        'is_starred': 0,
      },
      {
        'id': _uuid.v4(),
        'first_name': 'Jose',
        'last_name': 'Mendoza',
        'middle_name': 'Torres',
        'email': 'jose.mendoza@email.com',
        'phone': '+639567890123',
        'client_type': 'EXISTING',
        'product_type': 'PENSION_LOAN',
        'market_type': 'GOVERNMENT',
        'pension_type': 'GSIS',
        'agency_name': 'Philippine National Police',
        'department': 'Retirement Division',
        'position': 'Police Senior Sergeant',
        'caravan_id': 'caravan-2',
        'is_starred': 0,
      },
    ];

    for (final client in clients) {
      await db.execute(
        '''INSERT INTO clients (
          id, first_name, last_name, middle_name, email, phone,
          client_type, product_type, market_type, pension_type,
          agency_name, department, position, caravan_id, is_starred, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          client['id'],
          client['first_name'],
          client['last_name'],
          client['middle_name'],
          client['email'],
          client['phone'],
          client['client_type'],
          client['product_type'],
          client['market_type'],
          client['pension_type'],
          client['agency_name'],
          client['department'],
          client['position'],
          client['caravan_id'],
          client['is_starred'],
          now,
          now,
        ],
      );
    }

    logDebug('Seeded ${clients.length} clients');
  }

  static Future<void> _seedItineraries(db) async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final tomorrow = DateTime(now.year, now.month, now.day + 1).toIso8601String().split('T')[0];

    // Get some client IDs
    final clients = await db.getAll('SELECT id FROM clients LIMIT 3');
    if (clients.isEmpty) return;

    final itineraries = [
      {
        'id': _uuid.v4(),
        'client_id': clients[0]['id'],
        'caravan_id': 'caravan-1',
        'scheduled_date': today,
        'scheduled_time': '09:00',
        'status': 'pending',
        'priority': 'high',
        'notes': 'Initial client visit',
      },
      {
        'id': _uuid.v4(),
        'client_id': clients.length > 1 ? clients[1]['id'] : clients[0]['id'],
        'caravan_id': 'caravan-1',
        'scheduled_date': today,
        'scheduled_time': '14:00',
        'status': 'pending',
        'priority': 'normal',
        'notes': 'Follow-up meeting',
      },
      {
        'id': _uuid.v4(),
        'client_id': clients.length > 2 ? clients[2]['id'] : clients[0]['id'],
        'caravan_id': 'caravan-2',
        'scheduled_date': tomorrow,
        'scheduled_time': '10:00',
        'status': 'pending',
        'priority': 'normal',
        'notes': 'Document collection',
      },
    ];

    for (final itinerary in itineraries) {
      await db.execute(
        '''INSERT INTO itineraries (
          id, client_id, caravan_id, scheduled_date, scheduled_time, status, priority, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          itinerary['id'],
          itinerary['client_id'],
          itinerary['caravan_id'],
          itinerary['scheduled_date'],
          itinerary['scheduled_time'],
          itinerary['status'],
          itinerary['priority'],
          itinerary['notes'],
        ],
      );
    }

    logDebug('Seeded ${itineraries.length} itineraries');
  }

  /// Clear all seeded data (for testing)
  static Future<void> clearAll() async {
    try {
      final db = await PowerSyncService.database;
      await db.execute('DELETE FROM itineraries');
      await db.execute('DELETE FROM touchpoints');
      await db.execute('DELETE FROM clients');
      _hasSeeded = false;
      logDebug('Cleared all seeded data');
    } catch (e) {
      logError('Failed to clear seeded data', e);
    }
  }
}
