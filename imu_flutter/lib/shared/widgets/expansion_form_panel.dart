// lib/shared/widgets/expansion_form_panel.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExpansionFormPanel extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget summary;
  final Widget child;
  final String? errorText;

  const ExpansionFormPanel({
    super.key,
    required this.title,
    this.icon,
    required this.isExpanded,
    required this.onTap,
    required this.summary,
    required this.child,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: errorText != null
              ? theme.colorScheme.error
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
        color: errorText != null
            ? theme.colorScheme.errorContainer.withOpacity(0.1)
            : null,
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: errorText != null
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: errorText != null
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (!isExpanded) summary,
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],

          // Error text
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
