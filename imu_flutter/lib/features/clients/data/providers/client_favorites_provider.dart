import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../shared/providers/app_providers.dart' show currentUserIdProvider;
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
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    final db = await PowerSyncService.database;

    // Optimistic local insert - PowerSync will upload this automatically
    // Don't insert with explicit id - let PowerSync handle it
    await db.execute(
      'INSERT OR IGNORE INTO client_favorites (user_id, client_id, created_at) VALUES (?, ?, ?)',
      [userId, clientId, DateTime.now().toIso8601String()],
    );

    // PowerSync will automatically upload this change to the server
    // No direct API call needed - prevents duplicate requests
  }

  Future<void> unstarClient(String clientId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    final db = await PowerSyncService.database;

    // Optimistic local delete - PowerSync will upload this automatically
    await db.execute(
      'DELETE FROM client_favorites WHERE user_id = ? AND client_id = ?',
      [userId, clientId],
    );

    // PowerSync will automatically upload this change to the server
    // No direct API call needed - prevents duplicate requests
  }
}

final clientFavoritesServiceProvider = Provider<ClientFavoritesService>((ref) {
  return ClientFavoritesService(ref);
});

/// Starred clients for the current user, from PowerSync SQLite.
final favoritedClientListProvider = StreamProvider<List<Client>>((ref) {
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
