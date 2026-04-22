// lib/features/record_forms/presentation/providers/record_form_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/domain/services/touchpoint_calculator_service.dart';
import 'package:imu_flutter/services/gps/gps_capture_service.dart';
import 'package:imu_flutter/services/api/touchpoint_api_service.dart';
import 'package:imu_flutter/services/api/my_day_api_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart' show Client;

// Touchpoint Form State
class TouchpointFormState {
  final TouchpointFormData data;
  final bool isSubmitting;
  final String? submissionError;
  final String? successMessage;
  final int? touchpointNumber;

  const TouchpointFormState({
    required this.data,
    this.isSubmitting = false,
    this.submissionError,
    this.successMessage,
    this.touchpointNumber,
  });

  TouchpointFormState copyWith({
    TouchpointFormData? data,
    bool? isSubmitting,
    String? submissionError,
    String? successMessage,
    int? touchpointNumber,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TouchpointFormState(
      data: data ?? this.data,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionError: clearError ? null : (submissionError ?? this.submissionError),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      touchpointNumber: touchpointNumber ?? this.touchpointNumber,
    );
  }
}

// Touchpoint Form Notifier
class TouchpointFormNotifier extends StateNotifier<TouchpointFormState> {
  final GPSCaptureService _gpsService;
  final TouchpointCalculatorService _calculatorService;
  final TouchpointApiService _touchpointApi;
  final Ref _ref;

  TouchpointFormNotifier({
    required Client client,
    GPSCaptureService? gpsService,
    TouchpointCalculatorService? calculatorService,
    TouchpointApiService? touchpointApi,
    required Ref ref,
  })  : _gpsService = gpsService ?? GPSCaptureService(),
       _calculatorService = calculatorService ?? TouchpointCalculatorService(),
       _touchpointApi = touchpointApi ?? TouchpointApiService(),
       _ref = ref,
       super(TouchpointFormState(data: TouchpointFormData(client: client))) {
    _loadTouchpointNumber();
  }

  Future<void> _loadTouchpointNumber() async {
    try {
      // Fetch existing touchpoints for this client
      final touchpoints = await _touchpointApi.fetchTouchpoints(
        clientId: state.data.client.id,
      );
      final number = await _calculatorService.calculateNextNumber(
        state.data.client.id!,
        touchpoints,
      );
      state = state.copyWith(touchpointNumber: number);
    } catch (e) {
      state = state.copyWith(submissionError: e.toString());
    }
  }

  void updateTimeIn(DateTime? time) {
    state = state.copyWith(
      data: state.data.copyWith(timeIn: time),
      clearError: true,
      clearSuccess: true,
    );
  }

  void updateTimeOut(DateTime? time) {
    state = state.copyWith(
      data: state.data.copyWith(timeOut: time),
      clearError: true,
      clearSuccess: true,
    );
  }

  void updateOdometerIn(String? value) {
    state = state.copyWith(
      data: state.data.copyWith(odometerIn: value),
      clearError: true,
      clearSuccess: true,
    );
  }

  void updateOdometerOut(String? value) {
    state = state.copyWith(
      data: state.data.copyWith(odometerOut: value),
      clearError: true,
      clearSuccess: true,
    );
  }

  void updateReason(TouchpointReason? reason) {
    state = state.copyWith(
      data: state.data.copyWith(reason: reason),
      clearError: true,
      clearSuccess: true,
    );
  }

  void updateStatus(TouchpointStatus? status) {
    state = state.copyWith(
      data: state.data.copyWith(status: status),
      clearError: true,
      clearSuccess: true,
    );
  }

  void updateRemarks(String? remarks) {
    state = state.copyWith(
      data: state.data.copyWith(remarks: remarks),
      clearError: true,
      clearSuccess: true,
    );
  }

  void updatePhoto(String? photoPath) {
    state = state.copyWith(
      data: state.data.copyWith(photoPath: photoPath),
      clearError: true,
      clearSuccess: true,
    );
  }

  Future<bool> submit() async {
    if (!state.data.isValid) {
      state = state.copyWith(submissionError: 'Please fix all errors');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      // Capture GPS (required)
      final gps = await _gpsService.captureLocation();

      // Update form data with GPS
      final updatedData = state.data.copyWith(
        gpsLatitude: gps.latitude,
        gpsLongitude: gps.longitude,
        gpsAddress: gps.address,
      );

      // Prepare time strings
      final timeArrival = updatedData.timeIn != null
          ? '${updatedData.timeIn!.hour.toString().padLeft(2, '0')}:${updatedData.timeIn!.minute.toString().padLeft(2, '0')}'
          : null;
      final timeDeparture = updatedData.calculatedTimeOut != null
          ? '${updatedData.calculatedTimeOut!.hour.toString().padLeft(2, '0')}:${updatedData.calculatedTimeOut!.minute.toString().padLeft(2, '0')}'
          : null;

      // Submit to API using completeVisit endpoint
      final myDayApiService = _ref.read(myDayApiServiceProvider);
      final result = await myDayApiService.completeVisit(
        clientId: state.data.client.id!,
        touchpointNumber: state.touchpointNumber!,
        type: 'Visit',
        reason: updatedData.reason?.apiValue ?? 'INTERESTED',
        status: updatedData.status?.apiValue,
        address: updatedData.gpsAddress,
        timeArrival: timeArrival,
        timeDeparture: timeDeparture,
        odometerArrival: updatedData.odometerIn,
        odometerDeparture: updatedData.odometerOut,
        notes: updatedData.remarks,
        latitude: updatedData.gpsLatitude,
        longitude: updatedData.gpsLongitude,
        photoPath: updatedData.photoPath,
      );

      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Touchpoint #${state.touchpointNumber} recorded',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submissionError: e.toString(),
      );
      return false;
    }
  }
}

// Provider family for touchpoint form
final touchpointFormProvider = StateNotifierProvider.family<TouchpointFormNotifier, TouchpointFormState, Client>(
  (ref, client) {
    return TouchpointFormNotifier(
      client: client,
      ref: ref,
    );
  },
);

// GPS Service Provider
final gpsCaptureServiceProvider = Provider<GPSCaptureService>((ref) {
  return GPSCaptureService();
});

// Calculator Service Provider
final touchpointCalculatorProvider = Provider<TouchpointCalculatorService>((ref) {
  return TouchpointCalculatorService();
});

// Touchpoint API Service Provider
final touchpointApiServiceProvider = Provider<TouchpointApiService>((ref) {
  return TouchpointApiService();
});

// My Day API Service Provider
final myDayApiServiceProvider = Provider<MyDayApiService>((ref) {
  return MyDayApiService();
});
