import 'package:flutter/material.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart'
    show SectionCard;

class NotesCard extends StatelessWidget {
  final TextEditingController controller;
  final bool showError;

  const NotesCard({super.key, required this.controller, required this.showError});

  bool get _isEmpty => controller.text.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final hasError = showError && _isEmpty;
    return SectionCard(
      title: 'NOTES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Remarks',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: 4,
            maxLength: 255,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12),
              hintText: 'Enter remarks...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasError ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
                  width: hasError ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasError ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
          ),
          if (hasError)
            const Text(
              'Remarks is required',
              style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
        ],
      ),
    );
  }
}
