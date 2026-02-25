import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Camera service for capturing photos
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Capture a photo from camera
  Future<File?> capturePhoto({
    int imageQuality = 85,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  /// Pick an image from gallery
  Future<File?> pickFromGallery({
    int imageQuality = 85,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      return null;
    }
  }

  /// Capture multiple photos
  Future<List<File>> captureMultiplePhotos({
    int limit = 5,
    int imageQuality = 85,
  }) async {
    try {
      final List<XFile> photos = await _picker.pickMultiImage(
        imageQuality: imageQuality,
      );

      if (photos.length > limit) {
        return photos.take(limit).map((xFile) => File(xFile.path)).toList();
      }

      return photos.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      debugPrint('Error capturing multiple photos: $e');
      return [];
    }
  }

  /// Delete a photo file
  Future<bool> deletePhoto(File photo) async {
    try {
      if (await photo.exists()) {
        await photo.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      return false;
    }
  }
}

/// Widget for displaying a photo with options to retake or remove
class PhotoCaptureWidget extends StatefulWidget {
  final File? initialPhoto;
  final Function(File) onPhotoCaptured;
  final VoidCallback? onPhotoRemoved;
  final String placeholderText;
  final double width;
  final double height;

  const PhotoCaptureWidget({
    super.key,
    this.initialPhoto,
    required this.onPhotoCaptured,
    this.onPhotoRemoved,
    this.placeholderText = 'Tap to capture photo',
    this.width = 200,
    this.height = 150,
  });

  @override
  State<PhotoCaptureWidget> createState() => _PhotoCaptureWidgetState();
}

class _PhotoCaptureWidgetState extends State<PhotoCaptureWidget> {
  final CameraService _cameraService = CameraService();
  File? _photo;

  @override
  void initState() {
    super.initState();
    _photo = widget.initialPhoto;
  }

  Future<void> _capturePhoto() async {
    final photo = await _cameraService.capturePhoto();
    if (photo != null) {
      setState(() => _photo = photo);
      widget.onPhotoCaptured(photo);
    }
  }

  Future<void> _showOptions() async {
    if (_photo != null) {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Retake Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _capturePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final photo = await _cameraService.pickFromGallery();
                  if (photo != null) {
                    setState(() => _photo = photo);
                    widget.onPhotoCaptured(photo);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photo = null);
                  widget.onPhotoRemoved?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    } else {
      _capturePhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showOptions,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          image: _photo != null
              ? DecorationImage(
                  image: FileImage(_photo!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _photo == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.placeholderText,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
