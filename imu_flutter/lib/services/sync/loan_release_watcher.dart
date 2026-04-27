import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import '../../core/utils/logger.dart';
import '../../services/local_storage/hive_service.dart';
import '../../shared/providers/app_providers.dart';
import '../../features/clients/data/providers/client_favorites_provider.dart';
import 'powersync_service.dart';

/// Long-lived watcher that listens to local PowerSync `clients` table
/// changes and patches the corresponding Hive entry whenever a row's
/// `loan_released` flips. Keeps the assigned-clients UI (which reads
/// from Hive) in sync with admin approvals/rejections.
///
/// Lifecycle: instantiated by reading `loanReleaseWatcherProvider`
/// after auth completes. Subscription cancels via the Provider's
/// onDispose.
class LoanReleaseWatcher {
  final Ref _ref;
  StreamSubscription? _subscription;
  String? _lastSeenIso;

  LoanReleaseWatcher(this._ref) {
    _start();
  }

  Future<void> _start() async {
    try {
      final db = await PowerSyncService.database;
      _lastSeenIso = DateTime.now().toUtc().toIso8601String();
      _subscription = db.watch(
        '''
        SELECT id, loan_released, loan_released_at, updated_at
        FROM clients
        WHERE updated_at >= ?
        ''',
        parameters: [_lastSeenIso],
      ).listen(_handleChanges, onError: (e, st) {
        logError('[LoanReleaseWatcher] Stream error', e, st);
        // Restart after a short delay
        Future.delayed(const Duration(seconds: 2), _start);
      });
      logDebug('[LoanReleaseWatcher] Started');
    } catch (e, st) {
      logError('[LoanReleaseWatcher] Failed to start', e, st);
    }
  }

  Future<void> _handleChanges(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final hive = HiveService();
    var anyPatched = false;
    for (final row in rows) {
      try {
        final id = row['id'] as String?;
        if (id == null) continue;
        final cached = hive.getClient(id);
        if (cached == null) continue;
        final patched = Map<String, dynamic>.from(cached)
          ..['loan_released'] = row['loan_released']
          ..['loan_released_at'] = row['loan_released_at']
          ..['updated_at'] = row['updated_at'];
        await hive.saveClient(patched);
        anyPatched = true;
      } catch (e, st) {
        logError('[LoanReleaseWatcher] Patch failed for row ${row['id']}', e, st);
        // Don't rethrow — keep processing the rest of the batch
      }
    }
    if (anyPatched) {
      _ref.invalidate(assignedClientsProvider);
      _ref.invalidate(favoritedClientListProvider);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    logDebug('[LoanReleaseWatcher] Disposed');
  }
}

/// Eagerly-started watcher provider. Read this once after auth completes
/// (e.g. in main_shell.dart) so the watcher subscription stays alive for the
/// session. Disposed automatically on logout.
final loanReleaseWatcherProvider = Provider<LoanReleaseWatcher>((ref) {
  // Tear down on logout so we don't leak a subscription tied to the prior user
  ref.listen(currentUserIdProvider, (prev, next) {
    if (prev != null && next == null) {
      ref.invalidateSelf();
    }
  });
  final watcher = LoanReleaseWatcher(ref);
  ref.onDispose(watcher.dispose);
  return watcher;
});
