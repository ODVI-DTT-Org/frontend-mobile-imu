import 'dart:async';
import 'session_service.dart';

/// Manager for auto-lock functionality.
///
/// Handles:
/// - 15-minute inactivity timer
/// - Auto-lock trigger
/// - Timer reset on activity
class SessionLockManager {
  /// Inactivity duration before auto-lock (15 minutes)
  static const Duration inactivityLockDuration = Duration(minutes: 15);

  final SessionService _sessionService;
  Timer? _inactivityTimer;
  bool _isLocked = false;

  SessionLockManager({
    required SessionService sessionService,
  }) : _sessionService = sessionService;

  /// Start monitoring for inactivity.
  ///
  /// Begins the 15-minute countdown to auto-lock.
  void startMonitoring() {
    _resetInactivityTimer();
  }

  /// Stop monitoring for inactivity.
  ///
  /// Cancels the auto-lock timer.
  void stopMonitoring() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Record user activity and reset timer.
  ///
  /// Called by UserActivityTracker on user interaction.
  void recordActivity() {
    if (!_isLocked) {
      _resetInactivityTimer();
    }
  }

  /// Check if auto-lock should be triggered.
  ///
  /// Returns true if 15 minutes of inactivity have elapsed.
  bool shouldLock() {
    if (_isLocked) return false;

    final lastActivity = _sessionService.lastActivityTime;
    if (lastActivity == null) return false;

    final inactiveDuration = DateTime.now().difference(lastActivity);
    return inactiveDuration >= inactivityLockDuration;
  }

  /// Lock the session.
  ///
  /// Called when inactivity timer expires.
  void lock() {
    _isLocked = true;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Unlock the session.
  ///
  /// Called when user successfully enters PIN or biometric.
  void unlock() {
    _isLocked = false;
    _resetInactivityTimer();
  }

  /// Check if currently locked.
  bool get isLocked => _isLocked;

  /// Get remaining time until auto-lock.
  ///
  /// Returns null if not monitoring.
  Duration? get timeUntilLock {
    if (_inactivityTimer == null || _isLocked) return null;

    final lastActivity = _sessionService.lastActivityTime;
    if (lastActivity == null) return null;

    final inactiveDuration = DateTime.now().difference(lastActivity);
    final remaining = inactivityLockDuration - inactiveDuration;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Reset the inactivity timer.
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityLockDuration, () {
      if (shouldLock()) {
        lock();
      }
    });
  }

  /// Dispose of resources.
  void dispose() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }
}
