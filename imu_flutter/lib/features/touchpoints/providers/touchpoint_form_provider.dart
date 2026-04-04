import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for Time In/Out capture
class TimeCaptureState {
  final DateTime? time;
  final double? gpsLat;
  final double? gpsLng;
  final String? gpsAddress;
  final bool isCapturing;
  final String? error;

  const TimeCaptureState({
    this.time,
    this.gpsLat,
    this.gpsLng,
    this.gpsAddress,
    this.isCapturing = false,
    this.error,
  });

  bool get isCaptured => time != null;

  TimeCaptureState copyWith({
    DateTime? time,
    double? gpsLat,
    double? gpsLng,
    String? gpsAddress,
    bool? isCapturing,
    String? error,
    bool clearTime = false,
    bool clearGpsLat = false,
    bool clearGpsLng = false,
    bool clearGpsAddress = false,
    bool clearError = false,
  }) {
    return TimeCaptureState(
      time: clearTime ? null : (time ?? this.time),
      gpsLat: clearGpsLat ? null : (gpsLat ?? this.gpsLat),
      gpsLng: clearGpsLng ? null : (gpsLng ?? this.gpsLng),
      gpsAddress: clearGpsAddress ? null : (gpsAddress ?? this.gpsAddress),
      isCapturing: isCapturing ?? this.isCapturing,
      error: clearError ? null : (error ?? this.error),
    );
  }

  factory TimeCaptureState.empty() => const TimeCaptureState();
}

/// State for the entire touchpoint form
class TouchpointFormState {
  final String touchpointType; // 'Visit' or 'Call'
  final TimeCaptureState timeIn;
  final TimeCaptureState timeOut;
  final bool isSubmitting;

  // Form field values
  final String? reason;
  final String? status;  // NEW: status dropdown value
  final String? remarks;
  final String? photoPath;
  final String? audioPath;
  final String? photoUrl;  // NEW: uploaded photo URL
  final bool isUploadingPhoto;  // NEW: photo upload in progress

  const TouchpointFormState({
    this.touchpointType = 'Visit',
    this.timeIn = const TimeCaptureState(),
    this.timeOut = const TimeCaptureState(),
    this.isSubmitting = false,
    this.reason,
    this.status,  // NEW
    this.remarks,
    this.photoPath,
    this.audioPath,
    this.photoUrl,  // NEW
    this.isUploadingPhoto = false,  // NEW
  });

  /// Form fields are enabled after Time In is captured (for Visit type)
  bool get canFillForm => touchpointType == 'Call' || timeIn.isCaptured;

  /// Submit is enabled after Time Out is captured (for Visit type)
  /// with proper null-safety checks
  bool get canSubmit {
    // Call type can submit immediately
    if (touchpointType == 'Call') return true;

    // Handle nullable Time In
    final timeIn = this.timeIn;
    if (!timeIn.isCaptured) return false;

    // Handle nullable Time Out
    final timeOut = this.timeOut;
    if (!timeOut.isCaptured) return false;

    // Both times must be non-null at this point since isCaptured checks time != null
    // But we still need to handle the nullable .time property
    final timeInValue = timeIn.time;
    final timeOutValue = timeOut.time;

    if (timeInValue == null || timeOutValue == null) return false;

    // Time Out must be after Time In
    return timeOutValue.isAfter(timeInValue);
  }

  /// Check if Time Out time is valid (after Time In)
  bool get isTimeOutValid {
    // Handle nullable Time In
    final timeIn = this.timeIn;
    if (!timeIn.isCaptured) return true;

    // Handle nullable Time Out
    final timeOut = this.timeOut;
    if (!timeOut.isCaptured) return true;

    // Both times must be non-null at this point
    final timeInValue = timeIn.time;
    final timeOutValue = timeOut.time;

    if (timeInValue == null || timeOutValue == null) return true;

    return timeOutValue.isAfter(timeInValue);
  }

  /// Calculate visit duration in minutes
  int? get visitDurationMinutes {
    // Handle nullable Time In
    final timeIn = this.timeIn;
    if (!timeIn.isCaptured) return null;

    // Handle nullable Time Out
    final timeOut = this.timeOut;
    if (!timeOut.isCaptured) return null;

    // Both times must be non-null at this point
    final timeInValue = timeIn.time;
    final timeOutValue = timeOut.time;

    if (timeInValue == null || timeOutValue == null) return null;

    return timeOutValue.difference(timeInValue).inMinutes;
  }

