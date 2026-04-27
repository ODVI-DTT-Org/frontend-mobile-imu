/// Status returned by the pending-upload guard at app startup.
enum PendingUploadStatus {
  /// No pending uploads — safe to proceed.
  clean,
  /// Pending uploads exist and we're online — flush them, then proceed.
  flushing,
  /// Pending uploads exist and we're offline — block app startup with a
  /// dialog asking the user to connect, otherwise their writes will be
  /// lost when PowerSync's checkpoint resets.
  mustWait,
}

/// Pre-flight check for the Edition 2 → 3 sync-rule migration. Run at
/// app startup before connecting PowerSync.
class PendingUploadGuard {
  static Future<PendingUploadStatus> check({
    required Future<int> Function() pendingCountProvider,
    required bool Function() isOnlineProvider,
  }) async {
    final pending = await pendingCountProvider();
    if (pending == 0) return PendingUploadStatus.clean;
    if (!isOnlineProvider()) return PendingUploadStatus.mustWait;
    return PendingUploadStatus.flushing;
  }
}
