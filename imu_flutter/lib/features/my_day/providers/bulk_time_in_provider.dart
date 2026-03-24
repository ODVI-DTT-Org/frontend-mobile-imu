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
    this.isCapturingGps: false,
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
    double? timeOutGpsLng;
    String? timeOutGpsAddress,
    bool? isCapturingGps,
    String? errorMessage,
  }) {
  return BulkTimeInState(
    selectedClients: selectedClients ?? [],
    timeIn: timeIn,
    timeInGpsLat: timeInGpsLat,
    timeInGpsAddress: timeInGpsAddress,
    visitedClientIds: visitedClientIds ?? {},
    timeOut: timeOut,
    timeOutGpsLat: timeOutGpsLat,
    timeOutGpsLng: timeOutGpsLng,
    timeOutGpsAddress: timeOutGpsAddress,
    isCapturingGps: capturing,
    errorMessage: errorMessage,
  });
}
```

- [ ] **Step 2: Commit bulk time in provider**

```bash
cd mobile/imu_flutter && git add lib/features/my_day/providers/bulk_time_in_provider.dart && git commit -m "feat(mobile): add BulkTimeInProvider for bulk time in/out

- BulkClient model for selected clients
- BulkTimeInState with time in/out, GPS, visited tracking
- BulkTimeInNotifier with state management methods
- Computed properties

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```
