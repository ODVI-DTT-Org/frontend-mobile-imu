import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Reusable odometer number input field
class OdometerField extends HookWidget {
  final String label;
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const OdometerField({
    super.key,
    required this.label,
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialValue);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[50],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          prefixIcon: Icon(
            LucideIcons.gauge,
            size: 16,
            color: Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        style: const TextStyle(fontSize: 14),
        onChanged: onChanged,
      ),
    );
  }
}
