import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../services/api/client_api_service.dart';
import '../../../../services/api/approvals_api_service.dart';
import '../../../../services/auth/auth_service.dart';
import '../../../../services/touchpoint/touchpoint_validation_service.dart';
import '../../../../services/maps/map_service.dart';
import '../../../../services/error_service.dart';
import '../../../../shared/providers/app_providers.dart' show
    assignedClientsProvider,
    isOnlineProvider,
    touchpointApiServiceProvider,
    authNotifierProvider,
    powerSyncDatabaseProvider,
    addressRepositoryProvider,
    phoneNumberRepositoryProvider;
import '../../../../shared/utils/loading_helper.dart';
import '../../../../shared/widgets/permission_dialog.dart';
import '../../../../shared/widgets/touchpoint_validation_dialog.dart';
import '../../../../shared/widgets/map_widgets/client_map_view.dart';
import '../../../../shared/widgets/touchpoint_history_dialog.dart';
import '../../../../shared/utils/permission_helpers.dart';
import '../../../clients/data/models/client_model.dart' hide Address, PhoneNumber;
import '../../../clients/data/models/address_model.dart';
import '../../../clients/data/models/phone_number_model.dart';
import '../../../clients/data/repositories/address_repository.dart' show AddressRepository;
import '../../../clients/data/repositories/phone_number_repository.dart' show PhoneNumberRepository;
import '../../../clients/presentation/widgets/edit_client_form_v2.dart';
import '../../../clients/presentation/widgets/contact_info_section.dart';
import '../../../clients/presentation/widgets/add_address_modal.dart';
import '../../../clients/presentation/widgets/add_phone_modal.dart';
import '../../../clients/presentation/widgets/address_selection_modal.dart';
import '../../../touchpoints/presentation/widgets/touchpoint_form.dart';
import 'package:powersync/powersync.dart' hide Column;

// Client detail provider
final clientDetailProvider = FutureProvider.family<Client?, String>((ref, clientId) async {
  final clientApi = ref.watch(clientApiServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);

  if (isOnline) {
    try {
      return await clientApi.fetchClient(clientId);
    } catch (e) {
      // Fall back to local cache
      final hiveService = HiveService();
      if (!hiveService.isInitialized) await hiveService.init();
      final localClient = hiveService.getClient(clientId);
      if (localClient != null) {
        return Client.fromJson(localClient);
      }
      return null;
    }
  } else {
    // Offline - use local cache
    final hiveService = HiveService();
    if (!hiveService.isInitialized) await hiveService.init();
    final localClient = hiveService.getClient(clientId);
    if (localClient != null) {
      return Client.fromJson(localClient);
    }
    return null;
  }
});

