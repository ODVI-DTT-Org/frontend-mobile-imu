// lib/shared/models/bulk_delete_models.dart

enum BulkDeleteStatus {
  deleting,
  completed,
  partialFailure,
  error,
}

class BulkDeleteError {
  final String id;
  final String error;
  final String? itemName;

  BulkDeleteError({
    required this.id,
    required this.error,
    this.itemName,
  });

  factory BulkDeleteError.fromJson(Map<String, dynamic> json) {
    return BulkDeleteError(
      id: json['id'] as String,
      error: json['error'] as String? ?? 'Unknown error',
      itemName: json['item_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'error': error,
    if (itemName != null) 'item_name': itemName,
  };
}

class BulkDeleteResult {
  final int successCount;
  final int errorCount;
  final List<BulkDeleteError> errors;
  final String? message;

  BulkDeleteResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
    this.message,
  });

  factory BulkDeleteResult.fromJson(Map<String, dynamic> json, {String? responseKey}) {
    final key = responseKey ?? 'response';
    final data = json[key] as Map<String, dynamic>? ?? json;

    final errorsList = data['errors'] as List<dynamic>? ?? [];
    final errors = errorsList
        .map((e) => BulkDeleteError.fromJson(e as Map<String, dynamic>))
        .toList();

    return BulkDeleteResult(
      successCount: data['deleted'] as int? ?? data['removed'] as int? ?? 0,
      errorCount: data['failed'] as int? ?? 0,
      errors: errors,
      message: data['message'] as String?,
    );
  }

  bool get isSuccessful => errorCount == 0;
  bool get isPartialFailure => successCount > 0 && errorCount > 0;
  bool get isCompleteFailure => successCount == 0;

  Map<String, dynamic> toJson() => {
    'successCount': successCount,
    'errorCount': errorCount,
    'errors': errors.map((e) => e.toJson()).toList(),
    if (message != null) 'message': message,
  };
}
