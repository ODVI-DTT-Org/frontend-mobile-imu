import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart' show jwtAuthProvider;
import 'package:imu_flutter/core/config/app_config.dart';

/// Upload result model
class UploadResult {
  final String url;
  final String key;
  final String fileId;
  final String originalName;
  final int size;
  final String type;

  UploadResult({
    required this.url,
    required this.key,
    required this.fileId,
    required this.originalName,
    required this.size,
    required this.type,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      url: json['url'] as String,
      key: json['key'] as String? ?? json['filename'] as String? ?? '',
      fileId: json['file_id'] as String? ?? '',
      originalName: json['original_name'] as String? ?? json['filename'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      type: json['type'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'UploadResult(url: $url, key: $key, fileId: $fileId)';
  }
}

/// Upload API service for file uploads (photos, audio, documents)
class UploadApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  UploadApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        )),
        _authService = authService ?? JwtAuthService();

  /// Upload a photo file for a touchpoint
  ///
  /// Parameters:
  /// - [file]: The photo file to upload
  /// - [touchpointId]: Optional touchpoint ID to link the file to
  ///
  /// Returns [UploadResult] with file URL and metadata, or null if failed
  Future<UploadResult?> uploadPhoto(File file, {String? touchpointId}) async {
    try {
      debugPrint('UploadApiService: Uploading photo for touchpoint: $touchpointId');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('UploadApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Prepare multipart form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: _getFileName(file.path),
        ),
        'category': 'touchpoint_photo',
        if (touchpointId != null) 'entity_id': touchpointId,
        if (touchpointId != null) 'entity_type': 'touchpoint',
      });

      // Make the API request
      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/upload/file',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // Don't set Content-Type manually - Dio will set it with proper boundary
          },
        ),
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = (sent / total * 100).toInt();
            debugPrint('UploadApiService: Photo upload progress: $progress%');
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = UploadResult.fromJson(response.data);
        debugPrint('UploadApiService: Photo uploaded successfully: $result');
        return result;
      } else {
        debugPrint('UploadApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to upload photo: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('UploadApiService: DioException - ${e.message}');
      debugPrint('UploadApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('UploadApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to upload photo',
        originalError: e,
      );
    }
  }

  /// Upload an audio file for a touchpoint
  ///
  /// Parameters:
  /// - [file]: The audio file to upload
  /// - [touchpointId]: Optional touchpoint ID to link the file to
  ///
  /// Returns [UploadResult] with file URL and metadata, or null if failed
  Future<UploadResult?> uploadAudio(File file, {String? touchpointId}) async {
    try {
      debugPrint('UploadApiService: Uploading audio for touchpoint: $touchpointId');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('UploadApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Prepare multipart form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: _getFileName(file.path),
        ),
        'category': 'audio',
        if (touchpointId != null) 'entity_id': touchpointId,
        if (touchpointId != null) 'entity_type': 'touchpoint',
      });

      // Make the API request
      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/upload/file',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // Don't set Content-Type manually - Dio will set it with proper boundary
          },
        ),
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = (sent / total * 100).toInt();
            debugPrint('UploadApiService: Audio upload progress: $progress%');
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = UploadResult.fromJson(response.data);
        debugPrint('UploadApiService: Audio uploaded successfully: $result');
        return result;
      } else {
        debugPrint('UploadApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to upload audio: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('UploadApiService: DioException - ${e.message}');
      debugPrint('UploadApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('UploadApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to upload audio',
        originalError: e,
      );
    }
  }

  /// Upload a file with retry logic
  ///
  /// Parameters:
  /// - [file]: The file to upload
  /// - [category]: The file category (touchpoint_photo, audio, etc.)
  /// - [touchpointId]: Optional touchpoint ID to link the file to
  /// - [maxRetries]: Maximum number of retry attempts (default: 3)
  /// - [onProgress]: Optional callback for upload progress (0-100)
  ///
  /// Returns [UploadResult] with file URL and metadata, or null if failed after all retries
  Future<UploadResult?> uploadWithRetry(
    File file, {
    required String category,
    String? touchpointId,
    int maxRetries = 3,
    void Function(int progress)? onProgress,
  }) async {
    int attempt = 0;
    UploadResult? result;

    while (attempt < maxRetries) {
      try {
        debugPrint('UploadApiService: Upload attempt ${attempt + 1}/$maxRetries');

        // Get the access token
        final token = _authService.accessToken;
        if (token == null) {
          debugPrint('UploadApiService: No access token available');
          throw ApiException(message: 'Not authenticated');
        }

        // Prepare multipart form data
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: _getFileName(file.path),
          ),
          'category': category,
          if (touchpointId != null) 'entity_id': touchpointId,
          if (touchpointId != null) 'entity_type': 'touchpoint',
        });

        // Make the API request
        final response = await _dio.post(
          '${AppConfig.postgresApiUrl}/upload/file',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              // Don't set Content-Type manually - Dio will set it with proper boundary
            },
          ),
          data: formData,
          onSendProgress: (sent, total) {
            if (total > 0) {
              final progress = (sent / total * 100).toInt();
              debugPrint('UploadApiService: Upload progress: $progress%');
              onProgress?.call(progress);
            }
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          result = UploadResult.fromJson(response.data);
          debugPrint('UploadApiService: Upload successful: $result');
          break;
        } else {
          debugPrint('UploadApiService: API returned status ${response.statusCode}');
          throw ApiException(message: 'Failed to upload: ${response.statusCode}');
        }
      } on DioException catch (e) {
        attempt++;
        debugPrint('UploadApiService: Upload attempt $attempt failed - ${e.message}');

        if (attempt >= maxRetries) {
          debugPrint('UploadApiService: Max retries reached');
          throw ApiException(
            message: 'Upload failed after $maxRetries attempts',
            originalError: e,
          );
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: 2 * attempt));
      } catch (e) {
        debugPrint('UploadApiService: Unexpected error - $e');
        attempt++;

        if (attempt >= maxRetries) {
          throw ApiException(
            message: 'Upload failed after $maxRetries attempts',
            originalError: e,
          );
        }

        // Wait before retrying
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }

    return result;
  }

  /// Get upload categories and their constraints
  Future<Map<String, dynamic>> getUploadCategories() async {
    try {
      debugPrint('UploadApiService: Fetching upload categories...');

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/upload/categories',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(message: 'Failed to fetch categories: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('UploadApiService: Error fetching categories - $e');
      throw ApiException(
        message: 'Failed to fetch upload categories',
        originalError: e,
      );
    }
  }

  /// Extract filename from file path
  String _getFileName(String path) {
    return path.split('/').last.split('\\').last;
  }
}

/// Provider for UploadApiService
final uploadApiServiceProvider = Provider<UploadApiService>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  return UploadApiService(authService: jwtAuth);
});
