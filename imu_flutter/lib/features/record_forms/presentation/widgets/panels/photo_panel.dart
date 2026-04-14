// lib/features/record_forms/presentation/widgets/panels/photo_panel.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/utils/app_notification.dart';

class PhotoPanel extends StatelessWidget {
  final String? photoPath;
  final ValueChanged<String?> onPhotoCaptured;
  final VoidCallback onPhotoRemoved;
  final String? error;

  const PhotoPanel({
    super.key,
    this.photoPath,
    required this.onPhotoCaptured,
    required this.onPhotoRemoved,
    this.error,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();

    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        onPhotoCaptured(photo.path);
      }
    } catch (e) {
      if (context.mounted) {
        AppNotification.showError(context, 'Failed to capture photo: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;
    final hasError = error != null || !hasPhoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo (Required)',
          style: theme.textTheme.labelSmall?.copyWith(
            color: hasError ? theme.colorScheme.error : null,
          ),
        ),
        const SizedBox(height: 8),

        // Photo preview or capture button
        if (hasPhoto) ...[
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Center(
                  child: photoPath!.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: photoPath!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            LucideIcons.imageOff,
                            size: 48,
                            color: Colors.grey,
                          ),
                        )
                      : Image.file(
                          File(photoPath!),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              LucideIcons.imageOff,
                              size: 48,
                              color: Colors.grey,
                            );
                          },
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(LucideIcons.x),
                    onPressed: onPhotoRemoved,
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          InkWell(
            onTap: () => _pickImage(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: error != null
                    ? theme.colorScheme.errorContainer.withOpacity(0.1)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.camera,
                    size: 32,
                    color: error != null
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to take photo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: error != null
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Error text
        if (error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 14,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
