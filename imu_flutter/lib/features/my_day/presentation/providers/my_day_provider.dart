import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/my_day_client.dart';
import '../../../../services/api/my_day_api_service.dart';

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

/// Notifier for My Day state
class MyDayNotifier extends StateNotifier<MyDayState> {
  final MyDayApiService _apiService;

  MyDayNotifier(this._apiService) : super(MyDayState()) {
    loadClients();
  }

  Future<void> loadClients() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final clients = await _apiService.fetchMyDayClients(state.selectedDate);
      state = state.copyWith(clients: clients, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadClients();
  }

  Future<void> setTimeIn(String clientId, bool isTimeIn) async {
    try {
      await _apiService.setTimeIn(clientId);
      await loadClients();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> submitVisitForm(String clientId, Map<String, dynamic> formData) async {
    try {
      await _apiService.submitVisitForm(clientId, formData);
      await loadClients();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for My Day state
final myDayStateProvider = StateNotifierProvider<MyDayNotifier, MyDayState>((ref) {
  final apiService = ref.watch(myDayApiServiceProvider);
  return MyDayNotifier(apiService);
});

/// Provider for filtered clients (by time-in status)
final filteredClientsProvider = Provider.family<List<MyDayClient>, bool?>((ref, isTimeIn) {
  final state = ref.watch(myDayStateProvider);
  if (isTimeIn == null) return state.clients;
  return state.clients.where((c) => c.isTimeIn == isTimeIn).toList();
});
