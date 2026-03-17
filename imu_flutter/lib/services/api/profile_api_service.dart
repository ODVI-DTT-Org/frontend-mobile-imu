import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/api/api_exception.dart';

/// User profile model
class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatarUrl;
  final String? agencyName;
  final String? position;
  final String? department;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.avatarUrl,
    this.agencyName,
    this.position,
    this.department,
    required this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatar'],
      agencyName: json['agency_name'],
      position: json['position'],
      department: json['department'],
      createdAt: DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated'] != null ? DateTime.parse(json['updated']) : null,
    );
  }
}

/// Profile API service
/// TODO: Phase 1 - Will be updated to work with PowerSync/Supabase backend
class ProfileApiService {
  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      debugPrint('ProfileApiService: fetchProfile for user $userId (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      return null;
    } catch (e) {
      debugPrint('ProfileApiService: Error fetching profile - $e');
      throw ApiException.fromError(e);
    }
  }

  Future<UserProfile?> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      debugPrint('ProfileApiService: updateProfile for user $userId (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase update
      return null;
    } catch (e) {
      debugPrint('ProfileApiService: Error updating profile - $e');
      throw ApiException.fromError(e);
    }
  }

  Future<String?> uploadAvatar(String userId, String filePath) async {
    try {
      debugPrint('ProfileApiService: uploadAvatar for user $userId (PowerSync integration pending)');
      // TODO: Phase 1 - Implement file upload
      return null;
    } catch (e) {
      debugPrint('ProfileApiService: Error uploading avatar - $e');
      throw ApiException.fromError(e);
    }
  }
}

/// Helper to create multipart file from path
Future<MultipartFile> createMultipartFile(String filePath) async {
  final file = await MultipartFile.fromPath('avatar', filePath);
  return file;
}

/// Provider for ProfileApiService
final profileApiServiceProvider = Provider<ProfileApiService>((ref) {
  return ProfileApiService();
});
