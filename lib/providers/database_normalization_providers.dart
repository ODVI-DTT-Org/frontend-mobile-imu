import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/api/visit_api_service.dart';
import 'package:imu_flutter/services/api/call_api_service.dart';
import 'package:imu_flutter/services/api/release_api_service.dart';
import 'package:imu_flutter/services/api/touchpoint_v2_api_service.dart';
import 'package:imu_flutter/models/visit_model.dart';
import 'package:imu_flutter/models/call_model.dart';
import 'package:imu_flutter/models/release_model.dart';
import 'package:imu_flutter/models/touchpoint_model_v2.dart';

// ==================== Service Providers ====================

/// Visit API service provider
final visitApiServiceProvider = Provider<VisitApiService>((ref) {
  return VisitApiService();
});

/// Call API service provider
final callApiServiceProvider = Provider<CallApiService>((ref) {
  return CallApiService();
});

/// Release API service provider
final releaseApiServiceProvider = Provider<ReleaseApiService>((ref) {
  return ReleaseApiService();
});

/// Touchpoint V2 API service provider
final touchpointV2ApiServiceProvider = Provider<TouchpointV2ApiService>((ref) {
  return TouchpointV2ApiService();
});

// ==================== Visit Providers ====================

/// All visits for current user
final visitsProvider = FutureProvider.autoDispose<List<Visit>>((ref) async {
  final service = ref.watch(visitApiServiceProvider);
  return service.fetchVisits();
});

/// Visits for a specific client
final clientVisitsProvider = FutureProvider.autoDispose.family<List<Visit>, String>((ref, clientId) async {
  final service = ref.watch(visitApiServiceProvider);
  return service.fetchVisits(clientId: clientId);
});

/// Single visit by ID
final visitProvider = FutureProvider.autoDispose.family<Visit?, String>((ref, id) async {
  final service = ref.watch(visitApiServiceProvider);
  return service.fetchVisit(id);
});

// ==================== Call Providers ====================

/// All calls for current user
final callsProvider = FutureProvider.autoDispose<List<Call>>((ref) async {
  final service = ref.watch(callApiServiceProvider);
  return service.fetchCalls();
});

/// Calls for a specific client
final clientCallsProvider = FutureProvider.autoDispose.family<List<Call>, String>((ref, clientId) async {
  final service = ref.watch(callApiServiceProvider);
  return service.fetchCalls(clientId: clientId);
});

/// Single call by ID
final callProvider = FutureProvider.autoDispose.family<Call?, String>((ref, id) async {
  final service = ref.watch(callApiServiceProvider);
  return service.fetchCall(id);
});

// ==================== Release Providers ====================

/// All releases for current user
final releasesProvider = FutureProvider.autoDispose<List<Release>>((ref) async {
  final service = ref.watch(releaseApiServiceProvider);
  return service.fetchReleases();
});

/// Releases for a specific client
final clientReleasesProvider = FutureProvider.autoDispose.family<List<Release>, String>((ref, clientId) async {
  final service = ref.watch(releaseApiServiceProvider);
  return service.fetchReleases(clientId: clientId);
});

/// Pending releases (awaiting approval)
final pendingReleasesProvider = FutureProvider.autoDispose<List<Release>>((ref) async {
  final service = ref.watch(releaseApiServiceProvider);
  return service.fetchReleases(status: 'pending');
});

/// Single release by ID
final releaseProvider = FutureProvider.autoDispose.family<Release?, String>((ref, id) async {
  final service = ref.watch(releaseApiServiceProvider);
  return service.fetchRelease(id);
});

// ==================== Touchpoint V2 Providers ====================

/// All touchpoints for current user
final touchpointsV2Provider = FutureProvider.autoDispose<List<TouchpointV2>>((ref) async {
  final service = ref.watch(touchpointV2ApiServiceProvider);
  return service.fetchTouchpoints();
});

/// Touchpoints for a specific client
final clientTouchpointsV2Provider = FutureProvider.autoDispose.family<List<TouchpointV2>, String>((ref, clientId) async {
  final service = ref.watch(touchpointV2ApiServiceProvider);
  return service.fetchTouchpoints(clientId: clientId);
});

/// Single touchpoint by ID
final touchpointV2Provider = FutureProvider.autoDispose.family<TouchpointV2?, String>((ref, id) async {
  final service = ref.watch(touchpointV2ApiServiceProvider);
  return service.fetchTouchpoint(id);
});
