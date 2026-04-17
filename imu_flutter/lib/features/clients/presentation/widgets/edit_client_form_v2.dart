import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/client_model.dart';
import '../../../psgc/data/models/psgc_models.dart';
import '../../../psgc/data/repositories/psgc_repository.dart';

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
  final _remarksController = TextEditingController();

  // Location dropdown values
  PsgcRegion? _selectedRegion;
  PsgcProvince? _selectedProvince;
  PsgcMunicipality? _selectedMunicipality;
  PsgcBarangay? _selectedBarangay;

  List<PsgcRegion> _regions = [];
  List<PsgcProvince> _provinces = [];
  List<PsgcMunicipality> _municipalities = [];
  List<PsgcBarangay> _barangays = [];

  // Loading states for cascading dropdowns
  bool _isLoadingProvinces = false;
  bool _isLoadingMunicipalities = false;
  bool _isLoadingBarangays = false;

  // Dropdown values
  String _productType = 'BFP ACTIVE';
  String _pensionType = 'SSS';
  String _marketType = 'Residential';
  String _clientType = 'POTENTIAL';
  String? _loanType;

  // Date picker
  DateTime? _birthDate;

  // Section expansion states
  final Map<String, bool> _expandedSections = {
    'client': true,         // Client Information - EXPANDED (client type, nested panels)
    'employment': false,    // Employment Info - COLLAPSED (nested under client)
    'product': false,       // Product Info - COLLAPSED (nested under client)
    'contact': false,       // Contact Information - COLLAPSED (phone, email, facebook, address)
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
    _remarksController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    setState(() => _isLoading = true);

    try {
      // Load PSGC data first
      final psgcRepository = await ref.read(psgcRepositoryProvider.future);
      final regions = await psgcRepository.getRegions();

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
        setState(() {
          _regions = regions;
        });

        // BUG FIX: Populate form fields IMMEDIATELY after client data is loaded
        // Don't wait for location data - load that in background
        _populateFormFields();

        // Set loading to false here - form is ready to use
        setState(() {
          _isLoading = false;
        });

        // Load location data in background without blocking the form
        _loadLocationDataInBackground();
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

  // Load location data in background without blocking the form
  Future<void> _loadLocationDataInBackground() async {
    if (_client == null) return;

    try {
      final psgcRepository = await ref.read(psgcRepositoryProvider.future);

      // Load provinces if region is set
      if (_client!.region != null && _client!.region!.isNotEmpty) {
        final provinces = await psgcRepository.getProvincesByRegion(_client!.region!);
        if (mounted) {
          setState(() {
            _provinces = provinces;
          });

          // Set the selected province from client data (now that provinces list is loaded)
          if (_client!.province != null && _client!.province!.isNotEmpty && provinces.isNotEmpty) {
            try {
              final foundProvince = provinces.firstWhere(
                (p) => p.name == _client!.province,
                orElse: () => provinces.first,
              );
              setState(() {
                _selectedProvince = foundProvince;
              });
            } catch (e) {
              debugPrint('[EditClientFormV2] Error finding province: $e');
            }
          }

          // Load municipalities if province is set
          if (_client!.province != null && _client!.province!.isNotEmpty) {
            final municipalities = await psgcRepository.getMunicipalitiesByProvince(_client!.province!);
            if (mounted) {
              setState(() {
                _municipalities = municipalities;
              });

              // Set the selected municipality from client data (now that municipalities list is loaded)
              if (_client!.municipality != null && _client!.municipality!.isNotEmpty && municipalities.isNotEmpty) {
                try {
                  final foundMunicipality = municipalities.firstWhere(
                    (m) => m.name == _client!.municipality || m.displayName == _client!.municipality,
                    orElse: () => municipalities.first,
                  );
                  setState(() {
                    _selectedMunicipality = foundMunicipality;
                  });
                } catch (e) {
                  debugPrint('[EditClientFormV2] Error finding municipality: $e');
                }
              }

              // Load barangays if municipality is set
              if (_client!.municipality != null && _client!.municipality!.isNotEmpty) {
                await _loadBarangays(_client!.municipality!);

                // Set the selected barangay from client data (now that barangays list is loaded)
                if (_client!.barangay != null && _client!.barangay!.isNotEmpty && _barangays.isNotEmpty) {
                  try {
                    final foundBarangay = _barangays.firstWhere(
                      (b) => b.barangay == _client!.barangay,
                      orElse: () => _barangays.first,
                    );
                    setState(() {
                      _selectedBarangay = foundBarangay;
                    });
                  } catch (e) {
                    debugPrint('[EditClientFormV2] Error finding barangay: $e');
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[EditClientFormV2] Error loading location data in background: $e');
      // Don't show error to user - form is already usable
    }
  }

  Future<void> _loadBarangays(String municipality) async {
    try {
      final psgcRepository = await ref.read(psgcRepositoryProvider.future);
      final barangays = await psgcRepository.getBarangaysByMunicipality(municipality);
      if (mounted) {
        setState(() {
          _barangays = barangays;
          _isLoadingBarangays = false;
        });
      }
    } catch (e) {
      debugPrint('[EditClientFormV2] Error loading barangays: $e');
      if (mounted) {
        setState(() => _isLoadingBarangays = false);
      }
    }
  }

  void _populateFormFields() {
    if (_client == null) return;

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
    _loanType = _client!.loanTypeDisplay;

    // Location - Find and set dropdown values
    if (_client!.region != null && _client!.region!.isNotEmpty) {
      _selectedRegion = _regions.firstWhere(
        (r) => r.name == _client!.region || r.code == _client!.region,
        orElse: () => _regions.first,
      );
    }

    if (_client!.province != null && _client!.province!.isNotEmpty) {
      try {
        final foundProvince = _provinces.firstWhere(
          (p) => p.name == _client!.province,
          orElse: () => _provinces.first,
        );
        _selectedProvince = foundProvince;
      } catch (e) {
        if (_provinces.isNotEmpty) {
          _selectedProvince = _provinces.first;
        }
      }
    }

    if (_client!.municipality != null && _client!.municipality!.isNotEmpty) {
      try {
        final foundMunicipality = _municipalities.firstWhere(
          (m) => m.name == _client!.municipality || m.displayName == _client!.municipality,
          orElse: () => _municipalities.first,
        );
        _selectedMunicipality = foundMunicipality;
      } catch (e) {
        if (_municipalities.isNotEmpty) {
          _selectedMunicipality = _municipalities.first;
        }
      }
    }

    if (_client!.barangay != null && _client!.barangay!.isNotEmpty) {
      try {
        final foundBarangay = _barangays.firstWhere(
          (b) => b.barangay == _client!.barangay,
          orElse: () => _barangays.first,
        );
        _selectedBarangay = foundBarangay;
      } catch (e) {
        if (_barangays.isNotEmpty) {
          _selectedBarangay = _barangays.first;
        }
      }
    }

    // PAN
    _panController.text = _client!.pan ?? '';

    // Remarks
    _remarksController.text = _client!.remarks ?? '';
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
        AppNotification.showError(context, 'Please fix the errors before saving');
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
        loanType: _parseLoanType(_loanType),
        marketType: _parseMarketType(_marketType),
        clientType: _parseClientType(_clientType),
        pan: _panController.text.trim().isEmpty
            ? null
            : _panController.text.trim(),
        region: _selectedRegion?.name,
        province: _selectedProvince?.name,
        municipality: _selectedMunicipality?.name,
        barangay: _selectedBarangay?.barangay,
        createdAt: _client?.createdAt,
        updatedAt: DateTime.now(),
        touchpoints: _client?.touchpoints ?? [],
        isStarred: _client?.isStarred ?? false,
        loanReleased: _client?.loanReleased ?? false,
        loanReleasedAt: _client?.loanReleasedAt,
        agencyId: _client?.agencyId,
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
          // Null result means approval is required (caravan/tele users)
          debugPrint('[EditClientFormV2] Client edit requires approval');
          if (mounted) {
            _showSuccessSnackBar('Client edit submitted for approval');
            if (widget.isModal) {
              Navigator.of(context).pop(true);
            }
          }
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
      case 'BFP ACTIVE':
        return ProductType.bfpActive;
      case 'BFP PENSION':
        return ProductType.bfpPension;
      case 'PNP PENSION':
        return ProductType.pnpPension;
      case 'NAPOLCOM':
        return ProductType.napolcom;
      case 'BFP STP':
        return ProductType.bfpStp;
      default:
        return ProductType.bfpActive;
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

  LoanType? _parseLoanType(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toUpperCase()) {
      case 'NEW':
        return LoanType.firstLoan;
      case 'ADDITIONAL':
        return LoanType.additional;
      case 'RENEWAL':
        return LoanType.renewal;
      case 'PRETERM':
        return LoanType.preterm;
      default:
        return null;
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
    AppNotification.showSuccess(context, message);
  }

  void _showWarningSnackBar(String message) {
    AppNotification.showWarning(context, message, duration: const Duration(seconds: 4));
  }

  void _showErrorSnackBar(String message) {
    AppNotification.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      final loadingWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
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
          // Name Section (always visible, not expandable)
          const Text(
            'Name',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildNameFields(colorScheme),

          const SizedBox(height: 24),

          // Basic Info Section (always visible)
          _buildBasicInfoSection(colorScheme),

          const SizedBox(height: 24),

          // Client Information Section
          _buildSectionHeader(
            title: 'Client Information',
            icon: LucideIcons.user,
            sectionKey: 'client',
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _buildClientInfoSection(colorScheme),

          const SizedBox(height: 24),

          // Contact Information Section
          _buildSectionHeader(
            title: 'Contact Information',
            icon: LucideIcons.phone,
            sectionKey: 'contact',
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _buildContactInfoSection(colorScheme),

          const SizedBox(height: 32),

          // Buttons (Cancel + Save Changes)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : (widget.onCancel ?? () => Navigator.of(context).pop()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
            ],
          ),
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

  Widget _buildNameFields(ColorScheme colorScheme) {
    return Row(
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
    );
  }

  Widget _buildBasicInfoSection(ColorScheme colorScheme) {
    // Calculate age
    int age = 0;
    if (_birthDate != null) {
      final now = DateTime.now();
      age = now.year - _birthDate!.year;
      if (now.month < _birthDate!.month ||
          (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
        age--;
      }
    }

    // Format created at date
    String createdAtFormatted = 'N/A';
    if (_client?.createdAt != null) {
      final date = _client!.createdAt!;
      createdAtFormatted = '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        // Age and Created At
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Age',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    age > 0 ? '$age' : 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Created At',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    createdAtFormatted,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
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

  Widget _buildClientInfoSection(ColorScheme colorScheme) {
    if (!_expandedSections['client']!) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        const SizedBox(height: 16),

        // Nested: Employment Info Section
        _buildNestedSectionHeader(
          title: 'Employment Info',
          icon: LucideIcons.briefcase,
          sectionKey: 'employment',
          color: colorScheme.primary,
        ),
        const SizedBox(height: 12),
        _buildEmploymentInfoSection(colorScheme),

        const SizedBox(height: 16),

        // Nested: Product Info Section
        _buildNestedSectionHeader(
          title: 'Product Info',
          icon: LucideIcons.creditCard,
          sectionKey: 'product',
          color: colorScheme.primary,
        ),
        const SizedBox(height: 12),
        _buildProductInfoSection(colorScheme),
      ],
    );
  }

  Widget _buildNestedSectionHeader({
    required String title,
    required IconData icon,
    required String sectionKey,
    required Color color,
  }) {
    final isExpanded = _expandedSections[sectionKey]!;
    return InkWell(
      onTap: () => _toggleSection(sectionKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmploymentInfoSection(ColorScheme colorScheme) {
    if (!_expandedSections['employment']!) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
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
          const SizedBox(height: 12),

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
          const SizedBox(height: 12),

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
      ),
    );
  }

  Widget _buildProductInfoSection(ColorScheme colorScheme) {
    if (!_expandedSections['product']!) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _productType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Product Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: const ['BFP ACTIVE', 'BFP PENSION', 'PNP PENSION', 'NAPOLCOM', 'BFP STP']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      HapticUtils.lightImpact();
                      setState(() => _productType = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _pensionType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Pension Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _loanType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Loan Type',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            items: const ['NEW', 'ADDITIONAL', 'RENEWAL', 'PRETERM']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                HapticUtils.lightImpact();
                setState(() => _loanType = value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _panController,
            decoration: const InputDecoration(
              labelText: 'PAN',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection(ColorScheme colorScheme) {
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
        const SizedBox(height: 16),

        // Address Section Header
        const Text(
          'Address',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),

        // Region Dropdown
        DropdownButtonFormField<PsgcRegion>(
          value: _selectedRegion,
          decoration: InputDecoration(
            labelText: 'Region *',
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: _regions.isEmpty
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          items: _regions.map((region) {
            return DropdownMenuItem<PsgcRegion>(
              value: region,
              child: Text(region.name),
            );
          }).toList(),
          onChanged: (region) async {
            setState(() {
              _selectedRegion = region;
              _selectedProvince = null;
              _selectedMunicipality = null;
              _selectedBarangay = null;
              _provinces = [];
              _municipalities = [];
              _barangays = [];
              _isLoadingProvinces = region != null;
            });

            if (region != null) {
              try {
                final psgcRepository = await ref.read(psgcRepositoryProvider.future);
                final provinces = await psgcRepository.getProvincesByRegion(region.name);
                if (mounted) {
                  setState(() {
                    _provinces = provinces;
                    _isLoadingProvinces = false;
                  });
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoadingProvinces = false);
                }
              }
            }
          },
        ),
        const SizedBox(height: 16),

        // Province Dropdown
        IgnorePointer(
          ignoring: _selectedRegion == null || _isLoadingProvinces,
          child: DropdownButtonFormField<PsgcProvince>(
            value: _selectedProvince,
            decoration: InputDecoration(
              labelText: 'Province *',
              border: const OutlineInputBorder(),
              isDense: true,
              filled: _selectedRegion == null,
              fillColor: _selectedRegion == null ? Colors.grey.shade100 : null,
              suffixIcon: _isLoadingProvinces
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              hintText: _selectedRegion == null ? 'Select region first' : null,
            ),
            items: _provinces.isEmpty && _selectedRegion != null && !_isLoadingProvinces
                ? [
                    const DropdownMenuItem<PsgcProvince>(
                      value: null,
                      enabled: false,
                      child: Text('No provinces available', style: TextStyle(color: Colors.grey)),
                    ),
                  ]
                : _provinces.map((province) {
                    return DropdownMenuItem<PsgcProvince>(
                      value: province,
                      child: Text(province.name),
                    );
                  }).toList(),
            onChanged: _selectedRegion == null
                ? null
                : (province) async {
                    setState(() {
                      _selectedProvince = province;
                      _selectedMunicipality = null;
                      _selectedBarangay = null;
                      _municipalities = [];
                      _barangays = [];
                      _isLoadingMunicipalities = province != null;
                    });

                    if (province != null) {
                      try {
                        final psgcRepository = await ref.read(psgcRepositoryProvider.future);
                        final municipalities = await psgcRepository.getMunicipalitiesByProvince(province.name);
                        if (mounted) {
                          setState(() {
                            _municipalities = municipalities;
                            _isLoadingMunicipalities = false;
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isLoadingMunicipalities = false);
                        }
                      }
                    }
                  },
          ),
        ),
        const SizedBox(height: 16),

        // Municipality Dropdown
        IgnorePointer(
          ignoring: _selectedProvince == null || _isLoadingMunicipalities,
          child: DropdownButtonFormField<PsgcMunicipality>(
            value: _selectedMunicipality,
            decoration: InputDecoration(
              labelText: 'Municipality/City *',
              border: const OutlineInputBorder(),
              isDense: true,
              filled: _selectedProvince == null,
              fillColor: _selectedProvince == null ? Colors.grey.shade100 : null,
              suffixIcon: _isLoadingMunicipalities
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              hintText: _selectedProvince == null ? 'Select province first' : null,
            ),
            items: _municipalities.isEmpty && _selectedProvince != null && !_isLoadingMunicipalities
                ? [
                    const DropdownMenuItem<PsgcMunicipality>(
                      value: null,
                      enabled: false,
                      child: Text('No municipalities available', style: TextStyle(color: Colors.grey)),
                    ),
                  ]
                : _municipalities.map((municipality) {
                    return DropdownMenuItem<PsgcMunicipality>(
                      value: municipality,
                      child: Text(municipality.displayName),
                    );
                  }).toList(),
            onChanged: _selectedProvince == null
                ? null
                : (municipality) async {
                    setState(() {
                      _selectedMunicipality = municipality;
                      _selectedBarangay = null;
                      _barangays = [];
                      _isLoadingBarangays = municipality != null;
                    });

                    if (municipality != null) {
                      await _loadBarangays(municipality.name);
                    }
                  },
          ),
        ),
        const SizedBox(height: 16),

        // Barangay Dropdown
        IgnorePointer(
          ignoring: _selectedMunicipality == null || _isLoadingBarangays,
          child: DropdownButtonFormField<PsgcBarangay>(
            value: _selectedBarangay,
            decoration: InputDecoration(
              labelText: 'Barangay *',
              border: const OutlineInputBorder(),
              isDense: true,
              filled: _selectedMunicipality == null,
              fillColor: _selectedMunicipality == null ? Colors.grey.shade100 : null,
              suffixIcon: _isLoadingBarangays
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              hintText: _selectedMunicipality == null ? 'Select municipality first' : null,
            ),
            items: _barangays.isEmpty && _selectedMunicipality != null && !_isLoadingBarangays
                ? [
                    const DropdownMenuItem<PsgcBarangay>(
                      value: null,
                      enabled: false,
                      child: Text('No barangays available', style: TextStyle(color: Colors.grey)),
                    ),
                  ]
                : _barangays.map((barangay) {
                    return DropdownMenuItem<PsgcBarangay>(
                      value: barangay,
                      child: Text(barangay.barangay ?? 'Unknown'),
                    );
                  }).toList(),
            onChanged: _selectedMunicipality == null
                ? null
                : (barangay) {
                    HapticUtils.lightImpact();
                    setState(() {
                      _selectedBarangay = barangay;
                    });
                  },
          ),
        ),
      ],
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
