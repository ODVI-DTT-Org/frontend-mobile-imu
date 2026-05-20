import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/approvals/data/models/approval_model.dart';

/// Union type for history display - represents either a touchpoint or a loan release
sealed class HistoryItem {
  DateTime get createdAt;
  String get id;

  const HistoryItem();

  /// Type discriminator for matching/switching
  bool get isTouchpoint => this is TouchpointHistoryItem;
  bool get isLoanRelease => this is LoanReleaseHistoryItem;
}

/// Touchpoint history item
class TouchpointHistoryItem extends HistoryItem {
  final Touchpoint touchpoint;

  const TouchpointHistoryItem(this.touchpoint);

  @override
  DateTime get createdAt => touchpoint.createdAt;

  @override
  String get id => touchpoint.id;
}

/// Loan release history item
class LoanReleaseHistoryItem extends HistoryItem {
  final Approval approval;

  const LoanReleaseHistoryItem(this.approval);

  @override
  DateTime get createdAt => approval.createdAt;

  @override
  String get id => approval.id;
}
