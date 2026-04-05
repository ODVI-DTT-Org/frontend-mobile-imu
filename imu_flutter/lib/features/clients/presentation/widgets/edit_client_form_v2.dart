import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/client_model.dart';

/// Edit Client Form Widget - Aligned with Database Schema
///
/// Uses direct columns instead of nested lists:
/// - region, province, municipality, barangay (direct fields)
/// - phone (single field instead of phoneNumbers list)
/// - udi field added
/// - All fields match the database schema
class EditClientFormV2 extends ConsumerStatefulWidget {
  final String clientId;
  final Client? initialClient;
  final Function(Client)? onSave;
  final bool isModal;
  final VoidCallback? onCancel;

  const EditClientFormV2({
    super.key,
    required this.clientId,
    this.initialClient,
    this.onSave,
    this.isModal = false,
    this.onCancel,
  });

  @override
  ConsumerState<EditClientFormV2> createState() => _EditClientFormV2State();
}

class _EditClientFormV2State extends ConsumerState<EditClientFormV2> {
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
  final _phoneController = TextEditingController();
  final _facebookController = TextEditingController();
  final _agencyNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();
  final _employmentStatusController = TextEditingController();
  final _payrollDateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _panController = TextEditingController();
  final _udiController = TextEditingController();
  final _remarksController = TextEditingController();

  // Location controllers
  final _regionController = TextEditingController();
  final _provinceController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _barangayController = TextEditingController();

  // Dropdown values
  String _productType = 'SSS Pensioner';
  String _pensionType = 'SSS';
  String _marketType = 'Residential';
  String _clientType = 'POTENTIAL';

  // Date picker
  DateTime? _birthDate;

  // Section expansion states
  final Map<String, bool> _expandedSections = {
    'basic': true,
    'contact': true,
    'employment': false,
    'product': true,
    'location': true,
    'udi': false,
    'remarks': false,
  };

  @override
  void initState() {
    super.initState();
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
    _phoneController.dispose();
    _facebookController.dispose();
    _agencyNameController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _employmentStatusController.dispose();
    _payrollDateController.dispose();
    _tenureController.dispose();
    _panController.dispose();
    _udiController.dispose();
    _remarksController.dispose();
    _regionController.dispose();
    _provinceController.dispose();
    _municipalityController.dispose();
    _barangayController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    setState(() => _isLoading = true);

    try {
      if (widget.initialClient != null) {
        _client = widget.initialClient;
      } else {
        if (!_hiveService.isInitialized) {
          await _hiveService.init();
        }

        final clientData = _hiveService.getClient(widget.clientId);
        if (clientData != null) {
          try {
            _client = Client.fromRow(clientData);
          } catch (e) {
            debugPrint('[EditClientFormV2] fromRow failed, trying fromJson: $e');
            _client = Client.fromJson(clientData);
          }
        }

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
      debugPrint('[EditClientFormV2] Error loading client: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to load client', e);
      }
    }
  }

