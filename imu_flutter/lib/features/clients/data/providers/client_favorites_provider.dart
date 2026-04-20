import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../shared/providers/app_providers.dart' show currentUserIdProvider, jwtAuthProvider;
import '../../../../core/config/app_config.dart';
import '../models/client_model.dart';

/// Live set of favorited client IDs for the current user, from PowerSync SQLite.
final clientFavoritesProvider = StreamProvider<Set<String>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value({});
  return PowerSyncService.database.asStream().asyncExpand((db) {
    return db.watch(
      'SELECT client_id FROM client_favorites WHERE user_id = ?',
      parameters: [userId],
    ).map((rows) => rows.map((r) => r['client_id'] as String).toSet());
  });
});

/// Service for starring/unstarring clients with optimistic local SQLite updates.
class ClientFavoritesService {
  final Ref _ref;
  final Dio _dio;

  ClientFavoritesService(this._ref)
      : _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));

  Future<void> starClient(String clientId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    final db = await PowerSyncService.database;

    // Optimistic local insert
    await db.execute(
      'INSERT OR IGNORE INTO client_favorites (id, user_id, client_id, created_at) VALUES (?, ?, ?, ?)',
      [const Uuid().v4(), userId, clientId, DateTime.now().toIso8601String()],
    );

    // Confirm via REST API
    try {
      final token = _ref.read(jwtAuthProvider).accessToken;
      await _dio.post(
        '${AppConfig.postgresApiUrl}/clients/$clientId/favorite',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {
      // Revert optimistic insert on failure
      await db.execute(
        'DELETE FROM client_favorites WHERE user_id = ? AND client_id = ?',
        [userId, clientId],
      );
      rethrow;
    }
  }

  Future<void> unstarClient(String clientId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    final db = await PowerSyncService.database;

    // Snapshot for possible revert
    final existing = await db.getAll(
      'SELECT id FROM client_favorites WHERE user_id = ? AND client_id = ?',
      [userId, clientId],
    );

    // Optimistic local delete
    await db.execute(
      'DELETE FROM client_favorites WHERE user_id = ? AND client_id = ?',
      [userId, clientId],
    );

    // Confirm via REST API
    try {
      final token = _ref.read(jwtAuthProvider).accessToken;
      await _dio.delete(
        '${AppConfig.postgresApiUrl}/clients/$clientId/favorite',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {
      // Revert optimistic delete on failure
      if (existing.isNotEmpty) {
        await db.execute(
          'INSERT OR IGNORE INTO client_favorites (id, user_id, client_id, created_at) VALUES (?, ?, ?, ?)',
          [existing.first['id'], userId, clientId, DateTime.now().toIso8601String()],
        );
      }
      rethrow;
    }
  }
}

final clientFavoritesServiceProvider = Provider<ClientFavoritesService>((ref) {
  return ClientFavoritesService(ref);
});

/// Starred clients for the current user, from PowerSync SQLite.
final starredClientListProvider = StreamProvider<List<Client>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return PowerSyncService.database.asStream().asyncExpand((db) {
    return db.watch(
      '''SELECT c.* FROM clients c
         JOIN client_favorites cf ON cf.client_id = c.id
         WHERE cf.user_id = ?
         AND (c.deleted_at IS NULL)
         ORDER BY c.first_name, c.last_name''',
      parameters: [userId],
    ).map((rows) => rows.map((r) => Client.fromRow(Map<String, dynamic>.from(r))).toList());
  });
});
