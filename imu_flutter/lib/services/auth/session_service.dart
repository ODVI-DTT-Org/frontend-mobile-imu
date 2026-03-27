import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Session service for auto-lock functionality
class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  Timer? _inactivityTimer;
  Timer? _sessionTimer;
  DateTime? _lastActivityTime;
  DateTime? _sessionStartTime;

  // Configuration
  static const Duration inactivityTimeout = Duration(minutes: 15);
  static const Duration sessionTimeout = Duration(hours: 8);

  // State
  bool _isLocked = false;
  bool _isSessionValid = true;

  // Getters
  bool get isLocked => _isLocked;
  bool get isSessionValid => _isSessionValid;
  DateTime? get lastActivityTime => _lastActivityTime;
  DateTime? get sessionStartTime => _sessionStartTime;
  Duration get remainingTime {
    if (_lastActivityTime == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastActivityTime!);
    final remaining = inactivityTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Start session (call on login/PIN entry)
  void startSession() {
    _isLocked = false;
    _isSessionValid = true;
    _sessionStartTime = DateTime.now();
    _lastActivityTime = DateTime.now();

    _startInactivityTimer();
    _startSessionTimer();

    notifyListeners();
    debugPrint('Session started');
  }

  /// Record user activity (resets inactivity timer)
  void recordActivity() {
    if (_isLocked || !_isSessionValid) return;

    _lastActivityTime = DateTime.now();
    _resetInactivityTimer();
  }

  /// Lock session (require PIN to resume)
  void lockSession() {
    _isLocked = true;
    _inactivityTimer?.cancel();
    notifyListeners();
    debugPrint('Session locked');
  }

  /// Unlock session (after PIN entry)
  void unlockSession() {
    if (!_isSessionValid) {
      debugPrint('Session expired, cannot unlock');
      return;
    }

    _isLocked = false;
    _lastActivityTime = DateTime.now();
    _startInactivityTimer();
    notifyListeners();
    debugPrint('Session unlocked');
  }

  /// End session (on logout)
  void endSession() {
    _isLocked = false;
    _isSessionValid = false;
    _inactivityTimer?.cancel();
    _sessionTimer?.cancel();
    _sessionStartTime = null;
    _lastActivityTime = null;
    notifyListeners();
    debugPrint('Session ended');
  }

  /// Extend session (for long operations)
  void extendSession() {
    _sessionStartTime = DateTime.now();
    _resetSessionTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, _onInactivityTimeout);
  }

  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(sessionTimeout, _onSessionTimeout);
  }

  void _resetSessionTimer() {
    _startSessionTimer();
  }

  void _onInactivityTimeout() {
    debugPrint('Inactivity timeout reached');
    lockSession();
  }

  void _onSessionTimeout() {
    debugPrint('Session timeout reached');
    _isSessionValid = false;
    endSession();
  }

  /// Check if session needs re-authentication
  bool needsReauth() {
    return _isLocked || !_isSessionValid;
  }

  /// Get session elapsed time since start
  Duration? get sessionElapsed {
    if (_sessionStartTime == null) return null;
    return DateTime.now().difference(_sessionStartTime!);
  }

  /// Get session remaining time
  Duration? get sessionRemaining {
    if (_sessionStartTime == null) return null;
    final elapsed = DateTime.now().difference(_sessionStartTime!);
    final remaining = sessionTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Reset session start time (e.g., after successful token refresh)
  /// This extends the full 8-hour session timeout
  void resetSessionStartTime() {
    _sessionStartTime = DateTime.now();
    _resetSessionTimer();
    notifyListeners();
    debugPrint('Session start time reset');
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }
}

/// Mixin for widgets that need to track user activity
mixin ActivityTracker<T extends StatefulWidget> on State<T> {
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _trackActivity();
  }

  void _trackActivity() {
    _sessionService.recordActivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trackActivity();
  }

  void onUserInteraction() {
    _sessionService.recordActivity();
  }
}
