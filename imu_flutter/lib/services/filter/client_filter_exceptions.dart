// lib/services/filter/client_filter_exceptions.dart
/// Custom exception types for client filter operations

/// Thrown when PowerSync is not available but required for filtering
class PowerSyncUnavailableException implements Exception {
  final String message;
  final dynamic originalError;

  PowerSyncUnavailableException(this.message, [this.originalError]);

  @override
  String toString() => 'PowerSyncUnavailableException: $message${originalError != null ? ' (caused by: $originalError)' : ''}';
}

/// Thrown when filter options fail to load from both PowerSync and API
class FilterOptionsLoadException implements Exception {
  final String message;
  final dynamic originalError;

  FilterOptionsLoadException(this.message, [this.originalError]);

  @override
  String toString() => 'FilterOptionsLoadException: $message${originalError != null ? ' (caused by: $originalError)' : ''}';
}

/// Thrown when filter values are invalid or malformed
class InvalidFilterValueException implements Exception {
  final String message;
  final String? filterType;
  final dynamic invalidValue;

  InvalidFilterValueException(this.message, {this.filterType, this.invalidValue});

  @override
  String toString() => 'InvalidFilterValueException: $message${filterType != null ? ' (filter: $filterType)' : ''}${invalidValue != null ? ' (value: $invalidValue)' : ''}';
}
