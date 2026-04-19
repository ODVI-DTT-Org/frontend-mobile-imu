import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart'
    show SectionCard;

class PhotoCard extends StatelessWidget {
  final String? photoPath;
  final void Function(String path) onPhotoTaken;
  final bool showError;

  const PhotoCard({
    super.key,
    required this.photoPath,
    required this.onPhotoTaken,
    required this.showError,
  });

  bool get _hasPhoto => photoPath != null && photoPath!.isNotEmpty;
  bool get _hasError => showError && !_hasPhoto;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) onPhotoTaken(picked.path);
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'PHOTO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hasError
                      ? const Color(0xFFEF4444)
                      : (_hasPhoto
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFE5E7EB)),
                  width: _hasError ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _hasPhoto
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFF9FAFB),
              ),
              child: _hasPhoto
                  ? Row(children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(7),
                          bottomLeft: Radius.circular(7),
                        ),
                        child: Image.file(
                          File(photoPath!),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: const Color(0xFFDCFCE7),
                            child: const Icon(Icons.image, color: Color(0xFF16A34A)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(children: [
                            Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                            SizedBox(width: 6),
                            Text(
                              'Photo Captured',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ]),
                          Text(
                            'Tap to retake',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ])
                  : Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: _hasError
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Take Photo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _hasError
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (_hasError)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Photo is required',
                style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
              ),
            ),
        ],
      ),
    );
  }
}
