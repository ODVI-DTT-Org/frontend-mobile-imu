// lib/services/aws/file_upload_service.dart
import 'dart:io';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 's3_service.dart';
import '../../core/utils/logger.dart';

/// Upload queue item
class UploadQueueItem {
  final String id;
  final String touchpointId;
  final String type; // 'photo' | 'audio'
  final String filePath;
  final DateTime createdAt;
  DateTime? lastAttemptAt;
  int? attemptCount;

  UploadQueueItem({
    required this.id,
    required this.touchpointId,
    required this.type,
    required this.filePath,
    DateTime? createdAt,
    this.lastAttemptAt,
    this.attemptCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'touchpointId': touchpointId,
      'type': type,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'attemptCount': attemptCount,
    };
  }

  factory UploadQueueItem.fromJson(Map<String, dynamic> json) {
    return UploadQueueItem(
      id: json['id'],
      touchpointId: json['touchpointId'],
      type: json['type'],
      filePath: json['filePath'],
      createdAt: DateTime.parse(json['createdAt']),
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'])
          : null,
      attemptCount: json['attemptCount'] ?? 0,
    );
  }
}

/// File upload service with offline queue support
class FileUploadService {
  final S3Service _s3Service;
  final String _queueBoxName = 'file_upload_queue';
  final int _maxRetries = 3;
  final Duration _retryDelay = const Duration(seconds: 30);

  FileUploadService(this._s3Service);

  /// Upload a photo file
  /// Returns the URL of the uploaded photo or null if failed
  Future<String?> uploadPhoto(File photo, String touchpointId) async {
    try {
      logDebug('Uploading photo for touchpoint: $touchpointId');

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${touchpointId}_photo_$timestamp.jpg';

      // Upload to S3 (path: photos/touchpoints/{touchpointId}, filename)
      final url = await _s3Service.uploadFile(
        photo,
        'photos/touchpoints/$touchpointId',
        filename,
      );

      if (url != null) {
        logDebug('Photo uploaded successfully: $url');
        return url;
      } else {
        logError('Failed to upload photo for touchpoint: $touchpointId');
        return null;
      }
    } catch (e) {
      logError('Error uploading photo', e);
      return null;
    }
  }

  /// Upload an audio file
  /// Returns the URL of the uploaded audio or null if failed
  Future<String?> uploadAudio(File audio, String touchpointId) async {
    try {
      logDebug('Uploading audio for touchpoint: $touchpointId');

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${touchpointId}_audio_$timestamp.m4a';

      // Upload to S3 (path: audio/touchpoints/{touchpointId}, filename)
      final url = await _s3Service.uploadFile(
        audio,
        'audio/touchpoints/$touchpointId',
        filename,
      );

      if (url != null) {
        logDebug('Audio uploaded successfully: $url');
        return url;
      } else {
        logError('Failed to upload audio for touchpoint: $touchpointId');
        return null;
      }
    } catch (e) {
      logError('Error uploading audio', e);
      return null;
    }
  }

  /// Queue a file for upload (offline support)
  /// Returns the queue item ID
  Future<String> queueUpload(File file, String touchpointId, String type) async {
    try {
      logDebug('Queueing $type upload for touchpoint: $touchpointId');

      // Create queue item
      final uuid = const Uuid();
      final item = UploadQueueItem(
        id: uuid.v4(),
        touchpointId: touchpointId,
        type: type,
        filePath: file.path,
      );

      // Save to queue
      await _addToQueue(item);

      logDebug('File queued for upload: ${item.id}');
      return item.id;
    } catch (e) {
      logError('Error queuing upload', e);
      rethrow;
    }
  }

  /// Process all pending uploads
  /// Returns the number of successful uploads
  Future<int> processPendingUploads() async {
    try {
      // Load queue
      final queueBox = await Hive.openBox<UploadQueueItem>(_queueBoxName);
      final pendingItems = queueBox.values
          .where((item) => item.attemptCount == null || item.attemptCount! < _maxRetries)
          .toList();

      logDebug('Found ${pendingItems.length} pending uploads');

      int successful = 0;
      final List<String> toRemove = [];

      for (final item in pendingItems) {
        try {
          // Check if file still exists
          final file = File(item.filePath);
          if (!await file.exists()) {
            logDebug('File not found: ${item.filePath}, skipping upload');
            toRemove.add(item.id);
            continue;
          }

          // Upload file
          String? url;
          if (item.type == 'photo') {
            url = await uploadPhoto(file, item.touchpointId);
          } else if (item.type == 'audio') {
            url = await uploadAudio(file, item.touchpointId);
          }

          if (url != null) {
            // Upload successful
            toRemove.add(item.id);
            successful++;
            logDebug('Queued upload completed successfully: ${item.id}');
          } else {
            // Upload failed, retry later
            await _updateQueueItem(
              item.id,
              attemptCount: (item.attemptCount ?? 1) + 1,
              lastAttemptAt: DateTime.now(),
            );
            logDebug('Upload failed, will retry later: ${item.id}');
          }
        } catch (e) {
          logError('Error processing queued upload: ${item.id}', e);
          await _updateQueueItem(
            item.id,
            attemptCount: (item.attemptCount ?? 1) + 1,
            lastAttemptAt: DateTime.now(),
          );
        }
      }

      // Remove successful uploads from queue
      for (final id in toRemove) {
        await _removeFromQueue(id);
      }

      logDebug('Completed processing uploads: $successful successful, ${toRemove.length} completed');
      return successful;
    } catch (e) {
      logError('Error processing pending uploads', e);
      return 0;
    }
  }

  /// Get all pending uploads
  Future<List<UploadQueueItem>> getPendingUploads() async {
    try {
      final queueBox = await Hive.openBox<UploadQueueItem>(_queueBoxName);
      return queueBox.values.toList();
    } catch (e) {
      logError('Error getting pending uploads', e);
      return [];
    }
  }

  /// Clear the upload queue
  Future<void> clearQueue() async {
    try {
      logDebug('Clearing file upload queue');
      final queueBox = await Hive.openBox<UploadQueueItem>(_queueBoxName);
      await queueBox.clear();
    } catch (e) {
      logError('Error clearing upload queue', e);
    }
  }

  /// Helper method to add item to queue
  Future<void> _addToQueue(UploadQueueItem item) async {
    try {
      final queueBox = await Hive.openBox<UploadQueueItem>(_queueBoxName);
      await queueBox.put(item.id, item);
    } catch (e) {
      logError('Error adding to queue', e);
      rethrow;
    }
  }

  /// Helper method to update queue item
  Future<void> _updateQueueItem(
    String id, {
    int? attemptCount,
    DateTime? lastAttemptAt,
  }) async {
    try {
      final queueBox = await Hive.openBox<UploadQueueItem>(_queueBoxName);
      final item = queueBox.get(id);
      if (item != null) {
        if (attemptCount != null) {
          item.attemptCount = attemptCount;
        }
        if (lastAttemptAt != null) {
          item.lastAttemptAt = lastAttemptAt;
        }
        await queueBox.put(id, item);
      }
    } catch (e) {
      logError('Error updating queue item', e);
      rethrow;
    }
  }

  /// Helper method to remove item from queue
  Future<void> _removeFromQueue(String id) async {
    try {
      final queueBox = await Hive.openBox<UploadQueueItem>(_queueBoxName);
      await queueBox.delete(id);
    } catch (e) {
      logError('Error removing from queue', e);
      rethrow;
    }
  }
}
