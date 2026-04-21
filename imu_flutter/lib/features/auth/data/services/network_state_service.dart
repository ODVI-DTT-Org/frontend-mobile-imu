import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Network status enumeration.
enum NetworkStatus {
  online,
  offline,
  unknown,
}

/// Real implementation for network state monitoring using connectivity_plus.
///
/// Monitors network connectivity changes and provides real-time status updates.
class NetworkStateService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkStatus> _statusController = StreamController.broadcast();
  NetworkStatus _currentStatus = NetworkStatus.unknown;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Stream of network status changes.
  Stream<NetworkStatus> get onNetworkStatusChange => _statusController.stream;

  /// Stream of network status (alias for onNetworkStatusChange).
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Get current network status (synchronous).
  NetworkStatus get currentStatus => _currentStatus;

  /// Check if currently offline.
  bool get isOffline => _isOffline;

  /// Check if currently online.
  bool get isOnline => !_isOffline;

  /// Initialize the service and start monitoring network changes.
  Future<void> initialize({bool startPolling = false}) async {
    final result = await _connectivity.checkConnectivity();
    _currentStatus = _mapToStatus(result);
    _isOffline = _currentStatus == NetworkStatus.offline;
    _statusController.add(_currentStatus);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final newStatus = _mapToStatus(result);
      if (newStatus != _currentStatus) {
        _currentStatus = newStatus;
        _isOffline = newStatus == NetworkStatus.offline;
        _statusController.add(newStatus);
      }
    });

    if (startPolling) {
      startStatusPolling();
    }
  }

  /// Map ConnectivityResult to NetworkStatus.
  NetworkStatus _mapToStatus(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.online;
  }

  /// Get current network status.
  Future<NetworkStatus> getNetworkStatus() async {
    final result = await _connectivity.checkConnectivity();
    return _mapToStatus(result);
  }

  /// Check if device is online.
  Future<bool> checkConnectivity() async {
    final status = await getNetworkStatus();
    return status == NetworkStatus.online;
  }

  /// Start monitoring (already started in initialize).
  void startMonitoring() {
    // Already listening in initialize
  }

  /// Start periodic status polling (optional - not needed with connectivity_plus).
  void startStatusPolling() {
    // ConnectivityPlus already provides real-time updates
    // This is kept for compatibility with the interface
  }

  /// Stop monitoring network status.
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
  }

  /// Dispose resources.
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}
