import 'client_model.dart';

enum PhoneLabel {
  mobile('Mobile'),
  home('Home'),
  work('Work');

  final String displayName;
  const PhoneLabel(this.displayName);

  static PhoneLabel fromString(String value) {
    return PhoneLabel.values.firstWhere(
      (label) => label.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PhoneLabel.mobile,
    );
  }
}

class PhoneNumber {
  final String id;
  final String clientId;
  final PhoneLabel label;
  final String number;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  PhoneNumber({
    required this.id,
    required this.clientId,
    required this.label,
    required this.number,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory from PowerSync database row
  factory PhoneNumber.fromSyncMap(Map<String, dynamic> map) {
    return PhoneNumber(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      label: PhoneLabel.fromString(map['label'] as String? ?? 'mobile'),
      number: map['number'] as String? ?? '',
      isPrimary: (map['is_primary'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  // Factory from legacy client field
  factory PhoneNumber.fromLegacyField(Client client) {
    return PhoneNumber(
      id: 'legacy_${client.id}',
      clientId: client.id ?? '',
      label: PhoneLabel.mobile,
      number: client.phone ?? '',
      isPrimary: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'label': label.name,
      'number': number,
      'is_primary': isPrimary,
    };
  }

  // Copy with method
  PhoneNumber copyWith({
    String? id,
    String? clientId,
    PhoneLabel? label,
    String? number,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PhoneNumber(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      label: label ?? this.label,
      number: number ?? this.number,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Format phone number for display
  String get displayNumber {
    // Simple formatting for PH numbers
    final cleaned = number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length == 11 && cleaned.startsWith('0')) {
      return '${cleaned.substring(0, 4)}-${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    } else if (cleaned.length == 12 && cleaned.startsWith('63')) {
      return '+${cleaned.substring(0, 2)} ${cleaned.substring(2, 5)} ${cleaned.substring(5, 8)} ${cleaned.substring(8)}';
    }
    return number;
  }

  @override
  String toString() {
    return 'PhoneNumber(id: $id, label: $label, number: $displayNumber, isPrimary: $isPrimary)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhoneNumber && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
