import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../services/sync/sync_service.dart';
import '../../../../services/api/client_api_service.dart';
import '../../../../services/api/touchpoint_api_service.dart';
import '../../../../services/api/approvals_api_service.dart';
import '../../../../services/auth/auth_service.dart';
import '../../../../services/touchpoint/touchpoint_validation_service.dart';
import '../../../../services/connectivity_service.dart';
import '../../../../services/maps/map_service.dart';
import '../../../../services/error_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../../../shared/widgets/permission_widgets.dart';
import '../../../../shared/widgets/permission_dialog.dart';
import '../../../../shared/widgets/map_widgets/client_map_view.dart';
import '../../../../shared/utils/permission_helpers.dart';
import '../../../clients/data/models/client_model.dart';
import '../../../../core/models/user_role.dart';
import '../../../touchpoints/presentation/widgets/touchpoint_form.dart';

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
    _loadClient();
  }

  Future<void> _loadClient() async {
    try {
      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Loading client...',
        operation: () async {
          if (!_hiveService.isInitialized) {
            await _hiveService.init();
          }

          final clientData = _hiveService.getClient(widget.clientId);
          if (clientData != null && mounted) {
            try {
              setState(() {
                _client = Client.fromJson(clientData);
                _isLoading = false;
              });
            } catch (e, stack) {
              debugPrint('Error parsing client data: $e\n$stack');
              if (mounted) {
                setState(() => _isLoading = false);
                _showErrorDialog('Failed to load client', e);
              }
            }
          } else {
            if (mounted) {
              setState(() => _isLoading = false);
              _showNotFoundError();
            }
          }
        },
      );
    } catch (e, stack) {
      debugPrint('Error in _loadClient: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to load client', e);
      }
    }
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
          ref.invalidate(clientsProvider);
        },
        onError: (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete client: $e')),
            );
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client deleted')),
        );
        context.pop();
      }
    }
  }

  void _editClient() {
    HapticUtils.lightImpact();
    context.push('/clients/${widget.clientId}/edit').then((_) {
      // Reload client data after edit
      _loadClient();
      ref.invalidate(clientsProvider);
    });
  }

  Future<void> _handleLoanRelease() async {
    HapticUtils.lightImpact();

    // Show UDI input dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ReleaseLoanDialog(clientName: _client?.fullName ?? 'this client'),
    );

    if (result == null || !result['confirmed']) return;

    final udiNumber = result['udi_number'] as String?;
    final notes = result['notes'] as String?;

    if (udiNumber == null || udiNumber.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UDI number is required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Submitting loan release...',
        operation: () async {
          final approvalsApi = ref.read(approvalsApiServiceProvider);
          await approvalsApi.submitLoanRelease(
            clientId: widget.clientId,
            udiNumber: udiNumber.trim(),
            notes: (notes?.trim().isNotEmpty ?? false) ? notes!.trim() : 'Loan release requested via mobile app',
          );
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loan release submitted for approval (UDI: ${udiNumber.trim()})'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload client to show updated loan status
        _loadClient();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit loan release: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _callClient(String? phone) {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Calling $phone...')),
          );
        }
      },
    );
  }

  void _navigateToAddress(String? address) {
    if (address == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No address available')),
      );
      return;
    }
    HapticUtils.lightImpact();

    // Show navigation options
    final primaryAddress = _client!.addresses.isNotEmpty
        ? _client!.addresses.first
        : null;

    if (primaryAddress?.latitude != null && primaryAddress?.longitude != null) {
      // Use map service for navigation
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose Navigation App',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Google Maps'),
                onTap: () {
                  Navigator.pop(context);
                  _openNavigation(primaryAddress!);
                },
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigating to $address...')),
      );
    }
  }

  void _showMapForAddress(Address address) {
    if (address.latitude == null || address.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location coordinates not available')),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open navigation: $e')),
          );
        }
      },
    );
  }

  Future<void> _startTouchpoint() async {
    if (_client == null) return;

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
        PermissionDeniedDialog.show(context);
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save touchpoint: $e')),
              );
            }
          }
        },
      );
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
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
          // Loan release button - only for Caravan and Tele users
          Consumer(
            builder: (context, ref, _) {
              final authState = ref.watch(authNotifierProvider);
              final userRole = authState.user?.role?.apiValue;

              // Show loan release button for Admin, Caravan and Tele
              if (userRole == 'admin' || userRole == 'caravan' || userRole == 'tele') {
                return IconButton(
                  icon: const Icon(LucideIcons.dollarSign),
                  tooltip: 'Release Loan',
                  onPressed: _handleLoanRelease,
                );
              }

              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            onPressed: _editClient,
          ),
          PermissionDeleter(
            resource: 'clients',
            child: IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.red),
              onPressed: _handleDelete,
            ),
            fallback: IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.red),
              onPressed: () {
                PermissionDeniedDialog.show(context);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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

            // Quick actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: LucideIcons.phone,
                      label: 'Call',
                      onTap: () => _callClient(primaryPhone),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      icon: LucideIcons.mapPin,
                      label: 'Navigate',
                      onTap: () => _navigateToAddress(primaryAddress?.fullAddress),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      icon: LucideIcons.plusCircle,
                      label: 'New Visit',
                      onTap: _startTouchpoint,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ),

            // Personal Info Section
            _Section(title: 'Personal Information'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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

            // Contact Section
            _Section(title: 'Contact Information'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ..._client!.phoneNumbers.map((phone) => _InfoRow(
                        icon: LucideIcons.phone,
                        label: phone.label ?? 'Phone',
                        value: phone.number,
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.phoneCall, size: 18),
                          onPressed: () => _callClient(phone.number),
                        ),
                      )),
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

            // Address Section
            if (_client!.addresses.isNotEmpty) ...[
              _Section(title: 'Addresses'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: _client!.addresses.map((address) => _InfoRow(
                        icon: LucideIcons.mapPin,
                        label: address.isPrimary ? 'Primary' : 'Address',
                        value: address.fullAddress,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (address.latitude != null && address.longitude != null)
                              IconButton(
                                icon: const Icon(LucideIcons.map, size: 18),
                                onPressed: () => _showMapForAddress(address),
                              ),
                            IconButton(
                              icon: const Icon(LucideIcons.navigation, size: 18),
                              onPressed: () => _navigateToAddress(address.fullAddress),
                            ),
                          ],
                        ),
                      )).toList(),
                ),
              ),

              // Map view for client location
              if (_client!.addresses.any((a) => a.latitude != null && a.longitude != null))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    height: 200,
                    child: ClientMapView(
                      clients: [_client!],
                      showControls: false,
                      showSearch: false,
                    ),
                  ),
                ),
            ],

            // Pension Info Section
            _Section(title: 'Pension Information'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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

            // Visit History Section
            _Section(title: 'Visit History'),
            if (_client!.touchpoints.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No touchpoints yet',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _client!.touchpoints.length,
                itemBuilder: (context, index) {
                  final touchpoint = _client!.touchpoints[index];
                  return _TouchpointHistoryItem(touchpoint: touchpoint);
                },
              ),

            // Remarks Section
            if (_client!.remarks != null && _client!.remarks!.isNotEmpty) ...[
              _Section(title: 'Remarks'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_client!.remarks!),
              ),
            ],

            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getProductTypeLabel(ProductType type) {
    switch (type) {
      case ProductType.sssPensioner:
        return 'SSS Pensioner';
      case ProductType.gsisPensioner:
        return 'GSIS Pensioner';
      case ProductType.private:
        return 'Private';
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? Theme.of(context).colorScheme.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isPrimary ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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

/// Dialog for Release Loan with UDI number input
class _ReleaseLoanDialog extends StatefulWidget {
  final String clientName;

  const _ReleaseLoanDialog({required this.clientName});

  @override
  State<_ReleaseLoanDialog> createState() => _ReleaseLoanDialogState();
}

class _ReleaseLoanDialogState extends State<_ReleaseLoanDialog> {
  final _udiController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _udiController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        LucideIcons.dollarSign,
        color: Colors.green[600],
        size: 48,
      ),
      title: const Text('Release Loan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submit loan release request for ${widget.clientName}?',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _udiController,
            decoration: const InputDecoration(
              labelText: 'UDI Number *',
              hintText: 'Enter UDI number...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Enter notes (optional)...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          Text(
            'This will submit a request for approval. The loan will be marked as released and all touchpoints will be completed.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final udiNumber = _udiController.text.trim();
            if (udiNumber.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('UDI number is required'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context, {
              'confirmed': true,
              'udi_number': udiNumber,
              'notes': _notesController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit Request'),
        ),
      ],
    );
  }
}
