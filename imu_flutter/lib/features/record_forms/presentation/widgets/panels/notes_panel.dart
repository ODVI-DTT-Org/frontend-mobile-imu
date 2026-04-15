// lib/features/record_forms/presentation/widgets/panels/notes_panel.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NotesPanel extends StatelessWidget {
  final String? remarks;
  final ValueChanged<String?> onRemarksChanged;
  final String? error;
  final int maxLength;

  const NotesPanel({
    super.key,
    this.remarks,
    required this.onRemarksChanged,
    this.error,
    this.maxLength = 255,
  });

  int get currentLength => remarks?.length ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = error != null;
    final isNearLimit = currentLength > maxLength * 0.9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Remarks',
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasError ? theme.colorScheme.error : null,
                fontSize: 12,
              ),
            ),
            Text(
              '$currentLength/$maxLength',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: isNearLimit
                    ? Colors.orange
                    : (hasError ? theme.colorScheme.error : theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: TextEditingController(text: remarks)..selection = TextSelection.fromPosition(TextPosition(offset: remarks?.length ?? 0)),
            maxLines: 3,
            maxLength: maxLength,
            onChanged: (value) {
              if (value.isEmpty) {
                onRemarksChanged(null);
              } else {
                onRemarksChanged(value);
              }
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              hintText: 'Add notes about this visit...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 13,
              ),
              counterText: '', // Hide default counter, using custom one
            ),
            style: TextStyle(fontSize: 14),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 12,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontSize: 12,
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
