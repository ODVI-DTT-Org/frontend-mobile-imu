// lib/features/record_forms/presentation/widgets/panels/info_banner_panel.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InfoBannerPanel extends StatelessWidget {
  final List<String> messages;
  final String? title;

  const InfoBannerPanel({
    super.key,
    required this.messages,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 14,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                title ?? 'Auto-set Values',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...messages.map((message) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
