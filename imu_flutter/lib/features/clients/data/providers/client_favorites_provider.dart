import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../shared/providers/app_providers.dart' show currentUserIdProvider;
import '../../../../core/utils/logger.dart';
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
/// PowerSync handles all API uploads automatically.
class ClientFavoritesService {
  final Ref _ref;

  ClientFavoritesService(this._ref);

  Future<void> starClient(String clientId) async {
    logDebug('[ClientFavoritesService] Starting starClient for clientId: $clientId');

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      logError('[ClientFavoritesService] Cannot star client - userId is null');
      throw Exception('User not logged in');
    }

    logDebug('[ClientFavoritesService] userId: $userId');

    try {
      final db = await PowerSyncService.database;
      logDebug('[ClientFavoritesService] Database obtained, executing INSERT');

      // PowerSync requires an id column for all tables
      // Generate a UUID for the local record
      final id = const Uuid().v4();
      logDebug('[ClientFavoritesService] Generated id: $id');

      // Optimistic local insert - PowerSync will upload this automatically
      await db.execute(
        'INSERT OR IGNORE INTO client_favorites (id, user_id, client_id, created_at) VALUES (?, ?, ?, ?)',
        [id, userId, clientId, DateTime.now().toIso8601String()],
      );

      logDebug('[ClientFavoritesService] INSERT executed successfully for clientId: $clientId');
    } catch (e, stackTrace) {
      logError(
        '[ClientFavoritesService] Failed to star client $clientId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> unstarClient(String clientId) async {
    logDebug('[ClientFavoritesService] Starting unstarClient for clientId: $clientId');

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      logError('[ClientFavoritesService] Cannot unstar client - userId is null');
      throw Exception('User not logged in');
    }

    logDebug('[ClientFavoritesService] userId: $userId');

    try {
      final db = await PowerSyncService.database;
      logDebug('[ClientFavoritesService] Database obtained, executing DELETE');

      // Optimistic local delete - PowerSync will upload this automatically
      final result = await db.execute(
        'DELETE FROM client_favorites WHERE user_id = ? AND client_id = ?',
        [userId, clientId],
      );

      logDebug('[ClientFavoritesService] DELETE executed successfully for clientId: $clientId, rows affected: $result');
    } catch (e, stackTrace) {
      logError(
        '[ClientFavoritesService] Failed to unstar client $clientId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}

final clientFavoritesServiceProvider = Provider<ClientFavoritesService>((ref) {
  return ClientFavoritesService(ref);
});

/// Starred clients for the current user.
/// Queries directly from PowerSync (clients + client_favorites tables).
/// This ensures ALL favorited clients are shown, not just those in Hive cache.
final favoritedClientListProvider = StreamProvider<List<Client>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  // Query favorited clients with full details from PowerSync
  return PowerSyncService.database.asStream().asyncExpand((db) {
    return db.watch(
      '''SELECT c.* FROM clients c
         INNER JOIN client_favorites cf ON cf.client_id = c.id
         WHERE cf.user_id = ?
         AND c.deleted_at IS NULL
         ORDER BY c.first_name, c.last_name''',
      parameters: [userId],
    ).map((rows) => rows.map((r) => Client.fromRow(Map<String, dynamic>.from(r))).toList());
  });
});
