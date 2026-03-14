import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';

/// Touchpoint selector: 1st through 7th + Archive
class TouchpointSelector extends StatelessWidget {
  final int selectedTouchpoint;
  final ValueChanged<int> onTouchpointSelected;
  final VoidCallback onArchiveTap;

  const TouchpointSelector({
    super.key,
    required this.selectedTouchpoint,
    required this.onTouchpointSelected,
    required this.onArchiveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...List.generate(7, (index) => _buildTouchpointButton(index + 1)),
          _buildArchiveButton(),
        ],
      ),
    );
  }

  Widget _buildTouchpointButton(int number) {
    final isSelected = selectedTouchpoint == number;
    final isVisit = number == 1 || number == 4 || number == 7;

    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        onTouchpointSelected(number);
      },
      child: Container(
        width: 42,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVisit ? LucideIcons.mapPin : LucideIcons.phone,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(height: 4),
            Text(
              _getOrdinal(number),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveButton() {
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        onArchiveTap();
      },
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.archive,
              size: 18,
              color: Color(0xFF64748B),
            ),
            SizedBox(height: 4),
            Text(
              'Archive',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getOrdinal(int number) {
    switch (number) {
      case 1: return '1st';
      case 2: return '2nd';
      case 3: return '3rd';
      case 4: return '4th';
      case 5: return '5th';
      case 6: return '6th';
      case 7: return '7th';
      default: return '${number}th';
    }
  }
}
