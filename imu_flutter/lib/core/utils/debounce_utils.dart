import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debounce utility for delaying function execution until after a specified delay
/// has elapsed since the last call.
///
/// Usage:
/// ```dart
/// final debouncedSearch = Debounce(milliseconds: 300);
///
/// // In onChanged callback
/// debouncedSearch.run(() {
///   performSearch();
/// });
///
/// // Don't forget to dispose
/// @override
/// void dispose() {
///   debouncedSearch.dispose();
///   super.dispose();
/// }
/// ```
class Debounce {
  final Duration delay;
  Timer? _timer;
  bool _disposed = false;

  /// Create a debounce with a Duration or milliseconds
  /// Use either:
  /// - Debounce(delay: Duration(seconds: 1))
  /// - Debounce(milliseconds: 300)
  Debounce({Duration? delay, int? milliseconds}) :
      delay = milliseconds != null ? Duration(milliseconds: milliseconds) : (delay ?? const Duration(milliseconds: 300));

  /// Run the given function after the delay, cancelling any pending calls
  void run(VoidCallback action) {
    if (_disposed) {
      debugPrint('[Debounce] Warning: Attempting to run on disposed Debounce instance');
      return;
    }

    _timer?.cancel();
    _timer = Timer(delay, () {
      if (!_disposed) {
        action();
      }
    });
  }

  /// Cancel any pending execution
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Check if there's a pending execution
  bool get isPending => _timer?.isActive ?? false;

  /// Dispose the debounce instance and cancel any pending execution
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  /// Check if the debounce instance has been disposed
  bool get isDisposed => _disposed;
}

/// Factory for creating debounced callbacks
///
/// Usage:
/// ```dart
/// final searchDebouncer = DebouncerFactory.create(milliseconds: 300);
///
/// // Later
/// searchDebouncer(() {
///   performSearch();
/// });
/// ```
class DebouncerFactory {
  /// Create a debounced function with the specified delay
  static DebouncedCallback create({
    required Duration delay,
    required VoidCallback callback,
  }) {
    final debounce = Debounce(delay: delay);
    return () => debounce.run(callback);
  }
}

/// Type alias for a debounced callback function
typedef DebouncedCallback = void Function();
