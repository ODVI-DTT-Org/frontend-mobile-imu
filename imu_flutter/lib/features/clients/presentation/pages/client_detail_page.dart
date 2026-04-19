import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../data/repositories/client_repository.dart' show clientRepositoryProvider;
import '../../../../services/touchpoint/touchpoint_validation_service.dart' hide UserRole;
import '../../../../services/maps/map_service.dart';
import '../../../../services/error_service.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../../shared/providers/app_providers.dart' show
    assignedClientsProvider,
    touchpointApiServiceProvider,
    authNotifierProvider,
    addressRepositoryProvider,
    phoneNumberRepositoryProvider,
    clientMutationServiceProvider,
    jwtAuthProvider,
    powerSyncDatabaseProvider;
import '../../../../core/models/user_role.dart';
import '../../../../services/client/client_mutation_service.dart' show ClientMutationResult;
import '../../../../shared/utils/loading_helper.dart';
import '../../../../shared/widgets/touchpoint_validation_dialog.dart';
import '../../../../shared/widgets/map_widgets/client_map_view.dart';
import '../../../../shared/utils/permission_helpers.dart';
import '../../../clients/data/models/client_model.dart' hide Address, PhoneNumber;
import '../../../clients/data/models/address_model.dart';
import '../../../clients/data/models/phone_number_model.dart';
import '../../../clients/data/repositories/address_repository.dart' show AddressRepository;
import '../../../clients/data/repositories/phone_number_repository.dart' show PhoneNumberRepository;
import '../../../clients/presentation/widgets/add_address_modal.dart';
import '../../../clients/presentation/widgets/add_phone_modal.dart';
import '../../../record_forms/presentation/widgets/record_touchpoint_bottom_sheet.dart';
import '../../../record_forms/presentation/widgets/record_visit_bottom_sheet.dart';
import '../../../record_forms/presentation/widgets/record_loan_release_bottom_sheet.dart';
import '../../../clients/presentation/widgets/client_information_expansion_panel.dart';
import '../../../clients/presentation/widgets/contact_information_expansion_panel.dart';
import '../../../clients/presentation/widgets/touchpoint_history_expansion_panel.dart';
import '../../../clients/presentation/widgets/cms_visit_history_expansion_panel.dart';
import '../../../touchpoints/presentation/widgets/touchpoint_form.dart';

final clientDetailProvider = FutureProvider.family<Client?, String>((ref, clientId) async {
  final clientRepo = ref.watch(clientRepositoryProvider);
  return clientRepo.getClient(clientId);
});

final clientTouchpointsProvider = FutureProvider.family<List<Touchpoint>, String>((ref, clientId) async {
  final clientRepo = ref.watch(clientRepositoryProvider);
  final client = await clientRepo.getClient(clientId);
  return client?.touchpointSummary ?? [];
});

class ClientDetailPage extends ConsumerStatefulWidget {
  final String clientId;

  const ClientDetailPage({
    super.key,
    required this.clientId,
  });

