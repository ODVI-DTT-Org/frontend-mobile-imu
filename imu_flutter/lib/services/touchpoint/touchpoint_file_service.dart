import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/upload_api_service.dart';
import '../../core/utils/logger.dart';

/// Touchpoint file upload result
class TouchpointFileUpload {
  final String touchpointId;
  final String? photoUrl;
  final String? audioUrl;
  final bool success;
  final String? errorMessage;

  TouchpointFileUpload({
    required this.touchpointId,
    this.photoUrl,
    this.audioUrl,
    required this.success,
    this.errorMessage,
  });
}

/// Service for managing file uploads associated with touchpoints
///
/// This service handles uploading photos and audio files for touchpoints
/// with retry logic and progress tracking.
class TouchpointFileService {
  final UploadApiService _uploadApi;

  TouchpointFileService(this._uploadApi);

  /// Upload photo for a touchpoint
  ///
  /// Parameters:
  /// - [file]: The photo file to upload
  /// - [touchpointId]: The ID of the touchpoint
  /// - [onProgress]: Optional callback for upload progress (0-100)
  ///
  /// Returns the URL of the uploaded photo, or null if failed
  Future<String?> uploadPhoto(
    File file,
    String touchpointId, {
    void Function(int progress)? onProgress,
  }) async {
    try {
      logDebug('Uploading photo for touchpoint: $touchpointId');

      final result = await _uploadApi.uploadWithRetry(
        file,
        category: 'touchpoint_photo',
        touchpointId: touchpointId,
        maxRetries: 3,
        onProgress: onProgress,
      );

      if (result != null) {
        logDebug('Photo uploaded successfully: ${result.url}');
        return result.url;
      } else {
        logError('Photo upload failed for touchpoint: $touchpointId');
        return null;
      }
    } catch (e) {
      logError('Error uploading photo for touchpoint: $touchpointId', e);
      return null;
    }
  }

  /// Upload audio for a touchpoint
  ///
  /// Parameters:
  /// - [file]: The audio file to upload
  /// - [touchpointId]: The ID of the touchpoint
  /// - [onProgress]: Optional callback for upload progress (0-100)
  ///
  /// Returns the URL of the uploaded audio, or null if failed
  Future<String?> uploadAudio(
    File file,
    String touchpointId, {
    void Function(int progress)? onProgress,
  }) async {
    try {
      logDebug('Uploading audio for touchpoint: $touchpointId');

      final result = await _uploadApi.uploadWithRetry(
        file,
        category: 'audio',
        touchpointId: touchpointId,
        maxRetries: 3,
        onProgress: onProgress,
      );

      if (result != null) {
        logDebug('Audio uploaded successfully: ${result.url}');
        return result.url;
      } else {
        logError('Audio upload failed for touchpoint: $touchpointId');
        return null;
      }
    } catch (e) {
      logError('Error uploading audio for touchpoint: $touchpointId', e);
      return null;
    }
  }

  /// Upload both photo and audio for a touchpoint
  ///
  /// Parameters:
  /// - [photo]: Optional photo file to upload
  /// - [audio]: Optional audio file to upload
  /// - [touchpointId]: The ID of the touchpoint
  /// - [onPhotoProgress]: Optional callback for photo upload progress (0-100)
  /// - [onAudioProgress]: Optional callback for audio upload progress (0-100)
  ///
  /// Returns [TouchpointFileUpload] with the URLs of uploaded files
  Future<TouchpointFileUpload> uploadFiles({
    File? photo,
    File? audio,
    required String touchpointId,
    void Function(int progress)? onPhotoProgress,
    void Function(int progress)? onAudioProgress,
  }) async {
    try {
      logDebug('Uploading files for touchpoint: $touchpointId');

      String? photoUrl;
      String? audioUrl;

      // Upload photo if provided
      if (photo != null) {
        photoUrl = await uploadPhoto(
          photo,
          touchpointId,
          onProgress: onPhotoProgress,
        );
      }

      // Upload audio if provided
      if (audio != null) {
        audioUrl = await uploadAudio(
          audio,
          touchpointId,
          onProgress: onAudioProgress,
        );
      }

      // Check if at least one upload succeeded
      final success = photoUrl != null || audioUrl != null;

      return TouchpointFileUpload(
        touchpointId: touchpointId,
        photoUrl: photoUrl,
        audioUrl: audioUrl,
        success: success,
        errorMessage: success ? null : 'All file uploads failed',
      );
    } catch (e) {
      logError('Error uploading files for touchpoint: $touchpointId', e);
      return TouchpointFileUpload(
        touchpointId: touchpointId,
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Upload files for a touchpoint that hasn't been created yet
  ///
  /// Use this when you need to upload files before creating the touchpoint.
  /// The files will be uploaded without a touchpoint_id and can be linked later.
  ///
  /// Parameters:
  /// - [photo]: Optional photo file to upload
  /// - [audio]: Optional audio file to upload
  /// - [onPhotoProgress]: Optional callback for photo upload progress (0-100)
  /// - [onAudioProgress]: Optional callback for audio upload progress (0-100)
  ///
  /// Returns a map with 'photoUrl' and 'audioUrl' keys
  Future<Map<String, String?>> uploadFilesForNewTouchpoint({
    File? photo,
    File? audio,
    void Function(int progress)? onPhotoProgress,
    void Function(int progress)? onAudioProgress,
  }) async {
    try {
      logDebug('Uploading files for new touchpoint');

      String? photoUrl;
      String? audioUrl;

      // Upload photo if provided (without touchpoint_id)
      if (photo != null) {
        final result = await _uploadApi.uploadWithRetry(
          photo,
          category: 'touchpoint_photo',
          touchpointId: null, // No touchpoint ID yet
          maxRetries: 3,
          onProgress: onPhotoProgress,
        );
        photoUrl = result?.url;
      }

      // Upload audio if provided (without touchpoint_id)
      if (audio != null) {
        final result = await _uploadApi.uploadWithRetry(
          audio,
          category: 'audio',
          touchpointId: null, // No touchpoint ID yet
          maxRetries: 3,
          onProgress: onAudioProgress,
        );
        audioUrl = result?.url;
      }

      return {
        'photoUrl': photoUrl,
        'audioUrl': audioUrl,
      };
    } catch (e) {
      logError('Error uploading files for new touchpoint', e);
      return {
        'photoUrl': null,
        'audioUrl': null,
      };
    }
  }
}

/// Provider for TouchpointFileService
final touchpointFileServiceProvider = Provider<TouchpointFileService>((ref) {
  final uploadApi = ref.watch(uploadApiServiceProvider);
  return TouchpointFileService(uploadApi);
});
