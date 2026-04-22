import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../clients/data/models/client_model.dart';
import '../../../clients/data/models/address_model.dart' as addr;
import '../../../clients/data/models/phone_number_model.dart' as ph;
import '../../../../services/maps/map_service.dart';

/// Contact Information Expansion Panel
/// Displays all client contact information including phone numbers,
/// email, addresses, and social media
class ContactInformationExpansionPanel extends StatelessWidget {
  final Client client;
  final VoidCallback onAddPhone;
  final VoidCallback onAddAddress;

  const ContactInformationExpansionPanel({
    super.key,
    required this.client,
    required this.onAddPhone,
    required this.onAddAddress,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'CONTACT INFORMATION',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        '4 sections',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhoneNumbersSection(),
              const SizedBox(height: 16),
              _buildEmailSection(),
              const SizedBox(height: 16),
              _buildAddressesSection(context),
              const SizedBox(height: 16),
              _buildSocialMediaSection(),
            ],
          ),
        ),
      ],
    );
  }

  List<ph.PhoneNumber> _effectivePhoneNumbers() {
    final phones = List<ph.PhoneNumber>.from(client.phoneNumbers);
    if (client.phone != null && client.phone!.isNotEmpty) {
      final alreadyListed = phones.any((p) => p.number == client.phone);
      if (!alreadyListed) {
        phones.add(ph.PhoneNumber.fromLegacyField(client));
      }
    }
    return phones;
  }

  Widget _buildPhoneNumbersSection() {
    final phones = _effectivePhoneNumbers();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHONE NUMBERS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...phones.map((phone) => _buildPhoneNumberTile(phone)),
              const SizedBox(height: 8),
              _buildAddButton('+ Add Phone Number', onAddPhone),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneNumberTile(ph.PhoneNumber phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            phone.label == ph.PhoneLabel.mobile
                ? LucideIcons.smartphone
                : LucideIcons.phone,
            size: 18,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phone.number,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[900],
                  ),
                ),
                if (phone.label != ph.PhoneLabel.mobile)
                  Text(
                    phone.label.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (phone.isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 10, color: Colors.blue[700]),
                  const SizedBox(width: 2),
                  Text(
                    'Primary',
                    style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(LucideIcons.phone, size: 16, color: Colors.green[700]),
            onPressed: () => _makeCall(phone.number),
            tooltip: 'Call',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(LucideIcons.messageCircle, size: 16, color: Colors.blue[700]),
            onPressed: () => _sendSMS(phone.number),
            tooltip: 'SMS',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EMAIL',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (client.email != null && client.email!.isNotEmpty)
                Row(
                  children: [
                    Icon(LucideIcons.mail, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        client.email!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.send, size: 16, color: Colors.blue[700]),
                      onPressed: () => _sendEmail(client.email!),
                      tooltip: 'Send Email',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                )
              else
                Text('No email', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 8),
              _buildAddButton('+ Add Email', () {}),
            ],
          ),
        ),
      ],
    );
  }

  List<addr.Address> _effectiveAddresses() {
    final addresses = List<addr.Address>.from(client.addresses);
    final legacyFull = client.fullAddress;
    if (legacyFull.isNotEmpty) {
      final alreadyListed = addresses.any((a) => a.fullAddress == legacyFull);
      if (!alreadyListed) {
        addresses.add(addr.Address.fromLegacyFields(client));
      }
    }
    return addresses;
  }

  Widget _buildAddressesSection(BuildContext context) {
    final addresses = _effectiveAddresses();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADDRESSES',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...addresses.map((address) => _buildAddressTile(context, address)),
              const SizedBox(height: 8),
              _buildAddButton('+ Add Address', onAddAddress),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressTile(BuildContext context, addr.Address address) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.mapPin, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address.isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 10, color: Colors.blue[700]),
                        const SizedBox(width: 2),
                        Text(
                          'Primary',
                          style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                        ),
                      ],
                    ),
                  ),
                Text(
                  address.fullAddress,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.navigation, size: 16, color: Colors.green[700]),
            onPressed: () => _openMap(context, address),
            tooltip: 'Navigate',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOCIAL MEDIA',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (client.facebookLink != null && client.facebookLink!.isNotEmpty)
                Row(
                  children: [
                    Icon(LucideIcons.facebook, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        client.facebookLink!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.externalLink, size: 16, color: Colors.grey[700]),
                      onPressed: () => _openLink(client.facebookLink!),
                      tooltip: 'Open',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                )
              else
                Text('No social media links', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 8),
              _buildAddButton('+ Add Social Media', () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  Future<void> _openMap(BuildContext context, addr.Address address) async {
    // Check if address has GPS coordinates
    if (address.latitude != null && address.longitude != null) {
      await _openNavigationPicker(
        context: context,
        latitude: address.latitude!,
        longitude: address.longitude!,
        label: address.fullAddress,
      );
    } else if (address.fullAddress.isNotEmpty) {
      // Fallback to text-based search if no coordinates
      final query = Uri.encodeComponent(address.fullAddress);
      final url = 'https://www.google.com/maps/search/?api=1&query=$query';
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open maps')),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No address available')),
        );
      }
    }
  }

  Future<void> _openNavigationPicker({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Navigate with', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Google Maps'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await MapService().openGoogleMapsNavigation(
                  latitude: latitude,
                  longitude: longitude,
                  label: label,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open Google Maps')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation),
              title: const Text('Waze'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await MapService().openWazeNavigation(
                  latitude: latitude,
                  longitude: longitude,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open Waze')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final Uri launchUri = Uri.parse(url);
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $url');
    }
  }
}
