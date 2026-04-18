import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import 'package:imu_flutter/features/clients/data/models/address_model.dart';
import 'package:imu_flutter/features/clients/data/repositories/address_repository.dart';
import 'package:imu_flutter/shared/widgets/psgc_selector.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart' show addressRepositoryProvider, jwtAuthProvider, powerSyncDatabaseProvider;
import 'package:imu_flutter/core/utils/app_notification.dart';
import '../../../../core/models/user_role.dart';

/// Full screen page for adding or editing an address
class AddAddressPage extends HookConsumerWidget {
  final String clientId;
  final Address? initialAddress;

  const AddAddressPage({
    super.key,
    required this.clientId,
    this.initialAddress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final addressRepo = ref.read(addressRepositoryProvider);
    final currentUser = ref.read(jwtAuthProvider).currentUser;
    final requiresApproval = currentUser?.role == UserRole.tele || currentUser?.role == UserRole.caravan;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final label = useState<AddressLabel>(initialAddress?.label ?? AddressLabel.home);
    final streetAddress = useTextEditingController(text: initialAddress?.streetAddress ?? '');
    final postalCode = useTextEditingController(text: initialAddress?.postalCode ?? '');
    final latitude = useState<double?>(initialAddress?.latitude);
    final longitude = useState<double?>(initialAddress?.longitude);
    final isPrimary = useState<bool>(initialAddress?.isPrimary ?? false);
    final isSaving = useState<bool>(false);
    final selectedPsgc = useState<PsgcData?>(null);

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) return;

      if (selectedPsgc.value == null) {
        AppNotification.showWarning(context, 'Please select a location');
        return;
      }

      isSaving.value = true;

      try {
        final data = {
          'type': label.value.name,
          'street': streetAddress.text.trim(),
          'barangay': selectedPsgc.value!.barangay,
          'city': selectedPsgc.value!.municipality,
          'province': selectedPsgc.value!.province,
          'postal_code': postalCode.text.trim(),
          'latitude': latitude.value,
          'longitude': longitude.value,
          'is_primary': isPrimary.value,
        };

        if (requiresApproval) {
          final db = ref.read(powerSyncDatabaseProvider).value;
          if (db == null) throw Exception('Database not available');
          await db.execute(
            'INSERT INTO approvals (id, type, status, client_id, user_id, role, reason, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [const Uuid().v4(), 'address_add', 'pending', clientId, currentUser!.id, currentUser.role.apiValue, 'Add Address Request', jsonEncode(data)],
          );
        } else {
          await addressRepo.createAddress(clientId, data);
        }

        if (context.mounted) {
          final message = requiresApproval
              ? 'Address submitted for approval'
              : 'Address added successfully';
          AppNotification.showSuccess(context, message);
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(context, 'Error saving address: $e');
        }
      } finally {
        isSaving.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(initialAddress == null ? 'Add Address' : 'Edit Address'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label Selection
                Text(
                  'Address Type',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
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

                const SizedBox(height: 24),

                // PSGC Location Selector
                Text(
                  'Location *',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                PSGCSelector(
                  initialPsgcId: initialAddress?.psgcId.toString(),
                  onPsgcSelected: (psgc) {
                    selectedPsgc.value = psgc;
                  },
                ),

                const SizedBox(height: 24),

                // Street Address
                Text(
                  'Street Address',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: streetAddress,
                  decoration: const InputDecoration(
                    labelText: 'House/Unit/Lot number, Street name',
                    hintText: 'Ex: 123 Main Street, Block 5',
                    prefixIcon: Icon(LucideIcons.mapPin),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 16),

                // Postal Code
                Text(
                  'Postal Code',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: postalCode,
                  decoration: const InputDecoration(
                    labelText: 'ZIP code',
                    hintText: 'Ex: 1234',
                    prefixIcon: Icon(LucideIcons.mail),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 24),

                // GPS Coordinates (optional)
                Text(
                  'GPS Coordinates (Optional)',
                  style: theme.textTheme.titleMedium,
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

                const SizedBox(height: 24),

                // Set as Primary
                SwitchListTile(
                  value: isPrimary.value,
                  onChanged: (value) => isPrimary.value = value,
                  title: const Text('Set as Primary Address'),
                  subtitle: const Text('This will be used as the default address'),
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSaving.value ? null : handleSubmit,
                    child: isSaving.value
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
