import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/touchpoint/touchpoint_file_service.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/utils/loading_helper.dart';

/// Extension method to integrate file upload into TouchpointFormModal
///
/// This shows how to modify the existing touchpoint form to include
/// file upload functionality before creating the touchpoint.
extension TouchpointFormUploadExtension on ConsumerState {
  /// Upload files before creating touchpoint
  ///
  /// This method should be called in _handleSubmit before navigating back
  /// with the form data. It uploads the captured photo/audio files and
  /// returns their URLs.
  Future<Map<String, String?>> uploadTouchpointFiles({
    required File? photo,
    required File? audio,
    bool showProgress = true,
  }) async {
    // Use LoadingHelper for consistent loading experience
    if (showProgress) {
      try {
        final fileService = ref.read(touchpointFileServiceProvider);

        // Build appropriate message based on what's being uploaded
        String message = 'Uploading files...';
        if (photo != null && audio != null) {
          message = 'Uploading photo and audio...';
        } else if (photo != null) {
          message = 'Uploading photo...';
        } else if (audio != null) {
          message = 'Uploading audio...';
        }

        // Upload files with loading overlay
        final urls = await LoadingHelper.withLoading(
          ref: ref,
          message: message,
          operation: () => fileService.uploadFilesForNewTouchpoint(
            photo: photo,
            audio: audio,
            onPhotoProgress: (progress) {
              // Progress tracking available but not shown in overlay
              debugPrint('Photo upload progress: $progress%');
            },
            onAudioProgress: (progress) {
              // Progress tracking available but not shown in overlay
              debugPrint('Audio upload progress: $progress%');
            },
          ),
          onError: (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Upload failed: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );

        return urls ?? {'photoUrl': null, 'audioUrl': null};
      } catch (e) {
        // Error already handled by onError callback
        rethrow;
      }
    } else {
      // No loading overlay, just upload
      final fileService = ref.read(touchpointFileServiceProvider);
      return await fileService.uploadFilesForNewTouchpoint(
        photo: photo,
        audio: audio,
      );
    }
  }
}

/// Progress dialog for file uploads
class UploadProgressDialog extends StatefulWidget {
  const UploadProgressDialog({super.key});

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();

  /// Update progress for a specific file type
  static void updateProgress(BuildContext context, String type, int progress) {
    final state = context.findAncestorStateOfType<_UploadProgressDialogState>();
    state?.setProgress(type, progress);
  }
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  final Map<String, int> _progress = {
    'Photo': 0,
    'Audio': 0,
  };

