/// User profile model
class UserProfile {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String? profilePhotoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.profilePhotoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    if (firstName.isEmpty && lastName.isEmpty) return '?';
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  UserProfile copyWith({
    String? id,
    String? employeeId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? role,
    String? profilePhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'role': role,
    'profilePhotoUrl': profilePhotoUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'Field Agent',
      profilePhotoUrl: json['profilePhotoUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Mock profile for development
  static UserProfile mock() {
    return UserProfile(
      id: 'user-1',
      employeeId: 'EMP-2024-001',
      firstName: 'Juan',
      lastName: 'Dela Cruz',
      email: 'juan.delacruz@company.com',
      phone: '+63 912 345 6789',
      role: 'Field Agent - Caravan',
      createdAt: DateTime(2024, 1, 15),
    );
  }
}
