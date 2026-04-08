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
    return Release(
      id: row['id'] as String,
      clientId: row['client_id'] as String,
      userId: row['user_id'] as String,
      visitId: row['visit_id'] as String,
      productType: row['product_type'] as String,
      loanType: row['loan_type'] as String,
      amount: (row['amount'] as num).toDouble(),
      approvalNotes: row['approval_notes'] as String?,
      status: row['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
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
}

enum ProductType {
  pusu('PUSU'),
  lika('LIKA'),
  sub2k('SUB2K');

  final String value;
}
