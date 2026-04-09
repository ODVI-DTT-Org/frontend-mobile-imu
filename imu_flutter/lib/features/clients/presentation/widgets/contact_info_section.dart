import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/clients/data/models/address_model.dart';
import 'package:imu_flutter/features/clients/data/models/phone_number_model.dart';

/// Widget that displays client contact information (addresses and phone numbers)
/// Shows primary address/phone prominently with fallback to legacy fields
class ContactInfoSection extends StatelessWidget {
  final Client client;
  final VoidCallback? onViewAddresses;
  final VoidCallback? onViewPhoneNumbers;
  final VoidCallback? onAddAddress;
  final VoidCallback? onAddPhoneNumber;

  const ContactInfoSection({
    super.key,
    required this.client,
    this.onViewAddresses,
    this.onViewPhoneNumbers,
    this.onAddAddress,
    this.onAddPhoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAddress = client.primaryAddress;
    final primaryPhone = client.primaryPhone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Addresses Section
        _buildSection(
          context,
          title: 'Address',
          icon: LucideIcons.mapPin,
          child: primaryAddress != null
              ? _buildPrimaryAddress(context, primaryAddress)
              : _buildLegacyAddress(context),
          actionLabel: client.addresses.length > 1 ? 'View All (${client.addresses.length})' : null,
          onActionPressed: onViewAddresses,
          onAddPressed: onAddAddress,
        ),

        const SizedBox(height: 16),

        // Phone Numbers Section
        _buildSection(
          context,
          title: 'Phone Numbers',
          icon: LucideIcons.phone,
          child: primaryPhone != null
              ? _buildPrimaryPhone(context, primaryPhone)
              : _buildLegacyPhone(context),
          actionLabel: client.phoneNumbers.length > 1 ? 'View All (${client.phoneNumbers.length})' : null,
          onActionPressed: onViewPhoneNumbers,
          onAddPressed: onAddPhoneNumber,
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onAddPressed,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (actionLabel != null)
                TextButton(
                  onPressed: onActionPressed,
                  child: Text(actionLabel),
                ),
              if (onAddPressed != null)
                IconButton(
                  onPressed: onAddPressed,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  tooltip: 'Add',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          child,
        ],
      ),
    );
  }

  Widget _buildPrimaryAddress(BuildContext context, Address address) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (address.label != AddressLabel.home) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              address.label.displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (address.streetAddress != null && address.streetAddress!.isNotEmpty)
          Text(
            address.streetAddress!,
            style: theme.textTheme.bodyMedium,
          ),
        if (address.streetAddress != null && address.streetAddress!.isNotEmpty)
          const SizedBox(height: 4),
        Text(
          address.fullAddress,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (address.postalCode != null && address.postalCode!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            address.postalCode!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegacyAddress(BuildContext context) {
    final theme = Theme.of(context);
    final hasAddress = client.address != null && client.address!.isNotEmpty;
    final hasProvince = client.province != null && client.province!.isNotEmpty;
    final hasMunicipality = client.municipality != null && client.municipality!.isNotEmpty;
    final hasBarangay = client.barangay != null && client.barangay!.isNotEmpty;

    if (!hasAddress && !hasProvince && !hasMunicipality && !hasBarangay) {
      return _buildEmptyState(
        context,
        message: 'No address information available',
        icon: LucideIcons.mapPin,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasAddress)
          Text(
            client.address!,
            style: theme.textTheme.bodyMedium,
          ),
        if (hasAddress && (hasProvince || hasMunicipality || hasBarangay))
          const SizedBox(height: 4),
        if (hasProvince || hasMunicipality || hasBarangay)
          Text(
            [
              if (hasBarangay) client.barangay,
              if (hasMunicipality) client.municipality,
              if (hasProvince) client.province,
            ].where((s) => s != null && s!.isNotEmpty).join(', '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildPrimaryPhone(BuildContext context, PhoneNumber phone) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          _getPhoneIcon(phone.label),
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          phone.displayNumber,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (phone.label != PhoneLabel.mobile) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              phone.label.displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegacyPhone(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhone = client.phone != null && client.phone!.isNotEmpty;

    if (!hasPhone) {
      return _buildEmptyState(
        context,
        message: 'No phone number available',
        icon: LucideIcons.phone,
      );
    }

    return Row(
      children: [
        const Icon(
          LucideIcons.phone,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          client.phone!,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String message,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  IconData _getPhoneIcon(PhoneLabel label) {
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
