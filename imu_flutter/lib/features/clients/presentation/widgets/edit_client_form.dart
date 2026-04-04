import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/client_model.dart';

/// Reusable Edit Client Form Widget
///
/// Can be used as:
/// 1. Standalone page (EditClientPage)
/// 2. Modal dialog (from other screens)
/// 3. Embedded in other views
///
/// Features:
/// - Pre-loads client values from API or local storage
/// - Categorized sections for better UX
/// - Online/offline support
/// - Approval workflow for caravan/tele users
/// - Comprehensive validation
class EditClientForm extends ConsumerStatefulWidget {
  final String clientId;
  final Client? initialClient;
  final Function(Client)? onSave;
  final bool isModal;
  final VoidCallback? onCancel;

  const EditClientForm({
    super.key,
    required this.clientId,
    this.initialClient,
    this.onSave,
    this.isModal = false,
    this.onCancel,
  });

  @override
  ConsumerState<EditClientForm> createState() => _EditClientFormState();
}

class _EditClientFormState extends ConsumerState<EditClientForm> {
  final _formKey = GlobalKey<FormState>();
  final _hiveService = HiveService();
  final _scrollController = ScrollController();

  // Loading states
  bool _isLoading = true;
  bool _isSaving = false;

  // Client data
  Client? _client;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _facebookController = TextEditingController();
  final _remarksController = TextEditingController();

  // Dropdown values
  String _productType = 'SSS Pensioner';
  String _pensionType = 'SSS';
  String _marketType = 'Residential';
  String _clientType = 'POTENTIAL';

  // Lists
  final List<Address> _addresses = [];
  final List<PhoneNumber> _phoneNumbers = [];

  // Section expansion states
  final Map<String, bool> _expandedSections = {
    'basic': true,
    'contact': true,
    'product': true,
    'address': false,
    'phone': false,
    'remarks': false,
  };

  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClient();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _facebookController.dispose();
    _remarksController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    setState(() => _isLoading = true);