  void setProgress(String type, int progress) {
    setState(() {
      _progress[type] = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Uploading files...',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          // Photo progress
          if (_progress['Photo']! > 0 || _progress['Audio']! > 0) ...[
            _buildProgressItem('Photo', _progress['Photo']!),
            const SizedBox(height: 8),
            _buildProgressItem('Audio', _progress['Audio']!),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, int progress) {
    final isActive = progress > 0;
    final isComplete = progress == 100;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: isActive ? progress / 100 : 0,
            backgroundColor: Colors.grey[200],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            isComplete ? 'Done' : (isActive ? '$progress%' : ''),
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

/// Example usage in TouchpointFormModal:
///
/// ```dart
/// class _TouchpointFormModalState extends ConsumerState<TouchpointFormModal> {
///   File? _capturedPhoto;
///   File? _capturedAudio;
///   bool _isUploading = false;
///
///   Future<void> _handleSubmit() async {
///     if (_formKey.currentState!.validate()) {
///       setState(() => _isUploading = true);
///
///       try {
///         // Upload files before creating touchpoint
///         final urls = await uploadTouchpointFiles(
///           photo: _capturedPhoto,
///           audio: _capturedAudio,
///         );
///
///         // Now return form data with uploaded URLs
///         Navigator.pop(context, {
///           'reason': _selectedReason,
///           // Use uploaded URLs instead of local paths
///           'photoPath': urls['photoUrl'],
///           'audioPath': urls['audioUrl'],
///           // ... other fields
///         });
///       } catch (e) {
///         // Error already shown by uploadTouchpointFiles
///       } finally {
///         setState(() => _isUploading = false);
///       }
///     }
///   }
/// }
/// ```

/// Alternative: Manual upload without progress dialog
///
/// If you prefer not to use the extension method, you can manually upload:
///
/// ```dart
/// Future<void> _handleSubmit() async {
///   if (!_formKey.currentState!.validate()) return;
///
///   // Show simple loading indicator
///   setState(() => _isUploading = true);
///
///   try {
///     // Get the file service
///     final fileService = ref.read(touchpointFileServiceProvider);
///
///     // Upload files
///     final urls = await fileService.uploadFilesForNewTouchpoint(
///       photo: _capturedPhoto,
///       audio: _capturedAudio,
///     );
///
///     // Create touchpoint with uploaded URLs
///     final formState = ref.read(touchpointFormProvider);
///     final timeIn = formState.timeIn;
///     final timeOut = formState.timeOut;
///
///     Navigator.pop(context, {
///       'reason': _selectedReason,
///       'timeIn': timeIn.time?.toIso8601String(),
///       'timeInGpsLat': timeIn.gpsLat,
///       'timeInGpsLng': timeIn.gpsLng,
///       'timeInGpsAddress': timeIn.gpsAddress,
///       'timeOut': timeOut.time?.toIso8601String(),
///       'timeOutGpsLat': timeOut.gpsLat,
///       'timeOutGpsLng': timeOut.gpsLng,
///       'timeOutGpsAddress': timeOut.gpsAddress,
///       'timeArrival': timeIn.time != null
///           ? _formatDateTime(timeIn.time!)
///           : null,
///       'timeDeparture': timeOut.time != null
///           ? _formatDateTime(timeOut.time!)
///           : null,
///       'odometerArrival': _odometerArrivalController.text,
///       'odometerDeparture': _odometerDepartureController.text,
///       'nextVisitDate': _nextVisitDate?.toIso8601String(),
///       // Use uploaded URLs instead of local file paths
///       'photoPath': urls['photoUrl'],
///       'audioPath': urls['audioUrl'],
///       'location': timeIn.gpsLat != null && timeIn.gpsLng != null
///           ? {
///               'latitude': timeIn.gpsLat,
///               'longitude': timeIn.gpsLng,
///               'address': timeIn.gpsAddress,
///               'accuracy': null,
///             }
///           : null,
///     });
///
///     ScaffoldMessenger.of(context).showSnackBar(
///       const SnackBar(
///         content: Text('Touchpoint saved successfully'),
///         backgroundColor: Colors.green,
///       ),
///     );
///   } catch (e) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(
///         content: Text('Upload failed: $e'),
///         backgroundColor: Colors.red,
///       ),
///     );
///   } finally {
///     setState(() => _isUploading = false);
///   }
/// }
/// ```

/// Uploading files AFTER touchpoint creation
///
/// If you prefer to create the touchpoint first and upload files later:
///
/// ```dart
/// // 1. Create touchpoint without files
/// final touchpoint = await ref
///     .read(touchpointRepositoryProvider)
///     .createTouchpoint(touchpoint);
///
/// // 2. Upload files with touchpoint ID
/// final fileService = ref.read(touchpointFileServiceProvider);
/// final result = await fileService.uploadFiles(
///   photo: photoFile,
///   audio: audioFile,
///   touchpointId: touchpoint.id,
/// );
///
/// // 3. Update touchpoint with uploaded URLs
/// if (result.success) {
///   final updated = touchpoint.copyWith(
///     photoPath: result.photoUrl,
///     audioPath: result.audioUrl,
///   );
///   await ref.read(touchpointRepositoryProvider).updateTouchpoint(updated);
/// }
/// ```
