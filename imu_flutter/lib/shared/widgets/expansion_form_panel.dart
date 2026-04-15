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
        borderRadius: BorderRadius.circular(8),
        color: errorText != null
            ? theme.colorScheme.errorContainer.withOpacity(0.1)
            : null,
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: errorText != null
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: errorText != null
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!isExpanded)
                          DefaultTextStyle(
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            child: summary,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ],

          // Error text
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    size: 12,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
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