    try {
      // Use initialClient if provided, otherwise fetch
      if (widget.initialClient != null) {
        _client = widget.initialClient;
      } else {
        if (!_hiveService.isInitialized) {
          await _hiveService.init();
        }

        // Try local storage first (offline support)
        final clientData = _hiveService.getClient(widget.clientId);
        if (clientData != null) {
          try {
            _client = Client.fromRow(clientData);
          } catch (e) {
            debugPrint('[EditClientForm] fromRow failed, trying fromJson: $e');
            _client = Client.fromJson(clientData);
          }
        }

        // If online and no local data, fetch from API
        final isOnline = ref.read(isOnlineProvider);
        if (_client == null && isOnline) {
          final clientApi = ref.read(clientApiServiceProvider);
          _client = await clientApi.fetchClient(widget.clientId);
        }
      }

      if (_client != null && mounted) {
        _populateForm();
        setState(() => _isLoading = false);
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showNotFoundError();
        }
      }
    } catch (e, stack) {
      debugPrint('[EditClientForm] Error loading client: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to load client', e);
      }
    }
  }

  void _populateForm() {
    if (_client == null) return;

    setState(() {
      // Populate text fields
      _firstNameController.text = _client!.firstName;
      _middleNameController.text = _client!.middleName ?? '';
      _lastNameController.text = _client!.lastName;
      _emailController.text = _client!.email ?? '';
      _facebookController.text = _client!.facebookLink ?? '';
      _remarksController.text = _client!.remarks ?? '';

      // Populate dropdowns
      _productType = _getProductTypeLabel(_client!.productType);
      _pensionType = _getPensionTypeLabel(_client!.pensionType);
      _marketType = _client!.marketType != null
          ? _getMarketTypeLabel(_client!.marketType!)
          : 'Residential';
      _clientType = _client!.clientType.name.toUpperCase();

      // Populate lists
      _addresses.clear();
      _addresses.addAll(_client!.addresses);
      if (_addresses.isEmpty) {
        _addresses.add(Address(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          street: '',
          barangay: '',
          city: '',
          province: '',
          isPrimary: true,
        ),);
      }

      _phoneNumbers.clear();
      _phoneNumbers.addAll(_client!.phoneNumbers);
      if (_phoneNumbers.isEmpty) {
        _phoneNumbers.add(PhoneNumber(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          number: '',
          label: 'Mobile',
          isPrimary: true,
        ),);
      }
    });
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

  String _getPensionTypeLabel(PensionType type) {
    switch (type) {
      case PensionType.sss:
        return 'SSS';
      case PensionType.gsis:
        return 'GSIS';
      case PensionType.private:
        return 'Private';
      case PensionType.none:
        return 'None';
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      HapticUtils.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fix the errors before saving'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    HapticUtils.mediumImpact();

    setState(() => _isSaving = true);

    try {
      // Build updated client object
      final updatedClient = Client(
        id: widget.clientId,
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty
            ? null
            : _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        facebookLink: _facebookController.text.trim().isEmpty
            ? null
            : _facebookController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        productType: _parseProductType(_productType),
        pensionType: _parsePensionType(_pensionType),
        marketType: _parseMarketType(_marketType),
        clientType: _parseClientType(_clientType),
        addresses: List.from(_addresses),
        phoneNumbers: List.from(_phoneNumbers),
        createdAt: _client?.createdAt,
        updatedAt: DateTime.now(),
      );

      debugPrint('[EditClientForm] Submitting client edit: ${widget.clientId}');

      // Check connectivity
      final isOnline = ref.read(isOnlineProvider);

      if (isOnline) {
        // Send to backend for approval
        debugPrint('[EditClientForm] Online - submitting to backend API');
        final clientApi = ref.read(clientApiServiceProvider);
        final result = await clientApi.updateClient(updatedClient);

        if (result != null) {
          debugPrint('[EditClientForm] Client edit submitted successfully');
          // Update local storage with the response
          await _hiveService.saveClient(widget.clientId, result.toJson());

          // Call onSave callback if provided
          if (widget.onSave != null) {
            widget.onSave!(result);
          }

          if (mounted) {
            _showSuccessSnackBar('Client edit submitted for approval');
            if (widget.isModal) {
              Navigator.of(context).pop(true);
            }
          }
        } else {
          throw Exception('Failed to submit client edit - client not found');
        }
      } else {
        // Offline - save to local storage only
        debugPrint('[EditClientForm] Offline - saving to local storage only');
        await _hiveService.saveClient(widget.clientId, updatedClient.toJson());

        // Call onSave callback if provided
        if (widget.onSave != null) {
          widget.onSave!(updatedClient);
        }

        if (mounted) {
          _showWarningSnackBar('Offline: Changes will sync when connected');
          if (widget.isModal) {
            Navigator.of(context).pop(true);
          }
        }
      }
    } catch (e, stack) {
      debugPrint('[EditClientForm] Error: $e\n$stack');
      HapticUtils.error();
      if (mounted) {
        _showErrorSnackBar('Failed to submit client edit: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  ProductType _parseProductType(String value) {
    switch (value) {
      case 'SSS Pensioner':
        return ProductType.sssPensioner;
      case 'GSIS Pensioner':
        return ProductType.gsisPensioner;
      case 'Private':
        return ProductType.private;
      default:
        return ProductType.sssPensioner;
    }
  }

  PensionType _parsePensionType(String value) {
    switch (value) {
      case 'SSS':
        return PensionType.sss;
      case 'GSIS':
        return PensionType.gsis;
      case 'Private':
        return PensionType.private;
      case 'None':
        return PensionType.none;
      default:
        return PensionType.sss;
    }
  }

  MarketType _parseMarketType(String value) {
    switch (value) {
      case 'Residential':
        return MarketType.residential;
      case 'Commercial':
        return MarketType.commercial;
      case 'Industrial':
        return MarketType.industrial;
      default:
        return MarketType.residential;
    }
  }

  ClientType _parseClientType(String value) {
    switch (value.toLowerCase()) {
      case 'potential':
        return ClientType.potential;
      case 'existing':
        return ClientType.existing;
      default:
        return ClientType.potential;
    }
  }

  void _toggleSection(String section) {
    HapticUtils.lightImpact();
    setState(() {
      _expandedSections[section] = !_expandedSections[section]!;
    });
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
              if (widget.onCancel != null) widget.onCancel!();
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
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar:
            widget.isModal ? null : AppBar(title: const Text('Edit Client')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading client...'),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isModal
          ? null
          : AppBar(
              title: const Text('Edit Client'),
              actions: [
                if (_client?.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Chip(
                        label: Text(
                          'ID: ${widget.clientId.substring(0, 8)}...',
                          style: TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  ),
              ],
            ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Section
            _buildSectionHeader(
              title: 'Basic Information',
              icon: LucideIcons.user,
              sectionKey: 'basic',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildBasicInfoSection(colorScheme),

            const SizedBox(height: 24),

            // Contact Details Section
            _buildSectionHeader(
              title: 'Contact Details',
              icon: LucideIcons.phone,
              sectionKey: 'contact',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildContactDetailsSection(colorScheme),

            const SizedBox(height: 24),

            // Product Information Section
            _buildSectionHeader(
              title: 'Product Information',
              icon: LucideIcons.creditCard,
              sectionKey: 'product',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildProductInfoSection(colorScheme),

            const SizedBox(height: 24),

            // Address Section
            _buildSectionHeader(
              title: 'Address',
              icon: LucideIcons.mapPin,
              sectionKey: 'address',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildAddressSection(colorScheme),

            const SizedBox(height: 24),

            // Phone Numbers Section
            _buildSectionHeader(
              title: 'Phone Numbers',
              icon: LucideIcons.phone,
              sectionKey: 'phone',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildPhoneNumbersSection(colorScheme),

            const SizedBox(height: 24),

            // Remarks Section
            _buildSectionHeader(
              title: 'Remarks',
              icon: LucideIcons.messageSquare,
              sectionKey: 'remarks',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildRemarksSection(colorScheme),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            if (widget.isModal) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required String sectionKey,
    required Color color,
  }) {
    final isExpanded = _expandedSections[sectionKey]!;
    return InkWell(
      onTap: () => _toggleSection(sectionKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(ColorScheme colorScheme) {
    if (!_expandedSections['basic']!) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name fields
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _middleNameController,
                decoration: const InputDecoration(
                  labelText: 'Middle Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Client Type
        const Text(
          'Client Type',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ClientTypeButton(
                label: 'Potential',
                isSelected: _clientType == 'POTENTIAL',
                colorScheme: colorScheme,
                onTap: () {
                  HapticUtils.selectionClick();
                  setState(() => _clientType = 'POTENTIAL');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ClientTypeButton(
                label: 'Existing',
                isSelected: _clientType == 'EXISTING',
                colorScheme: colorScheme,
                onTap: () {
                  HapticUtils.selectionClick();
                  setState(() => _clientType = 'EXISTING');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactDetailsSection(ColorScheme colorScheme) {
    if (!_expandedSections['contact']!) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Contact (from phoneNumbers list)
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Primary Contact',
            hintText: '+63 912 345 6789',
            prefixIcon: const Icon(LucideIcons.phone),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType: TextInputType.phone,
          controller: TextEditingController(
            text: _phoneNumbers.isNotEmpty ? _phoneNumbers.first.number : '',
          ),
          onChanged: (value) {
            if (_phoneNumbers.isNotEmpty) {
              _phoneNumbers[0] = PhoneNumber(
                id: _phoneNumbers[0].id,
                number: value,
                label: _phoneNumbers[0].label,
                isPrimary: _phoneNumbers[0].isPrimary,
              );
            }
          },
        ),
        const SizedBox(height: 16),

        // Email
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'email@example.com',
            prefixIcon: Icon(LucideIcons.mail),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        // Facebook
        TextFormField(
          controller: _facebookController,
          decoration: const InputDecoration(
            labelText: 'Facebook Profile',
            hintText: 'Facebook profile URL',
            prefixIcon: Icon(LucideIcons.facebook),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfoSection(ColorScheme colorScheme) {
    if (!_expandedSections['product']!) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _productType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: ['SSS Pensioner', 'GSIS Pensioner', 'Private']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        HapticUtils.lightImpact();
                        setState(() => _productType = value);
                        // Auto-set pension type
                        if (value == 'SSS Pensioner') {
                          _pensionType = 'SSS';
                        } else if (value == 'GSIS Pensioner') {
                          _pensionType = 'GSIS';
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pension Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _pensionType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: ['SSS', 'GSIS', 'Private', 'None']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        HapticUtils.lightImpact();
                        setState(() => _pensionType = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _marketType,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Market Type',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          items: ['Residential', 'Commercial', 'Industrial']
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              HapticUtils.lightImpact();
              setState(() => _marketType = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildAddressSection(ColorScheme colorScheme) {
    if (!_expandedSections['address']!) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._addresses.asMap().entries.map((entry) {
          final index = entry.key;
          final address = entry.value;
          return _AddressEditField(
            address: address,
            onChanged: (updated) {
              setState(() {
                _addresses[index] = updated;
              });
            },
            onRemove: _addresses.length > 1
                ? () {
                    HapticUtils.lightImpact();
                    setState(() {
                      _addresses.removeAt(index);
                    });
                  }
                : null,
            colorScheme: colorScheme,
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            HapticUtils.lightImpact();
            setState(() {
              _addresses.add(Address(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                street: '',
                barangay: '',
                city: '',
                province: '',
                isPrimary: _addresses.isEmpty,
              ));
            });
          },
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('Add Address'),
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildPhoneNumbersSection(ColorScheme colorScheme) {
    if (!_expandedSections['phone']!) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._phoneNumbers.asMap().entries.map((entry) {
          final index = entry.key;
          final phone = entry.value;
          return _PhoneEditField(
            phone: phone,
            onChanged: (updated) {
              setState(() {
                _phoneNumbers[index] = updated;
              });
            },
            onRemove: _phoneNumbers.length > 1
                ? () {
                    HapticUtils.lightImpact();
                    setState(() {
                      _phoneNumbers.removeAt(index);
                    });
                  }
                : null,
            colorScheme: colorScheme,
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            HapticUtils.lightImpact();
            setState(() {
              _phoneNumbers.add(PhoneNumber(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                number: '',
                label: 'Mobile',
                isPrimary: _phoneNumbers.isEmpty,
              ));
            });
          },
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('Add Phone'),
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildRemarksSection(ColorScheme colorScheme) {
    if (!_expandedSections['remarks']!) return const SizedBox.shrink();

    return TextFormField(
      controller: _remarksController,
      decoration: const InputDecoration(
        labelText: 'Remarks',
        hintText: 'Additional notes about this client...',
        border: OutlineInputBorder(),
      ),
      maxLines: 4,
    );
  }
}

class _ClientTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ClientTypeButton({
    required this.label,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AddressEditField extends StatelessWidget {
  final Address address;
  final Function(Address) onChanged;
  final VoidCallback? onRemove;
  final ColorScheme colorScheme;

  const _AddressEditField({
    required this.address,
    required this.onChanged,
    this.onRemove,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: address.street,
                  decoration: const InputDecoration(
                    labelText: 'Street',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    onChanged(Address(
                      id: address.id,
                      street: value,
                      barangay: address.barangay,
                      city: address.city,
                      province: address.province,
                      isPrimary: address.isPrimary,
                    ));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: address.barangay,
                  decoration: const InputDecoration(
                    labelText: 'Barangay',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    onChanged(Address(
                      id: address.id,
                      street: address.street,
                      barangay: value,
                      city: address.city,
                      province: address.province,
                      isPrimary: address.isPrimary,
                    ));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: address.city,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    onChanged(Address(
                      id: address.id,
                      street: address.street,
                      barangay: address.barangay,
                      city: value,
                      province: address.province,
                      isPrimary: address.isPrimary,
                    ));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: address.province,
                  decoration: const InputDecoration(
                    labelText: 'Province',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    onChanged(Address(
                      id: address.id,
                      street: address.street,
                      barangay: address.barangay,
                      city: address.city,
                      province: value,
                      isPrimary: address.isPrimary,
                    ));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhoneEditField extends StatelessWidget {
  final PhoneNumber phone;
  final Function(PhoneNumber) onChanged;
  final VoidCallback? onRemove;
  final ColorScheme colorScheme;

  const _PhoneEditField({
    required this.phone,
    required this.onChanged,
    this.onRemove,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: DropdownButtonFormField<String>(
              value: phone.label,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              items: ['Mobile', 'Home', 'Work', 'Other']
                  .map((label) => DropdownMenuItem(
                        value: label,
                        child: Text(label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(PhoneNumber(
                    id: phone.id,
                    number: phone.number,
                    label: value,
                    isPrimary: phone.isPrimary,
                  ));
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: phone.number,
              decoration: const InputDecoration(
                hintText: '+63 912 345 6789',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                onChanged(PhoneNumber(
                  id: phone.id,
                  number: value,
                  label: phone.label,
                  isPrimary: phone.isPrimary,
                ));
              },
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 18),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
