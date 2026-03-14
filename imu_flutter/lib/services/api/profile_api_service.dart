import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/api/pocketbase_client.dart';
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
class ProfileApiService {
  final PocketBase _pb;

  ProfileApiService({required PocketBase pb}) : _pb = pb;

  Future<UserProfile> fetchProfile(String userId) async {
    try {
      debugPrint('ProfileApiService: Fetching profile for user $userId');
      final result = await _pb.collection('users').getOne(userId);
      debugPrint('ProfileApiService: Fetched profile for user ${result.id}');
      return UserProfile.fromJson(result.data);
    } on ClientException catch (e) {
      debugPrint('ProfileApiService: Error fetching profile - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }

  Future<UserProfile> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      debugPrint('ProfileApiService: Updating profile for user $userId');
      final result = await _pb.collection('users').update(userId, body: data);
      debugPrint('ProfileApiService: Updated profile for user ${result.id}');
      return UserProfile.fromJson(result.data);
    } on ClientException catch (e) {
      debugPrint('ProfileApiService: Error updating profile - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }

  Future<String?> uploadAvatar(String userId, String filePath) async {
    try {
      debugPrint('ProfileApiService: Uploading avatar for user $userId');
      final result = await _pb.collection('users').update(
        userId,
        body: {},
        files: [
          await createMultipartFile(filePath),
        ],
      );
      debugPrint('ProfileApiService: Uploaded avatar for user ${result.id}');
      return result.data['avatar'] as String?;
    } on ClientException catch (e) {
      debugPrint('ProfileApiService: Error uploading avatar - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
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
  final pb = ref.watch(pocketBaseProvider);
  return ProfileApiService(pb: pb);
});
