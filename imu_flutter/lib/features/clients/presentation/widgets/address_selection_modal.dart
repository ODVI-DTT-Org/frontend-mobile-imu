import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import 'package:imu_flutter/features/clients/data/models/address_model.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/address_list_tile.dart';

/// Modal dialog for selecting an address from a list
/// Used when creating touchpoints to select which address to visit
class AddressSelectionModal extends StatelessWidget {
  final List<Address> addresses;
  final String? selectedAddressId;
  final Function(Address) onAddressSelected;

  const AddressSelectionModal({
    super.key,
    required this.addresses,
    this.selectedAddressId,
    required this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                    'Select Address',
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

            // Address List
            Flexible(
              child: addresses.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.mapPin,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No addresses found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add an address for this client first',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final address = addresses[index];
                        final isSelected = address.id == selectedAddressId;

                        return InkWell(
                          onTap: () {
                            onAddressSelected(address);
                            Navigator.of(context).pop(address);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Radio indicator
                                Icon(
                                  isSelected
                                      ? LucideIcons.circleCheck
                                      : LucideIcons.circle,
                                  size: 24,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),

                                // Address details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Label badge
                                      if (address.label != AddressLabel.home) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            address.label.displayName,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.onSecondaryContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],

                                      // Primary badge
                                      if (address.isPrimary) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                LucideIcons.star,
                                                size: 12,
                                                color: theme.colorScheme.onPrimaryContainer,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Primary',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: theme.colorScheme.onPrimaryContainer,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],

                                      // Street address
                                      if (address.streetAddress != null &&
                                          address.streetAddress!.isNotEmpty)
                                        Text(
                                          address.streetAddress!,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                      if (address.streetAddress != null &&
                                          address.streetAddress!.isNotEmpty)
                                        const SizedBox(height: 4),

                                      // Full address (PSGC)
                                      Text(
                                        address.fullAddress,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),

                                      // Postal code
                                      if (address.postalCode != null &&
                                          address.postalCode!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          address.postalCode!,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Cancel button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
