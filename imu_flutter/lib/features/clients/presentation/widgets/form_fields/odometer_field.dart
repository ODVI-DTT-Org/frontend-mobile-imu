import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Reusable odometer number input field with km suffix
class OdometerField extends HookWidget {
  final String label;
  final String? initialValue;
  final ValueChanged<String?> onChanged;
  final bool showError;

  const OdometerField({
    super.key,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialValue);

    // Update controller when initialValue changes externally
    useEffect(() {
      if (initialValue != null && controller.text != initialValue) {
        controller.text = initialValue!;
      }
    }, [initialValue]);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(
          color: showError
            ? Colors.red[600]!
            : Colors.grey[300]!,
          width: showError ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          prefixIcon: Icon(
            LucideIcons.gauge,
            size: 18,
            color: Colors.grey[600],
          ),
          suffix: Text(
            'km',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(fontSize: 15),
        onChanged: (value) {
          // Call the onChanged callback with the current value
          onChanged(value.isEmpty ? null : value);
        },
      ),
    );
  }
}
