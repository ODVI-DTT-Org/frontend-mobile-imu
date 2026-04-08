import '../core/utils/date_utils.dart';

enum ProductType {
  pusu('PUSU', 'Pension Update Salary Loan'),
  lika('LIKA', 'Livelihood Loan for Karanasan sa Ago'),
  sub2k('SUB2K', 'Sub2K Loan');

  final String value;
  final String label;

  const ProductType(this.value, this.label);

  /// Get ProductType from string value
  static ProductType? fromValue(String? value) {
    if (value == null) return null;
    try {
      return ProductType.values.firstWhere((type) => type.value == value);
    } catch (_) {
      return null;
    }
  }

  /// Get ProductType from string value with fallback
  static ProductType fromValueOrFirst(String? value) {
    return fromValue(value) ?? ProductType.pusu;
  }

  /// Check if value is valid
  static bool isValid(String? value) {
    return fromValue(value) != null;
  }

  /// Get all values for UI display
  static List<ProductType> getAllValues() => ProductType.values;

  /// Get all labels for UI dropdown
  static List<String> getAllLabels() => ProductType.values.map((e) => e.label).toList();
}

enum LoanType {
  newLoan('NEW', 'New Loan'),
  additional('ADDITIONAL', 'Additional Loan'),
  renewal('RENEWAL', 'Renewal'),
  preterm('PRETERM', 'Pre-termination');

  final String value;
  final String label;

  const LoanType(this.value, this.label);

  /// Get LoanType from string value
  static LoanType? fromValue(String? value) {
    if (value == null) return null;
    try {
      return LoanType.values.firstWhere((type) => type.value == value);
    } catch (_) {
      return null;
    }
  }

  /// Get LoanType from string value with fallback
  static LoanType fromValueOrFirst(String? value) {
    return fromValue(value) ?? LoanType.newLoan;
  }

  /// Check if value is valid
  static bool isValid(String? value) {
    return fromValue(value) != null;
  }

  /// Get all values for UI display
  static List<LoanType> getAllValues() => LoanType.values;

  /// Get all labels for UI dropdown
  static List<String> getAllLabels() => LoanType.values.map((e) => e.label).toList();
}

enum ReleaseStatus {
  pending('pending', 'Pending Approval'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected'),
  disbursed('disbursed', 'Disbursed');

  final String value;
  final String label;

  const ReleaseStatus(this.value, this.label);

  /// Get ReleaseStatus from string value
  static ReleaseStatus? fromValue(String? value) {
    if (value == null) return null;
    try {
      return ReleaseStatus.values.firstWhere((status) => status.value == value);
    } catch (_) {
      return null;
    }
  }

  /// Get ReleaseStatus from string value with fallback
  static ReleaseStatus fromValueOrFirst(String? value) {
    return fromValue(value) ?? ReleaseStatus.pending;
  }

  /// Check if value is valid
  static bool isValid(String? value) {
    return fromValue(value) != null;
  }
}

class Release {
  final String id;
  final String clientId;
  final String userId;
  final String visitId;
  final String productType; // PUSU | LIKA | SUB2K
  final String loanType; // NEW | ADDITIONAL | RENEWAL | PRETERM
  final double amount;
  final String? approvalNotes;
  final String status; // pending | approved | rejected | disbursed
  final DateTime createdAt;
  final DateTime updatedAt;

  Release({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.visitId,
    required this.productType,
    required this.loanType,
    required this.amount,
    this.approvalNotes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Release copyWith({
    String? id,
    String? clientId,
    String? userId,
    String? visitId,
    String? productType,
    String? loanType,
    double? amount,
    String? approvalNotes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Release(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      visitId: visitId ?? this.visitId,
      productType: productType ?? this.productType,
      loanType: loanType ?? this.loanType,
      amount: amount ?? this.amount,
      approvalNotes: approvalNotes ?? this.approvalNotes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Release.fromRow(Map<String, dynamic> row) {
    // Validate required fields
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('Release: id is required and cannot be empty');
    }

    final clientId = row['client_id']?.toString();
    if (clientId == null || clientId.isEmpty) {
      throw ArgumentError('Release: client_id is required and cannot be empty');
    }

    final userId = row['user_id']?.toString();
    if (userId == null || userId.isEmpty) {
      throw ArgumentError('Release: user_id is required and cannot be empty');
    }

    final visitId = row['visit_id']?.toString();
    if (visitId == null || visitId.isEmpty) {
      throw ArgumentError('Release: visit_id is required and cannot be empty');
    }

    // Validate product type
    final productType = row['product_type']?.toString() ?? 'PUSU';
    if (!ProductType.isValid(productType)) {
      throw ArgumentError('Release: invalid product_type: $productType. Must be one of: PUSU, LIKA, SUB2K');
    }

    // Validate loan type
    final loanType = row['loan_type']?.toString() ?? 'NEW';
    if (!LoanType.isValid(loanType)) {
      throw ArgumentError('Release: invalid loan_type: $loanType. Must be one of: NEW, ADDITIONAL, RENEWAL, PRETERM');
    }

    // Parse amount safely
    final amountValue = row['amount'];
    double amount;
    if (amountValue == null) {
      throw ArgumentError('Release: amount is required');
    } else if (amountValue is num) {
      amount = amountValue.toDouble();
    } else if (amountValue is String) {
      amount = double.tryParse(amountValue) ??
               (double.tryParse(amountValue.replaceAll(',', '')) ??
               (throw ArgumentError('Release: amount must be a valid number, got: $amountValue')));
    } else {
      throw ArgumentError('Release: amount must be a number, got: ${amountValue.runtimeType}');
    }

    if (amount < 0) {
      throw ArgumentError('Release: amount cannot be negative, got: $amount');
    }

    // Validate status
    final status = row['status']?.toString() ?? 'pending';
    if (!ReleaseStatus.isValid(status)) {
      throw ArgumentError('Release: invalid status: $status. Must be one of: pending, approved, rejected, disbursed');
    }

    // Parse dates safely
    final createdAt = DateUtils.safeParse(row['created_at']);
    if (createdAt == null) {
      throw ArgumentError('Release: created_at is required and must be a valid date');
    }

    final updatedAt = DateUtils.safeParse(row['updated_at']);
    if (updatedAt == null) {
      throw ArgumentError('Release: updated_at is required and must be a valid date');
    }

    return Release(
      id: id,
      clientId: clientId,
      userId: userId,
      visitId: visitId,
      productType: productType,
      loanType: loanType,
      amount: amount,
      approvalNotes: row['approval_notes']?.toString(),
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'client_id': clientId,
      'user_id': userId,
      'visit_id': visitId,
      'product_type': productType,
      'loan_type': loanType,
      'amount': amount,
      'approval_notes': approvalNotes,
      'status': status,
    };
  }

  /// Get product type enum
  ProductType get productTypeEnum => ProductType.fromValueOrFirst(productType);

  /// Get loan type enum
  LoanType get loanTypeEnum => LoanType.fromValueOrFirst(loanType);

  /// Get status enum
  ReleaseStatus get statusEnum => ReleaseStatus.fromValueOrFirst(status);
}
