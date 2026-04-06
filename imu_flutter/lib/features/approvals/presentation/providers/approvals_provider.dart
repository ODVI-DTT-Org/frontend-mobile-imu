import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/approvals/data/models/approval_model.dart';
import 'package:imu_flutter/features/approvals/data/repositories/approvals_api_service.dart';

/// State for Approvals
class ApprovalsState {
  final List<Approval> pendingApprovals;
  final List<Approval> allApprovals;
  final bool isLoading;
  final String? error;
  final Map<ApprovalStatus, int> counts;

  const ApprovalsState({
    this.pendingApprovals = const [],
    this.allApprovals = const [],
    this.isLoading = false,
    this.error,
    this.counts = const {},
  });

  ApprovalsState copyWith({
    List<Approval>? pendingApprovals,
    List<Approval>? allApprovals,
    bool? isLoading,
    String? error,
    Map<ApprovalStatus, int>? counts,
  }) {
    return ApprovalsState(
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      allApprovals: allApprovals ?? this.allApprovals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      counts: counts ?? this.counts,
    );
  }

  /// Get pending count
  int get pendingCount => counts[ApprovalStatus.pending] ?? pendingApprovals.length;

  /// Get approved count
  int get approvedCount => counts[ApprovalStatus.approved] ?? 0;

  /// Get rejected count
  int get rejectedCount => counts[ApprovalStatus.rejected] ?? 0;
}

/// Notifier for Approvals state
class ApprovalsNotifier extends StateNotifier<ApprovalsState> {
  final ApprovalsApiService _apiService;

  ApprovalsNotifier(this._apiService) : super(const ApprovalsState()) {
    // Don't auto-load - let the UI trigger loading when needed
    // This prevents 403 errors for users without approvals permissions
  }

  Future<void> loadPendingApprovals() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final approvals = await _apiService.fetchPendingApprovals();
      final counts = await _apiService.getApprovalCounts();

      state = state.copyWith(
        pendingApprovals: approvals,
        allApprovals: approvals,
        isLoading: false,
        counts: counts,
      );
    } catch (e) {
      // Check if it's a permission error (403)
      final errorStr = e.toString();
      if (errorStr.contains('403') || errorStr.contains('Insufficient permissions')) {
        // Silently return empty state for users without permissions
        state = state.copyWith(
          pendingApprovals: [],
          allApprovals: [],
          isLoading: false,
          counts: const {},
          error: null,
        );
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> loadAllApprovals({ApprovalStatus? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final approvals = await _apiService.fetchAllApprovals(status: status);

      state = state.copyWith(
        allApprovals: approvals,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadPendingApprovals();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for Approvals state
final approvalsProvider = StateNotifierProvider<ApprovalsNotifier, ApprovalsState>((ref) {
  final apiService = ref.watch(approvalsApiServiceProvider);
  return ApprovalsNotifier(apiService);
});

/// Provider for pending approvals count
final pendingApprovalsCountProvider = Provider<int>((ref) {
  final approvalsState = ref.watch(approvalsProvider);
  return approvalsState.pendingCount;
});