  TouchpointFormState copyWith({
    String? touchpointType,
    TimeCaptureState? timeIn,
    TimeCaptureState? timeOut,
    bool? isSubmitting,
    String? reason,
    String? status,  // NEW
    String? remarks,
    String? photoPath,
    String? audioPath,
    String? photoUrl,  // NEW
    bool? isUploadingPhoto,  // NEW
    bool clearReason = false,
    bool clearStatus = false,  // NEW
    bool clearRemarks = false,
    bool clearPhotoPath = false,
    bool clearAudioPath = false,
    bool clearPhotoUrl = false,  // NEW
  }) {
    return TouchpointFormState(
      touchpointType: touchpointType ?? this.touchpointType,
      timeIn: timeIn ?? this.timeIn,
      timeOut: timeOut ?? this.timeOut,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      reason: clearReason ? null : (reason ?? this.reason),
      status: clearStatus ? null : (status ?? this.status),  // NEW
      remarks: clearRemarks ? null : (remarks ?? this.remarks),
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
      audioPath: clearAudioPath ? null : (audioPath ?? this.audioPath),
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),  // NEW
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,  // NEW
    );
  }
}

/// Notifier for touchpoint form state
class TouchpointFormNotifier extends StateNotifier<TouchpointFormState> {
  TouchpointFormNotifier() : super(const TouchpointFormState());

  void setTouchpointType(String type) {
    state = state.copyWith(touchpointType: type);
  }

  void setTimeInCapturing(bool isCapturing) {
    state = state.copyWith(
      timeIn: state.timeIn.copyWith(isCapturing: isCapturing),
    );
  }

  void setTimeIn(DateTime time, double? lat, double? lng, String? address) {
    state = state.copyWith(
      timeIn: TimeCaptureState(
        time: time,
        gpsLat: lat,
        gpsLng: lng,
        gpsAddress: address,
      ),
    );
  }

  void setTimeInError(String error) {
    state = state.copyWith(
      timeIn: state.timeIn.copyWith(
        isCapturing: false,
        error: error,
      ),
    );
  }

  void clearTimeInError() {
    state = state.copyWith(
      timeIn: state.timeIn.copyWith(clearError: true),
    );
  }

  void setTimeOutCapturing(bool isCapturing) {
    state = state.copyWith(
      timeOut: state.timeOut.copyWith(isCapturing: isCapturing),
    );
  }

  void setTimeOut(DateTime time, double? lat, double? lng, String? address) {
    state = state.copyWith(
      timeOut: TimeCaptureState(
        time: time,
        gpsLat: lat,
        gpsLng: lng,
        gpsAddress: address,
      ),
    );
  }

  void setTimeOutError(String error) {
    state = state.copyWith(
      timeOut: state.timeOut.copyWith(
        isCapturing: false,
        error: error,
      ),
    );
  }

  void clearTimeOutError() {
    state = state.copyWith(
      timeOut: state.timeOut.copyWith(clearError: true),
    );
  }

  void setReason(String? reason) {
    state = state.copyWith(reason: reason);
  }

  void setStatus(String? status) {
    state = state.copyWith(status: status);
  }

  void setRemarks(String? remarks) {
    state = state.copyWith(remarks: remarks);
  }

  void setPhotoPath(String? photoPath) {
    state = state.copyWith(photoPath: photoPath);
  }

  void setAudioPath(String? audioPath) {
    state = state.copyWith(audioPath: audioPath);
  }

  void setPhotoUrl(String? photoUrl) {
    state = state.copyWith(photoUrl: photoUrl);
  }

  void setIsUploadingPhoto(bool isUploading) {
    state = state.copyWith(isUploadingPhoto: isUploading);
  }

  void setIsSubmitting(bool isSubmitting) {
    state = state.copyWith(isSubmitting: isSubmitting);
  }

  void reset() {
    state = const TouchpointFormState();
  }
}

/// Provider for touchpoint form state
final touchpointFormProvider =
    StateNotifierProvider<TouchpointFormNotifier, TouchpointFormState>((ref) {
  return TouchpointFormNotifier();
});
