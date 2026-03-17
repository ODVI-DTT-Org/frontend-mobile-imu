import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity status enum
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _statusController = StreamController<ConnectivityStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether currently online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Whether currently offline
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Initialize the connectivity service
  Future<void> initialize() async {
    // Get initial status
    final result = await _connectivity.checkConnectivity();
    _updateStatusFromResult(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _updateStatusFromResult(result);
    });
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }

  /// Check current connectivity status
  Future<ConnectivityStatus> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatusFromResult(result);
    return _currentStatus;
  }

  void _updateStatusFromResult(List<ConnectivityResult> results) {
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final newStatus = _determineStatus(results);

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
    }
  }

  ConnectivityStatus _determineStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }

    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityStatus.online;
    }

    return ConnectivityStatus.unknown;
  }
}

/// Provider for ConnectivityService
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  // Initialize the service when created
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for connectivity status stream
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});

/// Provider for current connectivity status
final isOnlineProvider = Provider<bool>((ref) {
  final statusAsync = ref.watch(connectivityStatusProvider);
  // Default to true if unknown or loading to not block UI unnecessarily
  return statusAsync.maybeWhen(
    data: (status) => status == ConnectivityStatus.online,
    orElse: () => true, // Default to online when loading/unknown
  );
});
