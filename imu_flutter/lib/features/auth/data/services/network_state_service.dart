import 'dart:async';
import 'package:flutter/foundation.dart';

/// Network connectivity status.
enum NetworkStatus {
  /// Network is available and connected
  online,

  /// Network is unavailable or disconnected
  offline,

  /// Unknown network status
  unknown,
}

/// Result of a network connectivity check.
class NetworkCheckResult {
  final bool isOnline;
  final NetworkStatus status;
  final String? errorMessage;
  final DateTime checkedAt;

  const NetworkCheckResult({
    required this.isOnline,
    required this.status,
    this.errorMessage,
    required this.checkedAt,
  });

  factory NetworkCheckResult.online() {
    return NetworkCheckResult(
      isOnline: true,
      status: NetworkStatus.online,
      checkedAt: DateTime.now(),
    );
  }

  factory NetworkCheckResult.offline({String? reason}) {
    return NetworkCheckResult(
      isOnline: false,
      status: NetworkStatus.offline,
      errorMessage: reason,
      checkedAt: DateTime.now(),
    );
  }

  factory NetworkCheckResult.unknown() {
    return NetworkCheckResult(
      isOnline: false,
      status: NetworkStatus.unknown,
      checkedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'NetworkCheckResult(status: $status, isOnline: $isOnline)';
  }
}

/// Service for monitoring network connectivity state.
///
/// Features:
/// - Real-time network status monitoring
/// - Network change event streaming
/// - Manual connectivity checking
/// - Automatic status polling (optional)
///
/// Usage:
/// ```dart
/// // Listen to network status changes
/// networkService.statusStream.listen((status) {
///   if (status == NetworkStatus.online) {
///     // Process offline queue
///   }
/// });
///
/// // Check current status
/// final isOnline = await networkService.checkConnectivity();
/// ```
///
/// Note: This is a mock implementation. In production, use
/// connectivity_plus or similar package for actual network detection.
class NetworkStateService {
  /// Default polling interval for network status checks (30 seconds)
  static const Duration defaultPollingInterval = Duration(seconds: 30);

  Timer? _pollingTimer;
  NetworkStatus _currentStatus = NetworkStatus.unknown;
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  /// Stream of network status changes.
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Current network status.
  NetworkStatus get currentStatus => _currentStatus;

  /// Check if currently online.
  bool get isOnline => _currentStatus == NetworkStatus.online;

  /// Check if currently offline.
  bool get isOffline => _currentStatus == NetworkStatus.offline;

  NetworkStateService();

  /// Initialize the network state service.
  ///
  /// Performs initial connectivity check and starts polling if enabled.
  Future<void> initialize({bool startPolling = false}) async {
    await checkConnectivity();

    if (startPolling) {
      startStatusPolling();
    }
  }

  /// Check current network connectivity.
  ///
  /// Returns true if network is available, false otherwise.
  /// In production, this would make an actual network request.
  Future<bool> checkConnectivity() async {
    // Mock implementation - always returns online
    // In production, use connectivity_plus or make actual HTTP request
    try {
      // Simulate network check delay
      await Future.delayed(const Duration(milliseconds: 100));

      // For now, assume we're always online
      // In production, check actual connectivity
      final isOnline = true;

      final newStatus = isOnline ? NetworkStatus.online : NetworkStatus.offline;

      if (newStatus != _currentStatus) {
        _currentStatus = newStatus;
        _statusController.add(_currentStatus);
      }

      return isOnline;
    } catch (e) {
      _currentStatus = NetworkStatus.unknown;
      _statusController.add(_currentStatus);
      return false;
    }
  }

  /// Perform detailed connectivity check with result.
  Future<NetworkCheckResult> checkConnectivityDetailed() async {
    try {
      final isOnline = await checkConnectivity();

      if (isOnline) {
        return NetworkCheckResult.online();
      } else {
        return NetworkCheckResult.offline(
          reason: 'Network connectivity unavailable',
        );
      }
    } catch (e) {
      return NetworkCheckResult.offline(
        reason: 'Connectivity check failed: $e',
      );
    }
  }

  /// Start automatic status polling.
  ///
  /// Checks network status at regular intervals.
  void startStatusPolling({
    Duration interval = defaultPollingInterval,
  }) {
    stopStatusPolling();

    _pollingTimer = Timer.periodic(interval, (_) {
      checkConnectivity();
    });
  }

  /// Stop automatic status polling.
  void stopStatusPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Manually set network status (for testing).
  @visibleForTesting
  void setNetworkStatus(NetworkStatus status) {
    _currentStatus = status;
    _statusController.add(_currentStatus);
  }

  /// Dispose of resources.
  void dispose() {
    stopStatusPolling();
    _statusController.close();
  }
}
