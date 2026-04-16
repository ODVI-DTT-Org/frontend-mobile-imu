import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import 'package:imu_flutter/features/clients/data/models/phone_number_model.dart';
import 'package:imu_flutter/core/utils/app_notification.dart';

/// Bottom sheet for adding or editing a phone number
class AddPhoneModal extends HookWidget {
  final String clientId;
  final PhoneNumber? initialPhone;
  final Future<PhoneNumber> Function(String clientId, Map<String, dynamic> data) onSubmit;

  const AddPhoneModal({
    super.key,
    required this.clientId,
    this.initialPhone,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final label = useState<PhoneLabel>(initialPhone?.label ?? PhoneLabel.mobile);
    final number = useTextEditingController(text: initialPhone?.number ?? '');
    final isPrimary = useState<bool>(initialPhone?.isPrimary ?? false);
    final isSubmitting = useState<bool>(false);

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) return;

      // Show confirmation dialog before submitting
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(LucideIcons.phone, color: theme.colorScheme.primary),
          title: const Text('Add Phone Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Number: ${number.text.trim()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Type: ${label.value.displayName}'),
              if (isPrimary.value) ...[
                const SizedBox(height: 4),
                Text(
                  'Set as primary',
                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Add this phone number?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isSubmitting.value = true;

      try {
        final data = {
          'label': label.value.name,
          'number': number.text.trim(),
          'is_primary': isPrimary.value,
        };

        final result = await onSubmit(clientId, data);

        if (context.mounted) {
          AppNotification.showSuccess(context, 'Phone number added successfully');
          Navigator.of(context).pop(result);
        }
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(context, 'Error saving phone number: $e');
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.phone,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  initialPhone == null ? 'Add Phone Number' : 'Edit Phone Number',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Form
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label Selection
                  Text(
                    'Phone Type',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<PhoneLabel>(
                    segments: PhoneLabel.values.map((l) {
                      return ButtonSegment(
                        value: l,
                        label: Text(l.displayName),
                        icon: Icon(_getLabelIcon(l), size: 16),
                      );
                    }).toList(),
                    selected: {label.value},
                    onSelectionChanged: (Set<PhoneLabel> selected) {
                      label.value = selected.first;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Phone Number
                  TextFormField(
                    controller: number,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: '09XX XXX XXXX',
                      prefixIcon: Icon(LucideIcons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 13,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
                      if (cleaned.length < 11) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                    autofillHints: const [AutofillHints.telephoneNumber],
                  ),

                  const SizedBox(height: 8),

                  // Helper text
                  Text(
                    'Format: 09XX XXX XXXX or +63 XXX XXX XXXX',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Set as Primary
                  SwitchListTile(
                    value: isPrimary.value,
                    onChanged: (value) => isPrimary.value = value,
                    title: const Text('Set as Primary Number'),
                    subtitle: const Text('This will be used as the default phone number'),
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting.value ? null : handleSubmit,
                      child: isSubmitting.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(initialPhone == null ? 'Add Phone Number' : 'Save Changes'),
                    ),
                  ),

                  // Bottom padding for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLabelIcon(PhoneLabel label) {
    switch (label) {
      case PhoneLabel.mobile:
        return LucideIcons.smartphone;
      case PhoneLabel.home:
        return LucideIcons.phone;
      case PhoneLabel.work:
        return LucideIcons.phoneCall;
    }
  }
}