  @override
  ConsumerState<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends ConsumerState<ClientDetailPage> {
  Client? _client;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame to avoid modifying providers during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClient();
    });
  }

  Future<void> _loadClient() async {
    try {
      final clientRepo = ref.read(clientRepositoryProvider);
      Client? client = await clientRepo.getClient(widget.clientId);

      // Load addresses and phone numbers from PowerSync
      if (client != null) {
        try {
          final addressRepo = ref.read(addressRepositoryProvider);
          final phoneRepo = ref.read(phoneNumberRepositoryProvider);

          final addresses = await addressRepo.getAddresses(widget.clientId);
          final phoneNumbers = await phoneRepo.getPhoneNumbers(widget.clientId);

          // Update client with addresses and phone numbers
          client = client.copyWith(
            addresses: addresses,
            phoneNumbers: phoneNumbers,
          );
        } catch (e, stack) {
          debugPrint('Error loading addresses/phones from PowerSync: $e\n$stack');
          // Continue without addresses/phones
        }
      }

      if (mounted) {
        setState(() {
          _client = client;
          _isLoading = false;
        });

        if (client == null) {
          _showNotFoundError();
        }
      }
    } catch (e, stack) {
      debugPrint('Error in _loadClient: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to load client', e);
      }
    }
  }

  Widget _buildSkeletonLoading() {
    // Skeleton box widget for shimmer effect
    Widget skeletonBox({
      required double width,
      required double height,
      Color? color,
      BorderRadius? borderRadius,
      double? marginBottom,
    }) {
      return Container(
        width: width,
        height: height,
        margin: marginBottom != null ? EdgeInsets.only(bottom: marginBottom) : null,
        decoration: BoxDecoration(
          color: color ?? Colors.grey.shade300,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.history),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client header skeleton
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name skeleton
                        skeletonBox(
                          width: 200,
                          height: 24,
                          marginBottom: 8,
                        ),
                        // Client type skeleton
                        skeletonBox(
                          width: 120,
                          height: 16,
                          marginBottom: 8,
                        ),
                        // Product type skeleton
                        skeletonBox(
                          width: 150,
                          height: 14,
                        ),
                      ],
                    ),
                  ),
                  // Status badge skeleton
                  skeletonBox(
                    width: 80,
                    height: 28,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ],
              ),
            ),
            // Quick stats skeleton
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCardSkeleton(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCardSkeleton(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCardSkeleton(),
                  ),
                ],
              ),
            ),
            // Touchpoints section skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  skeletonBox(width: 150, height: 20, marginBottom: 16),
                  ...List.generate(3, (index) => _TouchpointSkeletonItem()),
                ],
              ),
            ),
            // Address section skeleton
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  skeletonBox(width: 100, height: 18, marginBottom: 12),
                  skeletonBox(
                    width: double.infinity,
                    height: 60,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
            // Phone section skeleton
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  skeletonBox(width: 80, height: 18, marginBottom: 8),
                  skeletonBox(
                    width: double.infinity,
                    height: 40,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            // Remarks section skeleton
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  skeletonBox(width: 80, height: 18, marginBottom: 8),
                  skeletonBox(
                    width: double.infinity,
                    height: 60,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotFoundError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Client Not Found'),
        content: const Text('The requested client could not be found.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message, Object error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        content: Text('Error: ${error.toString()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadClient(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${_client?.fullName ?? 'this client'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticUtils.delete();

      ClientMutationResult? deleteResult;
      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Deleting client...',
        operation: () async {
          final mutationService = ref.read(clientMutationServiceProvider);
          deleteResult = await mutationService.deleteClient(widget.clientId);
        },
        onError: (e) {
          if (mounted) {
            AppNotification.showError(context, 'Failed to delete client: $e');
          }
        },
      );

      if (mounted && deleteResult != null) {
        switch (deleteResult!) {
          case ClientMutationResult.success:
            AppNotification.showSuccess(context, 'Client deleted');
            context.pop();
          case ClientMutationResult.requiresApproval:
            AppNotification.showSuccess(context, 'Client deletion submitted for approval');
            context.pop();
          case ClientMutationResult.queued:
            AppNotification.showSuccess(context, 'Client deleted (will sync when online)');
            context.pop();
        }
      }
    }
  }

  Future<void> _navigateToClient() async {
    if (_client == null) return;
    final client = _client!;
    Address? primaryAddress;
    if (client.addresses.isNotEmpty) {
      try {
        primaryAddress = client.addresses.firstWhere((a) => a.isPrimary);
      } catch (_) {
        primaryAddress = client.addresses.first;
      }
    }

    if (primaryAddress?.latitude != null && primaryAddress?.longitude != null) {
      await _openNavigationPicker(
        latitude: primaryAddress!.latitude!,
        longitude: primaryAddress.longitude!,
        label: client.fullName,
      );
    } else if (client.municipality != null && client.province != null) {
      final query = Uri.encodeComponent('${client.municipality}, ${client.province}');
      final url = 'https://www.google.com/maps/search/?api=1&query=$query';
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
        if (mounted) AppNotification.showError(context, 'Could not open maps');
      }
    } else {
      if (mounted) AppNotification.showError(context, 'No location information available');
    }
  }

  Future<void> _navigateToAddress(Address address) async {
    if (address.latitude != null && address.longitude != null) {
      await _openNavigationPicker(
        latitude: address.latitude!,
        longitude: address.longitude!,
        label: address.fullAddress,
      );
    } else if (address.fullAddress.isNotEmpty) {
      final query = Uri.encodeComponent(address.fullAddress);
      final url = 'https://www.google.com/maps/search/?api=1&query=$query';
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
        if (mounted) AppNotification.showError(context, 'Could not open maps');
      }
    } else {
      if (mounted) AppNotification.showError(context, 'No address available');
    }
  }

  Future<void> _openNavigationPicker({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    if (!mounted) return;
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
                final ok = await MapService().openGoogleMapsNavigation(latitude: latitude, longitude: longitude, label: label);
                if (!ok && mounted) AppNotification.showError(context, 'Could not open Google Maps');
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation),
              title: const Text('Waze'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await MapService().openWazeNavigation(latitude: latitude, longitude: longitude);
                if (!ok && mounted) AppNotification.showError(context, 'Could not open Waze');
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

  Future<void> _editClient() async {
    HapticUtils.lightImpact();
    final result = await context.push<bool>('/clients/${widget.clientId}/edit');
    if (result == true) {
      _loadClient();
      ref.invalidate(assignedClientsProvider);
    }
  }

  Future<void> _viewAddresses() async {
    HapticUtils.lightImpact();
    final addressRepo = ref.read(addressRepositoryProvider);

    // Load addresses from PowerSync
    final tableAddresses = await addressRepo.getAddresses(widget.clientId);

    // Include client's legacy address fields if not already represented
    final addresses = List<Address>.from(tableAddresses);
    final legacyFull = _client?.fullAddress ?? '';
    if (legacyFull.isNotEmpty && _client != null) {
      final alreadyListed = addresses.any((a) => a.fullAddress == legacyFull);
      if (!alreadyListed) {
        addresses.add(Address.fromLegacyFields(_client!));
      }
    }

    if (!mounted) return;

    // Show addresses modal
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            AppBar(
              title: Text('Addresses (${addresses.length})'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: addresses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.mapPin, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No addresses', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final address = addresses[index];
                        return _buildAddressListTile(address, addressRepo);
                      },
                    ),
            ),
          ],
        ),
      ),
    );

    // Reload client to refresh UI
    _loadClient();
  }

  Widget _buildAddressListTile(Address address, AddressRepository repo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: address.isPrimary ? Colors.blue.shade300 : Colors.grey.shade300!,
          width: address.isPrimary ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (address.label != AddressLabel.home)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(address.label.displayName, style: const TextStyle(fontSize: 11)),
                ),
              if (address.isPrimary) ...[
                if (address.label != AddressLabel.home) const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.blue),
                      SizedBox(width: 4),
                      Text('Primary', style: TextStyle(fontSize: 11, color: Colors.blue)),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.navigation, size: 18),
                onPressed: () async {
                  HapticUtils.lightImpact();
                  await _navigateToAddress(address);
                },
                tooltip: 'Navigate',
              ),
              if (!address.isPrimary)
                IconButton(
                  icon: const Icon(Icons.star, size: 18),
                  onPressed: () async {
                    await repo.setPrimary(address.id);
                    if (mounted) {
                      Navigator.pop(context);
                      _viewAddresses(); // Refresh
                    }
                  },
                  tooltip: 'Set as Primary',
                ),
            ],
          ),
          if (address.streetAddress != null && address.streetAddress!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(address.streetAddress!, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 4),
          Text(address.fullAddress, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          if (address.postalCode != null && address.postalCode!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(address.postalCode!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Future<void> _addAddress() async {
    HapticUtils.lightImpact();
    final addressRepo = ref.read(addressRepositoryProvider);
    final currentUser = ref.read(jwtAuthProvider).currentUser;
    final requiresApproval = currentUser?.role == UserRole.tele || currentUser?.role == UserRole.caravan;

    final result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddAddressModal(
        clientId: widget.clientId,
        onSubmit: (clientId, data) async {
          if (requiresApproval) {
            final db = ref.read(powerSyncDatabaseProvider).value;
            if (db == null) throw Exception('Database not available');
            final approvalId = const Uuid().v4();
            await db.execute(
              'INSERT INTO approvals (id, type, status, client_id, user_id, role, reason, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
              [approvalId, 'address_add', 'pending', clientId, currentUser!.id, currentUser.role.apiValue, 'Add Address Request', jsonEncode(data)],
            );
            return Address(
              id: approvalId,
              clientId: clientId,
              psgcId: 0,
              label: AddressLabel.other,
              streetAddress: data['street_address'] as String? ?? '',
              isPrimary: data['is_primary'] as bool? ?? false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
          return await addressRepo.createAddress(clientId, data);
        },
      ),
    );

    if (result != null) {
      if (mounted) {
        final message = requiresApproval ? 'Address submitted for approval' : 'Address added';
        AppNotification.showSuccess(context, message);
      }
      _loadClient();
    }
  }

  Future<void> _viewPhoneNumbers() async {
    HapticUtils.lightImpact();
    final phoneRepo = ref.read(phoneNumberRepositoryProvider);

    // Load phone numbers from PowerSync
    final tablePhones = await phoneRepo.getPhoneNumbers(widget.clientId);

    // Include client's legacy phone field if not already represented
    final clientPhone = _client?.phone;
    final phoneNumbers = List<PhoneNumber>.from(tablePhones);
    if (clientPhone != null && clientPhone.isNotEmpty) {
      final alreadyListed = phoneNumbers.any((p) => p.number == clientPhone);
      if (!alreadyListed && _client != null) {
        phoneNumbers.add(PhoneNumber.fromLegacyField(_client!));
      }
    }

    if (!mounted) return;

    // Show phone numbers modal
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            AppBar(
              title: Text('Phone Numbers (${phoneNumbers.length})'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: phoneNumbers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.phone, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No phone numbers', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: phoneNumbers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final phone = phoneNumbers[index];
                        return _buildPhoneNumberListTile(phone, phoneRepo);
                      },
                    ),
            ),
          ],
        ),
      ),
    );

    // Reload client to refresh UI
    _loadClient();
  }

  Widget _buildPhoneNumberListTile(PhoneNumber phone, PhoneNumberRepository repo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: phone.isPrimary ? Colors.blue.shade300 : Colors.grey.shade300!,
          width: phone.isPrimary ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            phone.label == PhoneLabel.mobile
                ? LucideIcons.smartphone
                : phone.label == PhoneLabel.home
                    ? LucideIcons.phone
                    : LucideIcons.phoneCall,
            size: 20,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phone.displayNumber, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (phone.label != PhoneLabel.mobile)
                  Text(phone.label.displayName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          if (phone.isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: Colors.blue),
                  SizedBox(width: 4),
                  Text('Primary', style: TextStyle(fontSize: 11, color: Colors.blue)),
                ],
              ),
            ),
          if (!phone.isPrimary)
            IconButton(
              icon: const Icon(Icons.star, size: 18),
              onPressed: () async {
                await repo.setPrimary(phone.id);
                if (mounted) {
                  Navigator.pop(context);
                  _viewPhoneNumbers(); // Refresh
                }
              },
              tooltip: 'Set as Primary',
            ),
        ],
      ),
    );
  }

  Future<void> _addPhoneNumber() async {
    HapticUtils.lightImpact();
    final phoneRepo = ref.read(phoneNumberRepositoryProvider);
    final currentUser = ref.read(jwtAuthProvider).currentUser;
    final requiresApproval = currentUser?.role == UserRole.tele || currentUser?.role == UserRole.caravan;

    final result = await showModalBottomSheet<PhoneNumber>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddPhoneModal(
        clientId: widget.clientId,
        onSubmit: (clientId, data) async {
          if (requiresApproval) {
            final db = ref.read(powerSyncDatabaseProvider).value;
            if (db == null) throw Exception('Database not available');
            final approvalId = const Uuid().v4();
            await db.execute(
              'INSERT INTO approvals (id, type, status, client_id, user_id, role, reason, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
              [approvalId, 'phone_add', 'pending', clientId, currentUser!.id, currentUser.role.apiValue, 'Add Phone Number Request', jsonEncode(data)],
            );
            return PhoneNumber(
              id: approvalId,
              clientId: clientId,
              label: PhoneLabel.fromString(data['label'] as String? ?? 'mobile'),
              number: data['number'] as String? ?? '',
              isPrimary: data['is_primary'] as bool? ?? false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
          return await phoneRepo.createPhoneNumber(clientId, data);
        },
      ),
    );

    if (result != null) {
      _loadClient();
    }
  }

  Future<void> _handleLoanRelease() async {
    HapticUtils.lightImpact();

    // Navigate to unified Release Loan form
    final result = await context.push<bool>('/release-loan/${widget.clientId}');

    // If form was submitted successfully, reload client data
    if (result == true && mounted) {
      _loadClient();
    }
  }


  Future<void> _startTouchpoint() async {
    if (_client == null) return;

    // Prevent touchpoint creation for loan released clients
    if (_client!.loanReleased) {
      if (mounted) {
        HapticUtils.error();
        AppNotification.showError(context, 'Cannot create touchpoints: Loan has been released');
      }
      return;
    }

    HapticUtils.lightImpact();

    final nextType = _client!.nextTouchpointType;
    // Prefer backend-calculated nextTouchpointNumber; fall back to touchpoint_number
    // (next_touchpoint_number may be absent from Hive-cached API responses)
    final tp = _client!.touchpointNumber;
    final nextNumber = _client!.nextTouchpointNumber ?? (tp >= 1 && tp <= 7 ? tp : null);

    if (nextNumber == null) {
      // All touchpoints completed
      await _showTouchpointCompletionDialog();
      return;
    }

    if (nextType == null) {
      // Show completion dialog
      await _showTouchpointCompletionDialog();
      return;
    }

    // Validate the sequence before opening the form
    final validation = TouchpointValidationService.validateTouchpointSequence(
      touchpointNumber: nextNumber,
      touchpointType: nextType,
    );

    if (!validation.isValid) {
      _showValidationError(validation);
      return;
    }

    // RBAC: Check if user can create this touchpoint number based on their role
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.user?.role;

    // BUG FIX: Check BOTH touchpoint number AND type
    if (userRole == null ||
        !isValidTouchpointNumberForRole(nextNumber, userRole) ||
        (nextType != null && !isValidTouchpointTypeForRole(nextType, userRole))) {
      // User's role doesn't allow this touchpoint number or type
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => TouchpointValidationDialog(
            attemptedNumber: nextNumber,
            attemptedType: nextType,
            onConfirm: () => Navigator.of(context).pop(),
          ),
        );
      }
      return;
    }

    final result = await showTouchpointForm(
      context: context,
      clientId: widget.clientId,
      touchpointNumber: nextNumber,
      touchpointType: nextType == TouchpointType.visit ? 'Visit' : 'Call',
      clientName: _client!.fullName,
      address: _client!.addresses.isNotEmpty ? _client!.addresses.first.fullAddress : null,
    );

    if (result != null) {
      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Saving touchpoint...',
        operation: () async {
          // Reload client after touchpoint form submitted
          await _loadClient();
          ref.invalidate(clientTouchpointsProvider);

          // Check if this was the last touchpoint
          if (nextNumber == 7) {
            await _showTouchpointCompletionDialog();
          }
        },
        onError: (e) {
          if (mounted) {
            // Parse error and show using ErrorService
            final appError = ErrorService.parseError(e);
            if (appError != null) {
              ErrorService.showError(context, appError);
            } else {
              // Fallback to legacy error display
              AppNotification.showError(context, 'Failed to save touchpoint: $e');
            }
          }
        },
      );
    }
  }

  /// Open Record Touchpoint bottom sheet
  Future<void> _handleRecordTouchpoint() async {
    if (_client == null) return;

    // Prevent touchpoint creation for loan released clients
    if (_client!.loanReleased) {
      if (mounted) {
        HapticUtils.error();
        AppNotification.showError(context, 'Cannot create touchpoints: Loan has been released');
      }
      return;
    }

    HapticUtils.lightImpact();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => RecordTouchpointBottomSheet(
        client: _client!,
      ),
    );

    if (result == true && mounted) {
      await _loadClient();
      ref.invalidate(clientTouchpointsProvider);
    }
  }

  TouchpointStatus _parseTouchpointStatus(String status) {
    switch (status.toLowerCase()) {
      case 'interested':
        return TouchpointStatus.interested;
      case 'undecided':
        return TouchpointStatus.undecided;
      case 'not interested':
        return TouchpointStatus.notInterested;
      case 'completed':
        return TouchpointStatus.completed;
      default:
        return TouchpointStatus.interested;
    }
  }

  DateTime? _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    try {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  /// Open Record Visit Only bottom sheet
  Future<void> _handleRecordVisitOnly() async {
    if (_client == null) return;

    HapticUtils.lightImpact();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => RecordVisitBottomSheet(
        client: _client!,
      ),
    );

    if (result == true && mounted) {
      await _loadClient();
      ref.invalidate(clientTouchpointsProvider);
    }
  }

  /// Open Release Loan bottom sheet
  Future<void> _handleReleaseLoanBottomSheet() async {
    if (_client == null) return;

    HapticUtils.lightImpact();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => RecordLoanReleaseBottomSheet(
        client: _client!,
      ),
    );

    if (result == true && mounted) {
      await _loadClient();
      ref.invalidate(clientTouchpointsProvider);
    }
  }

  /// Show dialog when all 7 touchpoints are completed
  Future<void> _showTouchpointCompletionDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          LucideIcons.checkCircle,
          color: Colors.green[600],
          size: 48,
        ),
        title: const Text('All Touchpoints Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations! ${_client?.fullName ?? 'This client'} has completed all 7 touchpoints.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Touchpoint Sequence Completed:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...TouchpointValidationService.getSequenceDisplay().map((item) {
              return Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.check,
                      size: 14,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show validation error dialog
  void _showValidationError(validation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          LucideIcons.alertCircle,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('Invalid Touchpoint Sequence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(validation.error ?? 'Invalid touchpoint sequence'),
            const SizedBox(height: 16),
            const Text(
              'Expected Sequence:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...TouchpointValidationService.getSequenceDisplay().map((item) {
              return Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text('• $item'),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final client = _client!;
    final primaryAddress = client.addresses.isNotEmpty
        ? client.addresses.first
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and badges row
          Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    client.firstName.isNotEmpty
                        ? client.firstName[0].toUpperCase()
                        : client.lastName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Badges
                    Wrap(
                      spacing: 6,
                      children: [
                        _buildBadge(client.clientType.name, _getClientTypeColor(client.clientType)),
                        _buildBadge(client.productType.name, _getProductTypeColor(client.productType)),
                        if (client.isStarred)
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Birthday and created date
          Row(
            children: [
              Icon(LucideIcons.cake, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                client.birthDate != null
                    ? '${_formatDate(client.birthDate!)} (${client.age} years old)'
                    : 'No birthday',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 16),
              Icon(LucideIcons.calendar, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Created: ${_formatDate(client.createdAt!)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Touchpoint progress badge and location
          Row(
            children: [
              _buildTouchpointProgressBadge(),
              const SizedBox(width: 12),
              if (client.isStarred)
                const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              if (primaryAddress != null)
                Expanded(
                  child: Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${primaryAddress.municipality}, ${primaryAddress.province}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final client = _client!;
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.user?.role;
    final canRecordTouchpoint = client.touchpointStatus?.canCreateTouchpoint ?? true;
    final loanReleased = client.loanReleased;

    // Check role-based permissions for quick actions
    final canCreateVisit = userRole?.canCreateVisitTouchpoints ?? false;

    // Role must match the next touchpoint type:
    // caravan → Visit only (1, 4, 7); tele → Call only (2, 3, 5, 6); managers → any
    final nextType = client.nextTouchpointType;
    final roleCanRecordTouchpoint = userRole == null ? false
        : userRole.isManager ? true
        : userRole == UserRole.caravan ? nextType == TouchpointType.visit
        : userRole == UserRole.tele ? nextType == TouchpointType.call
        : false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Visit Only button — always enabled for caravan role
          Expanded(
            child: _buildActionButton(
              label: 'VISIT ONLY',
              color: Colors.blue[700]!,
              enabled: canCreateVisit,
              loanReleased: false,
              onPressed: () => _handleRecordVisitOnly(),
            ),
          ),
          const SizedBox(width: 12),
          // Touchpoint button — disabled by loan release, touchpoint business rules, or role mismatch
          Expanded(
            child: _buildActionButton(
              label: 'TOUCHPOINT',
              color: Colors.green[700]!,
              enabled: canRecordTouchpoint && !loanReleased && roleCanRecordTouchpoint,
              loanReleased: loanReleased,
              onPressed: () => _handleRecordTouchpoint(),
            ),
          ),
          const SizedBox(width: 12),
          // Release Loan button — always enabled for caravan role
          Expanded(
            child: ElevatedButton(
              onPressed: canCreateVisit ? () => _handleReleaseLoanBottomSheet() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canCreateVisit ? Colors.orange[700] : Colors.grey[300],
                foregroundColor: canCreateVisit ? Colors.white : Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('RELEASE LOAN'),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an action button that shows a red "Loan Released" badge when disabled due to loan release.
  Widget _buildActionButton({
    required String label,
    required Color color,
    required bool enabled,
    required bool loanReleased,
    required VoidCallback onPressed,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? color : Colors.grey[300],
              foregroundColor: enabled ? Colors.white : Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(label),
          ),
        ),
        if (loanReleased)
          Positioned(
            top: -8,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Text(
                'Loan Released',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadge(String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getClientTypeColor(ClientType type) {
    switch (type) {
      case ClientType.potential:
        return Colors.blue;
      case ClientType.existing:
        return Colors.green;
    }
  }

  Color _getProductTypeColor(ProductType type) {
    switch (type) {
      case ProductType.bfpActive:
        return Colors.red;
      case ProductType.bfpPension:
        return Colors.orange;
      case ProductType.pnpPension:
        return Colors.blue;
      case ProductType.napolcom:
        return Colors.purple;
      case ProductType.bfpStp:
        return Colors.teal;
    }
  }

  Widget _buildTouchpointProgressBadge() {
    final client = _client!;
    final completedCount = client.completedTouchpoints;
    final totalCount = 7;

    // Determine next touchpoint type
    final nextType = completedCount < totalCount
        ? (completedCount == 0 || completedCount == 3 || completedCount == 6
            ? 'Visit'
            : 'Call')
        : null;

    final badgeText = nextType != null
        ? '$completedCount/$totalCount • $nextType'
        : '$completedCount/$totalCount';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show skeleton loading while data is being fetched
    // Check this FIRST before checking if client is null to avoid "Client not found" flash
    if (_isLoading) {
      return _buildSkeletonLoading();
    }

    if (_client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.userX, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Client not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Client Details'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            tooltip: 'Edit Client',
            onPressed: () async {
              HapticUtils.lightImpact();
              if (mounted) {
                await _editClient();
              }
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash),
            tooltip: 'Delete Client',
            onPressed: () async {
              HapticUtils.lightImpact();
              if (mounted) {
                await _handleDelete();
              }
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.mapPin),
            tooltip: 'Navigate',
            onPressed: () async {
              HapticUtils.lightImpact();
              if (mounted) {
                await _navigateToClient();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Loan Released Sash
          if (_client!.loanReleased)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // Light red/pink background
                border: Border(
                  bottom: BorderSide(color: Colors.red.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.checkCircle,
                    size: 20,
                    color: const Color(0xFF16A34A), // Green checkmark
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loan Released',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFBE123C), // Dark red
                          ),
                        ),
                        Text(
                          'This client has completed their loan. No further touchpoints or edits allowed.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Card - Always visible basic info
                  _buildHeroCard(),

                  // Quick Actions - Visit, Touchpoint, Release Loan buttons
                  _buildQuickActions(),

                  // Expansion Panels
                  // 1. Client Information (44 fields in 8 subsections)
                  ClientInformationExpansionPanel(client: _client!),

                  // 2. Contact Information (Phone, Email, Addresses, Social Media)
                  ContactInformationExpansionPanel(
                    client: _client!,
                    onAddPhone: _addPhoneNumber,
                    onAddAddress: _addAddress,
                  ),

                  // 3. CMS Visit History
                  CmsVisitHistoryExpansionPanel(clientId: widget.clientId),

                  // 4. Touchpoint History (7-step sequence)
                  TouchpointHistoryExpansionPanel(
                    client: _client!,
                    touchpoints: _client!.touchpoints,
                  ),

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Quick Actions Section - Always visible at top with proper spacing
class _QuickActionsSection extends ConsumerWidget {
  final Address? primaryAddress;
  final bool isLoanReleased;
  final VoidCallback onNavigate;
  final VoidCallback onRecordTouchpoint;
  final VoidCallback onRecordVisitOnly;
  final VoidCallback onReleaseLoan;
  final VoidCallback onEdit;
  final Client? client; // NEW: Add client parameter for permission checks

  const _QuickActionsSection({
    required this.primaryAddress,
    required this.isLoanReleased,
    required this.onNavigate,
    required this.onRecordTouchpoint,
    required this.onRecordVisitOnly,
    required this.onReleaseLoan,
    required this.onEdit,
    this.client, // NEW
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.user?.role;
    final canReleaseLoan = userRole?.apiValue == 'admin' || userRole?.apiValue == 'caravan' || userRole?.apiValue == 'tele';

    // Use backend-provided can_create_touchpoint field (single source of truth)
    // Fallback to true for backward compatibility with cached data
    final canRecordTouchpoint = client?.touchpointStatus?.canCreateTouchpoint ?? true;

    // Role must match next touchpoint type
    final nextType = client?.nextTouchpointType;
    final roleCanRecordTouchpoint = userRole == null ? false
        : userRole.isManager ? true
        : userRole == UserRole.caravan ? nextType == TouchpointType.visit
        : userRole == UserRole.tele ? nextType == TouchpointType.call
        : false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickActionButton(
                icon: LucideIcons.mapPin,
                label: 'Navigate',
                onTap: onNavigate,
              ),
              _QuickActionButton(
                icon: LucideIcons.clipboardList,
                label: 'Record Touchpoint',
                onTap: (isLoanReleased || !canRecordTouchpoint || !roleCanRecordTouchpoint) ? null : onRecordTouchpoint,
                isPrimary: true,
              ),
              _QuickActionButton(
                icon: LucideIcons.userCheck,
                label: 'Record Visit',
                onTap: onRecordVisitOnly,
              ),
              if (canReleaseLoan)
                _QuickActionButton(
                  icon: LucideIcons.dollarSign,
                  label: 'Release Loan',
                  onTap: onReleaseLoan,
                  color: Colors.green[600],
                ),
              _QuickActionButton(
                icon: LucideIcons.pencil,
                label: 'Edit',
                onTap: isLoanReleased ? null : onEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick Action Button with proper spacing and touch targets
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final Color? color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: () {
        if (isDisabled) return;
        HapticUtils.lightImpact();
        onTap!();
      },
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 80,
          minHeight: 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[100]
              : (isPrimary ? const Color(0xFF0F172A) : (color ?? Colors.grey[100])),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? Colors.grey[200]!
                : (isPrimary ? const Color(0xFF0F172A) : (color ?? Colors.grey[300])!),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDisabled
                  ? Colors.grey[400]
                  : (isPrimary || color != null ? Colors.white : Colors.grey[700]),
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDisabled
                    ? Colors.grey[400]
                    : (isPrimary || color != null ? Colors.white : Colors.grey[700]),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Expandable Section with collapsible content
class _ExpandableSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final int itemCount;
  final Widget child;
  final bool initiallyExpanded;

  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.itemCount,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Section Header
          InkWell(
            onTap: () {
              HapticUtils.lightImpact();
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.itemCount}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable Content
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: widget.child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Skeleton stat card widget for loading state
class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton touchpoint item widget for loading state
class _TouchpointSkeletonItem extends StatelessWidget {
  const _TouchpointSkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 150,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TouchpointHistoryItem extends StatelessWidget {
  final Touchpoint touchpoint;

  const _TouchpointHistoryItem({required this.touchpoint});

  @override
  Widget build(BuildContext context) {
    final isVisit = touchpoint.type == TouchpointType.visit;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isVisit ? Colors.blue[50] : Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVisit ? LucideIcons.mapPin : LucideIcons.phone,
              color: isVisit ? Colors.blue : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${touchpoint.ordinal} ${touchpoint.type.name.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getReasonColor(touchpoint.reason).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatReason(touchpoint.reason),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getReasonColor(touchpoint.reason),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(touchpoint.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.grey),
        ],
      ),
    );
  }

  Color _getReasonColor(TouchpointReason reason) {
    switch (reason) {
      case TouchpointReason.interested:
        return Colors.green;
      case TouchpointReason.notInterested:
        return Colors.red;
      case TouchpointReason.undecided:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatReason(TouchpointReason reason) {
    return reason.name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}


