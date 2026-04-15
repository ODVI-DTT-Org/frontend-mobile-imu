import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import 'package:imu_flutter/features/clients/data/models/address_model.dart';
import 'package:imu_flutter/shared/widgets/psgc_selector.dart';

/// Bottom sheet for adding or editing an address
class AddAddressModal extends HookWidget {
  final String clientId;
  final Address? initialAddress;
  final Future<Address> Function(String clientId, Map<String, dynamic> data) onSubmit;

  const AddAddressModal({
    super.key,
    required this.clientId,
    this.initialAddress,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final streetAddress = useTextEditingController(text: initialAddress?.streetAddress ?? '');
    final psgcId = useState<String?>(initialAddress?.psgcId?.toString());
    final isSubmitting = useState<bool>(false);

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) return;

      isSubmitting.value = true;

      try {
        final data = {
          'street_address': streetAddress.text.trim(),
          'psgc_id': psgcId.value,
        };

        final result = await onSubmit(clientId, data);

        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving address: $e'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
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
                  LucideIcons.mapPin,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  initialAddress == null ? 'Add Address' : 'Edit Address',
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
          Flexible(
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PSGC Location Selector
                    Text(
                      'Location (Region, Province, Municipality, Barangay) *',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    PSGCSelector(
                      initialPsgcId: psgcId.value,
                      onPsgcSelected: (psgc) {
                        psgcId.value = psgc.id;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Street Address
                    TextFormField(
                      controller: streetAddress,
                      decoration: const InputDecoration(
                        labelText: 'Street Address *',
                        hintText: 'House/Unit/Lot number, Street name',
                        prefixIcon: Icon(LucideIcons.mapPin),
                      ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Street address is required';
                        }
                        return null;
                      },
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
                            : Text(initialAddress == null ? 'Add Address' : 'Save Changes'),
                      ),
                    ),

                    // Bottom padding for safe area
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
