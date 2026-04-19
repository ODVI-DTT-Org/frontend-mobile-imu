import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/my_day_client.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../core/utils/logger.dart';

/// State for My Day page
class MyDayState {
  final List<MyDayClient> clients;
  final bool isLoading;
  final String? error;
  final DateTime selectedDate;

  MyDayState({
    this.clients = const [],
    this.isLoading = false,
    this.error,
    DateTime? selectedDate,
  }) : selectedDate = selectedDate ?? DateTime.now();

  MyDayState copyWith({
    List<MyDayClient>? clients,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
  }) {
    return MyDayState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

/// Notifier for My Day state — reads from PowerSync local SQLite
class MyDayNotifier extends StateNotifier<MyDayState> {
  final Ref _ref;
  StreamSubscription<List<MyDayClient>>? _subscription;

  MyDayNotifier(this._ref) : super(MyDayState()) {
    _subscribeToDate(DateTime.now());
  }

  void _subscribeToDate(DateTime date) {
    _subscription?.cancel();
    state = state.copyWith(isLoading: true, error: null, selectedDate: date);

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = state.copyWith(isLoading: false, error: 'Not logged in');
      return;
    }

    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    _subscription = _buildStream(userId, dateStr).listen(
      (clients) {
        if (mounted) state = state.copyWith(clients: clients, isLoading: false);
      },
      onError: (e) {
        logError('MyDayNotifier stream error', e);
        if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
      },
    );
  }

  Stream<List<MyDayClient>> _buildStream(String userId, String dateStr) async* {
    final db = await PowerSyncService.database;
    await for (final rows in db.watch(
      '''SELECT i.id, i.client_id, i.user_id, i.scheduled_time, i.status,
                i.priority, i.notes,
                c.first_name, c.last_name, c.client_type,
                c.touchpoint_summary
         FROM itineraries i
         LEFT JOIN clients c ON c.id = i.client_id
         WHERE i.user_id = ? AND DATE(i.scheduled_date) = ?
         ORDER BY i.scheduled_time ASC''',
      parameters: [userId, dateStr],
    )) {
      yield rows.map(MyDayClient.fromPowerSync).toList();
    }
  }

  Future<void> refresh() async {
    _subscribeToDate(state.selectedDate);
  }

  void changeDate(DateTime date) {
    _subscribeToDate(date);
  }

  Future<void> setTimeIn(String clientId, bool isTimeIn) async {
    // Time-in is tracked locally via client list update
    final updated = state.clients.map((c) {
      if (c.clientId == clientId) return c.copyWith(isTimeIn: isTimeIn);
      return c;
    }).toList();
    state = state.copyWith(clients: updated);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for My Day state
final myDayStateProvider = StateNotifierProvider<MyDayNotifier, MyDayState>((ref) {
  return MyDayNotifier(ref);
});

/// Provider for filtered clients (by time-in status)
final filteredClientsProvider = Provider.family<List<MyDayClient>, bool?>((ref, isTimeIn) {
  final state = ref.watch(myDayStateProvider);
  if (isTimeIn == null) return state.clients;
  return state.clients.where((c) => c.isTimeIn == isTimeIn).toList();
});
