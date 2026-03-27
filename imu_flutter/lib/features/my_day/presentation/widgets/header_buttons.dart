import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';

/// Header buttons for My Day: Multiple Time In and Add Client
class HeaderButtons extends StatelessWidget {
  final VoidCallback onMultipleTimeIn;
  final VoidCallback onAddClient;

  const HeaderButtons({
    super.key,
    required this.onMultipleTimeIn,
    required this.onAddClient,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Multiple Time In button
        Expanded(
          child: _PillButton(
            icon: _buildHandIcons(),
            label: 'Multiple Time In',
            onTap: onMultipleTimeIn,
          ),
        ),
        const SizedBox(width: 12),
        // Add client button
        Expanded(
          child: _PillButton(
            icon: const Icon(LucideIcons.userPlus, size: 16, color: Color(0xFF0F172A)),
            label: 'Add Client',
            onTap: onAddClient,
          ),
        ),
      ],
    );
  }

  Widget _buildHandIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) =>
        Transform.translate(
          offset: Offset(index == 0 ? 0 : -8.0, 0),
          child: const Icon(
            LucideIcons.hand,
            size: 14,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
