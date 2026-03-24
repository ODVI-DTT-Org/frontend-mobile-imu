// lib/features/my_day/providers/bulk_time_in_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class BulkClient {
  final String id;
  final String name;
  final int touchpointNumber;
  final String type;

  const BulkClient({
    required this.id,
    required this.name,
    required this.touchpointNumber,
    required this.type,
  });
}

class BulkTimeInState {
  final List<BulkClient> selectedClients;
  final DateTime? timeIn;
  final double? timeInGpsLat;
  final double? timeInGpsLng;
  final String? timeInGpsAddress;
  final Set<String> visitedClientIds;
  final DateTime? timeOut;
  final double? timeOutGpsLat;
  final double? timeOutGpsLng;
  final String? timeOutGpsAddress;
  final bool isCapturingGps;
  final String? errorMessage;

  const BulkTimeInState({
    this.selectedClients = const [],
    this.timeIn,
    this.timeInGpsLat,
    this.timeInGpsLng,
    this.timeInGpsAddress,
    this.visitedClientIds = const {},
    this.timeOut,
    this.timeOutGpsLat,
    this.timeOutGpsLng,
    this.timeOutGpsAddress,
    this.isCapturingGps = false,
    this.errorMessage,
  });

  bool get canCaptureTimeOut =>
      timeIn != null && visitedClientIds.isNotEmpty;

  int get visitedCount => visitedClientIds.length;

  BulkTimeInState copyWith({
    List<BulkClient>? selectedClients,
    DateTime? timeIn,
    double? timeInGpsLat,
    double? timeInGpsLng,
    String? timeInGpsAddress,
    Set<String>? visitedClientIds,
    DateTime? timeOut,
    double? timeOutGpsLat,
    double? timeOutGpsLng,
    String? timeOutGpsAddress,
    bool? isCapturingGps,
    String? errorMessage,
  }) {
    return BulkTimeInState(
      selectedClients: selectedClients ?? this.selectedClients,
      timeIn: timeIn ?? this.timeIn,
      timeInGpsLat: timeInGpsLat ?? this.timeInGpsLat,
      timeInGpsLng: timeInGpsLng ?? this.timeInGpsLng,
      timeInGpsAddress: timeInGpsAddress ?? this.timeInGpsAddress,
      visitedClientIds: visitedClientIds ?? this.visitedClientIds,
      timeOut: timeOut ?? this.timeOut,
      timeOutGpsLat: timeOutGpsLat ?? this.timeOutGpsLat,
      timeOutGpsLng: timeOutGpsLng ?? this.timeOutGpsLng,
      timeOutGpsAddress: timeOutGpsAddress ?? this.timeOutGpsAddress,
      isCapturingGps: isCapturingGps ?? this.isCapturingGps,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class BulkTimeInNotifier extends StateNotifier<BulkTimeInState> {
  BulkTimeInNotifier() : super(const BulkTimeInState());

  void selectClients(List<BulkClient> clients) {
    state = state.copyWith(selectedClients: clients);
  }

  void addClient(BulkClient client) {
    if (!state.selectedClients.any((c) => c.id == client.id)) {
      state = state.copyWith(
        selectedClients: [...state.selectedClients, client],
      );
    }
  }

  void removeClient(String clientId) {
    state = state.copyWith(
      selectedClients: state.selectedClients.where((c) => c.id != clientId).toList(),
    );
  }

  Future<void> setTimeIn({
    required DateTime time,
    double? lat,
    double? lng,
    String? address,
  }) async {
    state = state.copyWith(
      timeIn: time,
      timeInGpsLat: lat,
      timeInGpsLng: lng,
      timeInGpsAddress: address,
    );
  }

  Future<void> setTimeOut({
    required DateTime time,
    double? lat,
    double? lng,
    String? address,
  }) async {
    state = state.copyWith(
      timeOut: time,
      timeOutGpsLat: lat,
      timeOutGpsLng: lng,
      timeOutGpsAddress: address,
    );
  }

  void markClientVisited(String clientId) {
    if (!state.visitedClientIds.contains(clientId)) {
      state = state.copyWith(
        visitedClientIds: {...state.visitedClientIds, clientId},
      );
    }
  }

  void unmarkClientVisited(String clientId) {
    state = state.copyWith(
      visitedClientIds: state.visitedClientIds.where((id) => id != clientId).toSet(),
    );
  }

  void setCapturingGps(bool capturing) {
    state = state.copyWith(isCapturingGps: capturing);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  void reset() {
    state = const BulkTimeInState();
  }
}

/// Provider for bulk time in state
final bulkTimeInProvider = StateNotifierProvider<BulkTimeInNotifier, BulkTimeInState>((ref) {
  return BulkTimeInNotifier();
});
