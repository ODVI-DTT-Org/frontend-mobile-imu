import '../../../../core/models/user_role.dart';

/// User profile model
class UserProfile {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  final String? profilePhotoUrl;
  // Manager assignment fields
  final String? areaManagerId;
  final String? assistantAreaManagerId;
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
    this.areaManagerId,
    this.assistantAreaManagerId,
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
    UserRole? role,
    String? profilePhotoUrl,
    String? areaManagerId,
    String? assistantAreaManagerId,
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
      areaManagerId: areaManagerId ?? this.areaManagerId,
      assistantAreaManagerId: assistantAreaManagerId ?? this.assistantAreaManagerId,
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
    'role': role.apiValue,
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
      role: UserRole.fromApi(json['role'] as String?),
      profilePhotoUrl: json['profilePhotoUrl'],
      areaManagerId: json['areaManagerId'],
      assistantAreaManagerId: json['assistantAreaManagerId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}
