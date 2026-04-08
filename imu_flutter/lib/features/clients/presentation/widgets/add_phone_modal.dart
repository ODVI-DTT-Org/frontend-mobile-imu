import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import 'package:imu_flutter/features/clients/data/models/phone_number_model.dart';

/// Modal dialog for adding or editing a phone number
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

      isSubmitting.value = true;

      try {
        final data = {
          'label': label.value.name,
          'number': number.text.trim(),
          'is_primary': isPrimary.value,
        };

        final result = await onSubmit(clientId, data);

        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving phone number: $e'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.phone,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    initialPhone == null ? 'Add Phone Number' : 'Edit Phone Number',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

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
                  ],
                ),
              ),
            ),
          ],
        ),
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