// Touchpoints for client provider
final clientTouchpointsProvider = FutureProvider.family<List<Touchpoint>, String>((ref, clientId) async {
  final touchpointApi = ref.watch(touchpointApiServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);

  if (isOnline) {
    try {
      return await touchpointApi.fetchTouchpoints(clientId: clientId);
    } catch (e) {
      // Fall back to local cache
      final hiveService = HiveService();
      if (!hiveService.isInitialized) await hiveService.init();
      final localTouchpoints = hiveService.getTouchpointsForClient(clientId);
      return localTouchpoints.map((data) => Touchpoint.fromJson(data)).toList();
    }
  } else {
    // Offline - use local cache
    final hiveService = HiveService();
    if (!hiveService.isInitialized) await hiveService.init();
    final localTouchpoints = hiveService.getTouchpointsForClient(clientId);
    return localTouchpoints.map((data) => Touchpoint.fromJson(data)).toList();
  }
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
  final _hiveService = HiveService();

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
      if (!_hiveService.isInitialized) {
        await _hiveService.init();
      }

      // Try loading from Hive first
      var clientData = _hiveService.getClient(widget.clientId);
      Client? client;

      if (clientData != null) {
        try {
          client = Client.fromJson(clientData);
        } catch (e, stack) {
          debugPrint('Error parsing client data: $e\n$stack');
          // Continue to API fetch
        }
      }

      // If Hive doesn't have client or parsing failed, try fetching from API
      if (client == null) {
        final isOnline = ref.read(isOnlineProvider);
        if (isOnline) {
          try {
            final clientApi = ref.read(clientApiServiceProvider);
            client = await clientApi.fetchClient(widget.clientId);
          } catch (e, stack) {
            debugPrint('Error fetching client from API: $e\n$stack');
            // Continue to error state
          }
        }
      }

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

      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Deleting client...',
        operation: () async {
          await _hiveService.deleteClient(widget.clientId);
          // PowerSync handles sync automatically via the repository
          ref.invalidate(assignedClientsProvider);
        },
        onError: (e) {
          if (mounted) {
            AppNotification.showError(context, 'Failed to delete client: $e');
          }
        },
      );

      if (mounted) {
        AppNotification.showSuccess(context, 'Client deleted');
        context.pop();
      }
    }
  }

  Future<void> _editClient() async {
    HapticUtils.lightImpact();

    // Show edit form as a full-page modal with the client data preloaded
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Edit Client'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete Client',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Client'),
                      content: const Text('Are you sure you want to delete this client?'),
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
                  if (confirmed == true && context.mounted) {
                    // Handle delete
                    final clientApi = ref.read(clientApiServiceProvider);
                    try {
                      await clientApi.deleteClient(widget.clientId);
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Close edit form
                        context.pop(); // Close client detail
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppNotification.showError(context, 'Failed to delete client: $e');
                      }
                    }
                  }
                },
              ),
            ],
          ),
          body: EditClientFormV2(
            clientId: widget.clientId,
            initialClient: _client, // Pass the already-loaded client data
            onSave: (savedClient) {
              Navigator.of(context).pop(true); // Close edit form
              return true;
            },
          ),
        ),
      ),
    );

    // Reload client data after edit if changes were made
    if (result == true) {
      _loadClient();
      ref.invalidate(assignedClientsProvider);
    }
  }

  Future<void> _viewAddresses() async {
    HapticUtils.lightImpact();
    final addressRepo = ref.read(addressRepositoryProvider);

    // Load addresses from PowerSync
    final addresses = await addressRepo.getAddresses(widget.clientId);

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

    final result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddAddressModal(
        clientId: widget.clientId,
        onSubmit: (clientId, data) async {
          return await addressRepo.createAddress(clientId, data);
        },
      ),
    );

    if (result != null) {
      if (mounted) {
        AppNotification.showSuccess(context, 'Address added');
      }
      _loadClient();
    }
  }

  Future<void> _viewPhoneNumbers() async {
    HapticUtils.lightImpact();
    final phoneRepo = ref.read(phoneNumberRepositoryProvider);

    // Load phone numbers from PowerSync
    final phoneNumbers = await phoneRepo.getPhoneNumbers(widget.clientId);

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

    final result = await showModalBottomSheet<PhoneNumber>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddPhoneModal(
        clientId: widget.clientId,
        onSubmit: (clientId, data) async {
          return await phoneRepo.createPhoneNumber(clientId, data);
        },
      ),
    );

    if (result != null) {
      if (mounted) {
        AppNotification.showSuccess(context, 'Phone number added');
      }
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

  void _callClient(String? phone) {
    if (phone == null || phone.isEmpty) {
      AppNotification.showError(context, 'No phone number available');
      return;
    }
    HapticUtils.lightImpact();
    // Stub implementation - TODO: Integrate with actual phone call functionality
    LoadingHelper.withLoading(
      ref: ref,
      message: 'Initiating call...',
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          AppNotification.showNeutral(context, 'Calling $phone...');
        }
      },
    );
  }

  void _navigateToAddress(String? address) {
    if (address == null || address.isEmpty) {
      AppNotification.showError(context, 'No address available');
      return;
    }
    HapticUtils.lightImpact();

    // Show navigation options
    final primaryAddress = _client!.addresses.isNotEmpty
        ? _client!.addresses.first
        : null;

    if (primaryAddress?.latitude != null && primaryAddress?.longitude != null) {
      // Open Google Maps directly with coordinates
      _openGoogleMapsNavigation(primaryAddress!);
    } else {
      // If no coordinates, search by address string
      _openGoogleMapsSearch(address);
    }
  }

  Future<void> _openGoogleMapsNavigation(Address address) async {
    final latitude = address.latitude;
    final longitude = address.longitude;
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Could not open Google Maps: $e');
      }
    }
  }

  Future<void> _openGoogleMapsSearch(String address) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Could not open Google Maps: $e');
      }
    }
  }

  void _showMapForAddress(Address address) {
    if (address.latitude == null || address.longitude == null) {
      AppNotification.showError(context, 'Location coordinates not available');
      return;
    }

    HapticUtils.lightImpact();
    showModalBottomSheet(
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
              title: Text(address.fullAddress),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: ClientMapView(
                clients: [_client!],
                showControls: true,
                showSearch: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNavigation(Address address) async {
    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Opening navigation...',
      operation: () async {
        // Import and use MapService
        final mapService = MapService();
        await mapService.openGoogleMapsNavigation(
          latitude: address.latitude!,
          longitude: address.longitude!,
          label: _client!.fullName,
        );
      },
      onError: (e) {
        if (mounted) {
          AppNotification.showError(context, 'Failed to open navigation: $e');
        }
      },
    );
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
    final nextNumber = _client!.completedTouchpoints + 1;

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

    if (userRole == null || !isValidTouchpointNumberForRole(nextNumber, userRole)) {
      // User's role doesn't allow this touchpoint number
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
          // Save touchpoint
          final touchpointId = DateTime.now().millisecondsSinceEpoch.toString();
          final touchpointData = Map<String, dynamic>.from({
            'id': touchpointId,
            'clientId': widget.clientId,
            'touchpointNumber': nextNumber,
            'type': nextType.name,
            'date': DateTime.now().toIso8601String(),
            ...result,
            'createdAt': DateTime.now().toIso8601String(),
          });

          await _hiveService.saveTouchpoint(touchpointId, touchpointData);
          // PowerSync handles sync automatically via the repository

          // Reload client
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

    // TODO: Phase 1 - Implement new compact Record Touchpoint bottom sheet
    if (mounted) {
      HapticUtils.error();
      AppNotification.showError(context, 'Record Touchpoint - Coming soon in Phase 1');
    }
  }

  /// Open Record Visit Only bottom sheet
  Future<void> _handleRecordVisitOnly() async {
    if (_client == null) return;

    // Prevent visit only for loan released clients
    if (_client!.loanReleased) {
      if (mounted) {
        HapticUtils.error();
        AppNotification.showError(context, 'Cannot create visit: Loan has been released');
      }
      return;
    }

    HapticUtils.lightImpact();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => _RecordVisitOnlyBottomSheet(
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

    // Prevent release loan if already released
    if (_client!.loanReleased) {
      if (mounted) {
        HapticUtils.error();
        AppNotification.showWarning(context, 'Loan has already been released');
      }
      return;
    }

    HapticUtils.lightImpact();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => _ReleaseLoanBottomSheet(
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

    final primaryAddress = _client!.addresses.isNotEmpty
        ? _client!.addresses.first
        : null;
    final primaryPhone = _client!.phoneNumbers.isNotEmpty
        ? _client!.phoneNumbers.first.number
        : null;

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
            tooltip: 'View History',
            onPressed: () async {
              HapticUtils.lightImpact();
              if (mounted) {
                await TouchpointHistoryDialog.show(
                  context,
                  clientId: widget.clientId,
                  clientName: _client?.fullName ?? 'Client',
                );
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
                  // Client header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _client!.fullName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_client!.loanReleased) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Text(
                                  'RELEASED',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_client!.clientType.name.toUpperCase()} Client',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Touchpoint indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_client!.completedTouchpoints}/7 Touchpoints',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // View History button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticUtils.lightImpact();
                    if (mounted) {
                      await TouchpointHistoryDialog.show(
                        context,
                        clientId: widget.clientId,
                        clientName: _client?.fullName ?? 'Client',
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.history, size: 18),
                  label: const Text('View Touchpoint History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

            // Quick Actions Section (always visible at top)
            _QuickActionsSection(
              primaryAddress: primaryAddress,
              isLoanReleased: _client!.loanReleased,
              onNavigate: () => _navigateToAddress(primaryAddress?.fullAddress),
              onRecordTouchpoint: _handleRecordTouchpoint,
              onRecordVisitOnly: _handleRecordVisitOnly,
              onReleaseLoan: _handleReleaseLoanBottomSheet,
              onEdit: _editClient,
            ),

            // Expandable Sections
            // Personal Information
            _ExpandableSection(
              title: 'Personal Information',
              icon: LucideIcons.user,
              itemCount: _getPersonalInfoCount(),
              child: Column(
                children: [
                  if (_client!.birthDate != null)
                    _InfoRow(
                      icon: LucideIcons.cake,
                      label: 'Birthday',
                      value: _formatDate(_client!.birthDate!),
                    ),
                  if (_client!.age > 0)
                    _InfoRow(
                      icon: LucideIcons.user,
                      label: 'Age',
                      value: '${_client!.age} years old',
                    ),
                  if (_client!.agencyName != null)
                    _InfoRow(
                      icon: LucideIcons.building,
                      label: 'Agency',
                      value: _client!.agencyName!,
                    ),
                  if (_client!.department != null)
                    _InfoRow(
                      icon: LucideIcons.briefcase,
                      label: 'Department',
                      value: _client!.department!,
                    ),
                  if (_client!.position != null)
                    _InfoRow(
                      icon: LucideIcons.award,
                      label: 'Position',
                      value: _client!.position!,
                    ),
                ],
              ),
            ),

            // Contact Information (Addresses & Phone Numbers)
            _ExpandableSection(
              title: 'Contact Information',
              icon: LucideIcons.phone,
              itemCount: _client!.addresses.length + _client!.phoneNumbers.length,
              child: ContactInfoSection(
                client: _client!,
                onViewAddresses: _viewAddresses,
                onViewPhoneNumbers: _viewPhoneNumbers,
                onAddAddress: _addAddress,
                onAddPhoneNumber: _addPhoneNumber,
              ),
            ),

            // Map Preview (always visible if coordinates exist)
            if (_client!.addresses.any((a) => a.latitude != null && a.longitude != null))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.map, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 180,
                        child: ClientMapView(
                          clients: [_client!],
                          showControls: false,
                          showSearch: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Other Contact Information (email, Facebook)
            if (_client!.email != null || _client!.facebookLink != null)
              _ExpandableSection(
                title: 'Other Contact',
                icon: LucideIcons.share2,
                itemCount: (_client!.email != null ? 1 : 0) + (_client!.facebookLink != null ? 1 : 0),
                child: Column(
                  children: [
                    if (_client!.email != null)
                      _InfoRow(
                        icon: LucideIcons.mail,
                        label: 'Email',
                        value: _client!.email!,
                      ),
                    if (_client!.facebookLink != null)
                      _InfoRow(
                        icon: LucideIcons.facebook,
                        label: 'Facebook',
                        value: _client!.facebookLink!,
                      ),
                  ],
                ),
              ),

            // Pension Information
            _ExpandableSection(
              title: 'Pension Information',
              icon: LucideIcons.creditCard,
              itemCount: _getPensionInfoCount(),
              child: Column(
                children: [
                  _InfoRow(
                    icon: LucideIcons.creditCard,
                    label: 'Product Type',
                    value: _getProductTypeLabel(_client!.productType),
                  ),
                  _InfoRow(
                    icon: LucideIcons.wallet,
                    label: 'Pension Type',
                    value: _client!.pensionType.name.toUpperCase(),
                  ),
                  if (_client!.marketType != null)
                    _InfoRow(
                      icon: LucideIcons.building2,
                      label: 'Market Type',
                      value: _getMarketTypeLabel(_client!.marketType!),
                    ),
                  if (_client!.payrollDate != null)
                    _InfoRow(
                      icon: LucideIcons.calendar,
                      label: 'Payroll Date',
                      value: _client!.payrollDate!,
                    ),
                ],
              ),
            ),

            // Visit History
            _ExpandableSection(
              title: 'Visit History',
              icon: LucideIcons.history,
              itemCount: _client!.touchpoints.length,
              initiallyExpanded: _client!.touchpoints.isNotEmpty,
              child: _client!.touchpoints.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No touchpoints yet',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < _client!.touchpoints.length; i++)
                          _TouchpointHistoryItem(touchpoint: _client!.touchpoints[i]),
                      ],
                    ),
            ),

            // Remarks
            if (_client!.remarks != null && _client!.remarks!.isNotEmpty)
              _ExpandableSection(
                title: 'Remarks',
                icon: LucideIcons.messageSquare,
                itemCount: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(_client!.remarks!),
                ),
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

  String _getProductTypeLabel(ProductType type) {
    switch (type) {
      case ProductType.bfpActive:
        return 'BFP ACTIVE';
      case ProductType.bfpPension:
        return 'BFP PENSION';
      case ProductType.pnpPension:
        return 'PNP PENSION';
      case ProductType.napolcom:
        return 'NAPOLCOM';
      case ProductType.bfpStp:
        return 'BFP STP';
    }
  }

  String _getMarketTypeLabel(MarketType type) {
    switch (type) {
      case MarketType.residential:
        return 'Residential';
      case MarketType.commercial:
        return 'Commercial';
      case MarketType.industrial:
        return 'Industrial';
    }
  }

  int _getPersonalInfoCount() {
    int count = 0;
    if (_client!.birthDate != null) count++;
    if (_client!.age > 0) count++;
    if (_client!.agencyName != null) count++;
    if (_client!.department != null) count++;
    if (_client!.position != null) count++;
    return count;
  }

  int _getPensionInfoCount() {
    int count = 2; // Product type and Pension type always present
    if (_client!.marketType != null) count++;
    if (_client!.payrollDate != null) count++;
    return count;
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

  const _QuickActionsSection({
    required this.primaryAddress,
    required this.isLoanReleased,
    required this.onNavigate,
    required this.onRecordTouchpoint,
    required this.onRecordVisitOnly,
    required this.onReleaseLoan,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.user?.role?.apiValue;
    final canReleaseLoan = userRole == 'admin' || userRole == 'caravan' || userRole == 'tele';

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
                onTap: isLoanReleased ? null : onRecordTouchpoint,
                isPrimary: true,
              ),
              _QuickActionButton(
                icon: LucideIcons.userCheck,
                label: 'Record Visit',
                onTap: isLoanReleased ? null : onRecordVisitOnly,
              ),
              if (canReleaseLoan && !isLoanReleased)
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


