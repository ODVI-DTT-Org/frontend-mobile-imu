import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/services/offline_credential_storage_service.dart';
import '../data/services/offline_sync_queue_service.dart';
import '../data/services/network_state_service.dart';
import '../entities/auth_state.dart';

/// Result of an offline authentication attempt.
class OfflineAuthResult {
  final bool success;
  final String? userId;
  final String? error;
  final Duration? remainingGracePeriod;

  const OfflineAuthResult({
    required this.success,
    this.userId,
    this.error,
    this.remainingGracePeriod,
  });

  factory OfflineAuthResult.success({
    required String userId,
    Duration? remainingGracePeriod,
  }) {
    return OfflineAuthResult(
      success: true,
      userId: userId,
      remainingGracePeriod: remainingGracePeriod,
    );
  }

  factory OfflineAuthResult.failure(String error) {
    return OfflineAuthResult(
      success: false,
      error: error,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'OfflineAuthResult.success(userId: $userId)';
    } else {
      return 'OfflineAuthResult.failure: $error';
    }
  }
}

/// Manager for offline authentication operations.
///
/// Coordinates offline credential storage, sync queue, and network state
/// to provide seamless offline authentication experience.
///
/// Features:
/// - Offline authentication with grace period
/// - Automatic sync queue processing when network becomes available
/// - Grace period tracking and expiration handling
/// - Network state monitoring
/// - Automatic credential cleanup on expiry
///
/// Security considerations:
/// - Grace period limited to 24 hours
/// - Credentials only used for offline mode
/// - Automatic cleanup when grace period expires
/// - Integrity validation for stored credentials
class OfflineAuthManager {
  final OfflineCredentialStorageService _credentialStorage;
  final OfflineSyncQueueService _syncQueue;
  final NetworkStateService _networkService;

  StreamSubscription<NetworkStatus>? _networkSubscription;
  bool _isProcessingQueue = false;

  OfflineAuthManager({
    required OfflineCredentialStorageService credentialStorage,
    required OfflineSyncQueueService syncQueue,
    required NetworkStateService networkService,
  })  : _credentialStorage = credentialStorage,
        _syncQueue = syncQueue,
        _networkService = networkService;

  /// Initialize the offline auth manager.
  ///
  /// Loads offline credentials and starts network monitoring.
  Future<void> initialize() async {
    await _syncQueue.initialize();
    await _networkService.initialize(startPolling: true);

    // Listen for network status changes
    _networkSubscription = _networkService.statusStream.listen((status) {
      if (status == NetworkStatus.online && !_isProcessingQueue) {
        // Network became available, process sync queue
        _processSyncQueueWhenOnline();
      }
    });
  }

  /// Attempt offline authentication.
  ///
  /// Returns success result if valid offline credentials exist
  /// and grace period hasn't expired.
  Future<OfflineAuthResult> authenticateOffline() async {
    final credentials = await _credentialStorage.getOfflineCredentials();

    if (credentials == null) {
      return OfflineAuthResult.failure(
        'No offline credentials available',
      );
    }

    if (credentials.isGracePeriodExpired) {
      // Grace period expired, clear credentials
      await _credentialStorage.clearOfflineCredentials();
      return OfflineAuthResult.failure(
        'Grace period has expired. Please connect to the internet.',
      );
    }

    // Validate credential integrity
    final isValid = await _credentialStorage.validateCredentialsIntegrity();
    if (!isValid) {
      return OfflineAuthResult.failure(
        'Credential integrity validation failed',
      );
    }

    return OfflineAuthResult.success(
      userId: credentials.userId,
      remainingGracePeriod: credentials.remainingGracePeriod,
    );
  }

  /// Store credentials for offline authentication.
  ///
  /// Should be called after successful online authentication.
  Future<void> storeOfflineCredentials({
    required String accessToken,
    required String refreshToken,
    required String userId,
    Duration gracePeriod = OfflineCredentialStorageService.defaultGracePeriod,
  }) async {
    await _credentialStorage.storeOfflineCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      gracePeriod: gracePeriod,
    );
  }

  /// Check if offline authentication is available.
  Future<bool> isOfflineAuthAvailable() async {
    return await _credentialStorage.isOfflineAuthAvailable();
  }

  /// Get remaining grace period.
  ///
  /// Returns null if no offline credentials are stored.
  Future<Duration?> getRemainingGracePeriod() async {
    return await _credentialStorage.getRemainingGracePeriod();
  }

  /// Add an operation to the offline sync queue.
  ///
  /// Returns true if operation was added successfully.
  /// Returns false if queue is full.
  Future<bool> queueOperation(SyncOperation operation) async {
    return await _syncQueue.addOperation(operation);
  }

  /// Process the offline sync queue.
  ///
  /// Attempts to sync all pending operations with the server.
  /// Should be called when network becomes available.
  Future<List<SyncResult>> processSyncQueue(
    Future<SyncResult> Function(SyncOperation) syncFunction,
  ) async {
    if (_isProcessingQueue) {
      return [];
    }

    _isProcessingQueue = true;

    try {
      final results = await _syncQueue.processQueue(syncFunction);

      // If all operations succeeded, we're done
      final allSuccess = results.every((r) => r.success);
      if (allSuccess) {
        // Queue is now empty
        return results;
      }

      // Some operations failed, keep them in queue for next retry
      return results;
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Get sync queue statistics.
  Map<String, dynamic> getSyncQueueStats() {
    return _syncQueue.getQueueStats();
  }

  /// Get current network status.
  NetworkStatus getNetworkStatus() {
    return _networkService.currentStatus;
  }

  /// Check if currently online.
  bool get isOnline => _networkService.isOnline;

  /// Check if currently offline.
  bool get isOffline => _networkService.isOffline;

  /// Clear offline credentials and sync queue.
  ///
  /// Should be called when user logs out.
  Future<void> clearOfflineData() async {
    await _credentialStorage.clearOfflineCredentials();
    await _syncQueue.clearQueue();
  }

  /// Process sync queue when network becomes available.
  Future<void> _processSyncQueueWhenOnline() async {
    if (_syncQueue.pendingOperationCount > 0) {
      // Note: The actual sync function should be provided by the caller
      // This is a placeholder for the sync operation
      // In production, this would be integrated with the API layer
    }
  }

  /// Get offline authentication timestamp.
  Future<DateTime?> getOfflineAuthTimestamp() async {
    return await _credentialStorage.getOfflineAuthTimestamp();
  }

  /// Validate offline credentials integrity.
  Future<bool> validateCredentialsIntegrity() async {
    return await _credentialStorage.validateCredentialsIntegrity();
  }

  /// Dispose of resources.
  void dispose() {
    _networkSubscription?.cancel();
    _networkService.dispose();
    _syncQueue.dispose();
    _credentialStorage.dispose();
  }
}
