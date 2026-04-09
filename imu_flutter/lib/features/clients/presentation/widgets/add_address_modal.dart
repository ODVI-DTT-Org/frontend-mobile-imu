import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import 'package:imu_flutter/features/clients/data/models/address_model.dart';
import 'package:imu_flutter/shared/widgets/psgc_selector.dart';

/// Modal dialog for adding or editing an address
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
    final label = useState<AddressLabel>(initialAddress?.label ?? AddressLabel.home);
    final streetAddress = useTextEditingController(text: initialAddress?.streetAddress ?? '');
    final postalCode = useTextEditingController(text: initialAddress?.postalCode ?? '');
    final psgcId = useState<String?>(initialAddress?.psgcId);
    final latitude = useState<double?>(initialAddress?.latitude);
    final longitude = useState<double?>(initialAddress?.longitude);
    final isPrimary = useState<bool>(initialAddress?.isPrimary ?? false);
    final isSubmitting = useState<bool>(false);

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) return;

      isSubmitting.value = true;

      try {
        final data = {
          'label': label.value.name,
          'street_address': streetAddress.text.trim(),
          'postal_code': postalCode.text.trim(),
          'psgc_id': psgcId.value,
          'latitude': latitude.value,
          'longitude': longitude.value,
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
              content: Text('Error saving address: $e'),
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
                    LucideIcons.mapPin,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    initialAddress == null ? 'Add Address' : 'Edit Address',
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
            Flexible(
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label Selection
                      Text(
                        'Address Type',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<AddressLabel>(
                        segments: AddressLabel.values.map((l) {
                          return ButtonSegment(
                            value: l,
                            label: Text(l.displayName),
                            icon: Icon(_getLabelIcon(l), size: 16),
                          );
                        }).toList(),
                        selected: {label.value},
                        onSelectionChanged: (Set<AddressLabel> selected) {
                          label.value = selected.first;
                        },
                      ),

                      const SizedBox(height: 16),

                      // PSGC Location Selector
                      Text(
                        'Location *',
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
                          labelText: 'Street Address',
                          hintText: 'House/Unit/Lot number, Street name',
                          prefixIcon: Icon(LucideIcons.mapPin),
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 16),

                      // Postal Code
                      TextFormField(
                        controller: postalCode,
                        decoration: const InputDecoration(
                          labelText: 'Postal Code',
                          hintText: 'ZIP code',
                          prefixIcon: Icon(LucideIcons.mail),
                        ),
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 16),

                      // GPS Coordinates (optional, for future use)
                      Text(
                        'GPS Coordinates (Optional)',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: latitude.value?.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                prefixIcon: Icon(LucideIcons.map),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                signed: true,
                                decimal: true,
                              ),
                              onChanged: (value) {
                                latitude.value = double.tryParse(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: longitude.value?.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                prefixIcon: Icon(LucideIcons.map),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                signed: true,
                                decimal: true,
                              ),
                              onChanged: (value) {
                                longitude.value = double.tryParse(value);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Set as Primary
                      SwitchListTile(
                        value: isPrimary.value,
                        onChanged: (value) => isPrimary.value = value,
                        title: const Text('Set as Primary Address'),
                        subtitle: const Text('This will be used as the default address'),
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
                              : Text(initialAddress == null ? 'Add Address' : 'Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLabelIcon(AddressLabel label) {
    switch (label) {
      case AddressLabel.home:
        return LucideIcons.home;
      case AddressLabel.work:
        return LucideIcons.briefcase;
      case AddressLabel.relative:
        return LucideIcons.users;
      case AddressLabel.other:
        return LucideIcons.moreHorizontal;
    }
  }
}