  void _populateForm() {
    if (_client == null) return;

    setState(() {
      // Basic info
      _firstNameController.text = _client!.firstName;
      _middleNameController.text = _client!.middleName ?? '';
      _lastNameController.text = _client!.lastName;
      _birthDate = _client!.birthDate;

      // Contact info
      _emailController.text = _client!.email ?? '';
      _phoneController.text = _client!.phone ?? '';
      _facebookController.text = _client!.facebookLink ?? '';

      // Employment info
      _agencyNameController.text = _client!.agencyName ?? '';
      _departmentController.text = _client!.department ?? '';
      _positionController.text = _client!.position ?? '';
      _employmentStatusController.text = _client!.employmentStatus ?? '';
      _payrollDateController.text = _client!.payrollDate ?? '';
      _tenureController.text = _client!.tenure?.toString() ?? '';

      // Product info
      _productType = _getProductTypeLabel(_client!.productType);
      _pensionType = _getPensionTypeLabel(_client!.pensionType);
      _marketType = _client!.marketType != null
          ? _getMarketTypeLabel(_client!.marketType!)
          : 'Residential';
      _clientType = _client!.clientType.name.toUpperCase();

      // UDI
      _udiController.text = _client!.udi ?? '';

      // Location
      _regionController.text = _client!.region ?? '';
      _provinceController.text = _client!.province ?? '';
      _municipalityController.text = _client!.municipality ?? '';
      _barangayController.text = _client!.barangay ?? '';

      // PAN
      _panController.text = _client!.pan ?? '';

      // Remarks
      _remarksController.text = _client!.remarks ?? '';
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
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        facebookLink: _facebookController.text.trim().isEmpty
            ? null
            : _facebookController.text.trim(),
        agencyName: _agencyNameController.text.trim().isEmpty
            ? null
            : _agencyNameController.text.trim(),
        department: _departmentController.text.trim().isEmpty
            ? null
            : _departmentController.text.trim(),
        position: _positionController.text.trim().isEmpty
            ? null
            : _positionController.text.trim(),
        employmentStatus: _employmentStatusController.text.trim().isEmpty
            ? null
            : _employmentStatusController.text.trim(),
        payrollDate: _payrollDateController.text.trim().isEmpty
            ? null
            : _payrollDateController.text.trim(),
        tenure: _tenureController.text.trim().isEmpty
            ? null
            : int.tryParse(_tenureController.text.trim()),
        birthDate: _birthDate,
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        productType: _parseProductType(_productType),
        pensionType: _parsePensionType(_pensionType),
        marketType: _parseMarketType(_marketType),
        clientType: _parseClientType(_clientType),
        pan: _panController.text.trim().isEmpty
            ? null
            : _panController.text.trim(),
        udi: _udiController.text.trim().isEmpty
            ? null
            : _udiController.text.trim(),
        region: _regionController.text.trim().isEmpty
            ? null
            : _regionController.text.trim(),
        province: _provinceController.text.trim().isEmpty
            ? null
            : _provinceController.text.trim(),
        municipality: _municipalityController.text.trim().isEmpty
            ? null
            : _municipalityController.text.trim(),
        barangay: _barangayController.text.trim().isEmpty
            ? null
            : _barangayController.text.trim(),
        createdAt: _client?.createdAt,
        updatedAt: DateTime.now(),
        touchpoints: _client?.touchpoints ?? [],
        isStarred: _client?.isStarred ?? false,
        loanReleased: _client?.loanReleased ?? false,
        loanReleasedAt: _client?.loanReleasedAt,
        agencyId: _client?.agencyId,
        userId: _client?.userId,
        psgcId: _client?.psgcId,
      );

      debugPrint('[EditClientFormV2] Submitting client edit: ${widget.clientId}');

      final isOnline = ref.read(isOnlineProvider);

      if (isOnline) {
        debugPrint('[EditClientFormV2] Online - submitting to backend API');
        final clientApi = ref.read(clientApiServiceProvider);
        final result = await clientApi.updateClient(updatedClient);

        if (result != null) {
          debugPrint('[EditClientFormV2] Client edit submitted successfully');
          await _hiveService.saveClient(widget.clientId, result.toJson());

          if (widget.onSave != null) {
            widget.onSave!(result);
          }

          if (mounted) {
            _showSuccessSnackBar('Client updated successfully');
            if (widget.isModal) {
              Navigator.of(context).pop(true);
            }
          }
        } else {
          throw Exception('Failed to update client - client not found');
        }
      } else {
        debugPrint('[EditClientFormV2] Offline - saving to local storage only');
        await _hiveService.saveClient(widget.clientId, updatedClient.toJson());

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
      debugPrint('[EditClientFormV2] Error: $e\n$stack');
      HapticUtils.error();
      if (mounted) {
        _showErrorSnackBar('Failed to update client: $e');
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
      final loadingWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading client...'),
          ],
        ),
      );
      return widget.isModal
          ? Scaffold(body: loadingWidget)
          : loadingWidget;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final formContent = Form(
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

          // Employment Information Section
          _buildSectionHeader(
            title: 'Employment Information',
            icon: LucideIcons.briefcase,
            sectionKey: 'employment',
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _buildEmploymentSection(colorScheme),

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

          // Location Section
          _buildSectionHeader(
            title: 'Location',
            icon: LucideIcons.mapPin,
            sectionKey: 'location',
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _buildLocationSection(colorScheme),

          const SizedBox(height: 24),

          // UDI Section
          _buildSectionHeader(
            title: 'Unified ID (UDI)',
            icon: LucideIcons.idCard,
            sectionKey: 'udi',
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _buildUDISection(colorScheme),

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
    );

    if (widget.isModal) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: formContent,
      );
    }

    return formContent;
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

        // Birth Date
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _birthDate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _birthDate = picked);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Birth Date',
              border: OutlineInputBorder(),
              isDense: true,
              suffixIcon: Icon(LucideIcons.calendar, size: 20),
            ),
            baseStyle: TextStyle(
              fontSize: 16,
              color: _birthDate != null ? Colors.black : Colors.grey,
            ),
            child: Text(
              _birthDate != null
                  ? '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}'
                  : 'Select birth date',
            ),
          ),
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
        // Phone
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+63 912 345 6789',
            prefixIcon: Icon(LucideIcons.phone),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType: TextInputType.phone,
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

  Widget _buildEmploymentSection(ColorScheme colorScheme) {
    if (!_expandedSections['employment']!) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _agencyNameController,
                decoration: const InputDecoration(
                  labelText: 'Agency Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _employmentStatusController,
                decoration: const InputDecoration(
                  labelText: 'Employment Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _payrollDateController,
                decoration: const InputDecoration(
                  labelText: 'Payroll Date',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _tenureController,
                decoration: const InputDecoration(
                  labelText: 'Tenure (months)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
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

  Widget _buildLocationSection(ColorScheme colorScheme) {
    if (!_expandedSections['location']!) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _regionController,
                decoration: const InputDecoration(
                  labelText: 'Region',
                  hintText: 'e.g., NCR, Region I',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _provinceController,
                decoration: const InputDecoration(
                  labelText: 'Province',
                  hintText: 'e.g., Metro Manila',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _municipalityController,
                decoration: const InputDecoration(
                  labelText: 'Municipality',
                  hintText: 'e.g., Cebu City',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _barangayController,
                decoration: const InputDecoration(
                  labelText: 'Barangay',
                  hintText: 'e.g., Luz',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUDISection(ColorScheme colorScheme) {
    if (!_expandedSections['udi']!) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _udiController,
          decoration: const InputDecoration(
            labelText: 'Unified ID (UDI)',
            hintText: 'Enter UDI',
            border: OutlineInputBorder(),
            isDense: true,
          ),
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
