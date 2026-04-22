import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../services/client/client_mutation_service.dart' show ClientMutationResult;
import '../../data/models/client_model.dart';
import '../../../psgc/data/models/psgc_models.dart';
import '../../../psgc/data/repositories/psgc_repository.dart';

/// Add Client Page - Aligned with Database Schema
///
/// Uses direct columns instead of nested lists:
/// - region, province, municipality, barangay (direct fields)
/// - phone (single field instead of phoneNumbers list)
/// - All fields match the database schema
class AddClientPage extends ConsumerStatefulWidget {
  const AddClientPage({super.key});

  @override
  ConsumerState<AddClientPage> createState() => _AddClientPageState();
}

class _AddClientPageState extends ConsumerState<AddClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Loading states
  bool _isLoading = true;
  bool _isSaving = false;

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
  String _pensionType = 'PNP - RETIREE OPTIONAL';
  String _marketType = 'BFP ACTIVE';
  String _clientType = 'VIRGIN';
  String? _loanType;

  // Date picker
  DateTime? _birthDate;

  // Section expansion states
  final Map<String, bool> _expandedSections = {
    'personal': true,
    'contact': true,
    'professional': false,
    'product': false,
    'notes': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPsgcData();
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

  Future<void> _loadPsgcData() async {
    setState(() => _isLoading = true);

    try {
      // Load PSGC regions
      final psgcRepository = ref.read(psgcRepositoryProvider);
      final regions = await psgcRepository.getRegions();

      if (mounted) {
        setState(() {
          _regions = regions;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[AddClientPage] Error loading PSGC data: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to load location data', e);
      }
    }
  }

  Future<void> _loadBarangays(String municipality) async {
    try {
      final psgcRepository = ref.read(psgcRepositoryProvider);
      final barangays = await psgcRepository.getBarangaysByMunicipality(municipality);
      if (mounted) {
        setState(() {
          _barangays = barangays;
          _isLoadingBarangays = false;
        });
      }
    } catch (e) {
      debugPrint('[AddClientPage] Error loading barangays: $e');
      if (mounted) {
        setState(() => _isLoadingBarangays = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      HapticUtils.error();
      if (mounted) {
        AppNotification.showError(context, 'Please fix the errors before submitting');
      }
      return;
    }

    HapticUtils.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final newClient = Client(
        id: '',
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        touchpoints: [],
        isStarred: false,
        loanReleased: false,
        loanReleasedAt: null,
        agencyId: null,
        psgcId: null,
      );

      debugPrint('[AddClientPage] Submitting new client');

      final mutationService = ref.read(clientMutationServiceProvider);
      final result = await mutationService.createClient(newClient);

      if (mounted) {
        switch (result) {
          case ClientMutationResult.success:
            _showSuccessSnackBar('Client added successfully');
          case ClientMutationResult.requiresApproval:
            _showSuccessSnackBar('Client submitted for approval');
          case ClientMutationResult.queued:
            _showWarningSnackBar('Offline: Client will sync when connected');
        }
        context.pop(true);
      }
    } catch (e, stack) {
      debugPrint('[AddClientPage] Error: $e\n$stack');
      HapticUtils.error();
      if (mounted) {
        _showErrorSnackBar('Failed to add client: $e');
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
      case 'PNP - RETIREE OPTIONAL':
        return PensionType.pnpRetireeOptional;
      case 'PNP - RETIREE COMPULSORY':
        return PensionType.pnpRetireeCompulsory;
      case 'PNP - RETIREE':
        return PensionType.pnpRetiree;
      case 'BFP - RETIREE':
        return PensionType.bfpRetiree;
      case 'BFP STP - RETIREE':
        return PensionType.bfpStpRetiree;
      case 'PNP - TRANSFEREE':
        return PensionType.pnpTransferree;
      case 'BFP - SURVIVOR':
        return PensionType.bfpSurvivor;
      case 'PNP - SURVIVOR':
        return PensionType.pnpSurvivor;
      case 'PNP - TPPD':
        return PensionType.pnpTppd;
      case 'BFP - TPPD':
        return PensionType.bfpTppd;
      case 'PNP - MINOR':
        return PensionType.pnpMinor;
      case 'BFP - MINOR':
        return PensionType.bfpMinor;
      case 'PNP - POSTHUMOUS MINOR':
        return PensionType.pnpPosthumousMinor;
      case 'PNP - POSTHUMOUS SPOUSE':
        return PensionType.pnpPosthumousSpouse;
      case 'OTHERS':
        return PensionType.others;
      default:
        return PensionType.others;
    }
  }

  MarketType _parseMarketType(String value) {
    switch (value) {
      case 'VIRGIN':
        return MarketType.virgin;
      case 'EXISTING':
        return MarketType.existing;
      case 'FULLY PAID':
        return MarketType.fullyPaid;
      default:
        return MarketType.virgin;
    }
  }

  ClientType _parseClientType(String value) {
    switch (value.toUpperCase()) {
      case 'POTENTIAL':
        return ClientType.potential;
      case 'EXISTING':
        return ClientType.existing;
      default:
        return ClientType.potential;
    }
  }

  LoanType? _parseLoanType(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toUpperCase()) {
      case 'NEW':
        return LoanType.newLoan;
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
    AppNotification.showWarning(context, message);
  }

  void _showErrorSnackBar(String message) {
    AppNotification.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Add Client'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final role = ref.watch(currentUserRoleProvider);
    final saveLabel = role == UserRole.admin ? 'Save Client' : 'Submit for Approval';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Client'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // Personal Section
            _buildSectionHeader(
              title: 'Personal',
              icon: LucideIcons.user,
              sectionKey: 'personal',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildPersonalSection(colorScheme),

            const SizedBox(height: 24),

            // Contact Section (phone/email/facebook + location)
            _buildSectionHeader(
              title: 'Contact',
              icon: LucideIcons.phone,
              sectionKey: 'contact',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildContactSection(colorScheme),

            const SizedBox(height: 24),

            // Professional Section
            _buildSectionHeader(
              title: 'Professional',
              icon: LucideIcons.briefcase,
              sectionKey: 'professional',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildProfessionalSection(colorScheme),

            const SizedBox(height: 24),

            // Product Section
            _buildSectionHeader(
              title: 'Product',
              icon: LucideIcons.creditCard,
              sectionKey: 'product',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildProductSection(colorScheme),

            const SizedBox(height: 24),

            // Notes Section
            _buildSectionHeader(
              title: 'Notes',
              icon: LucideIcons.messageSquare,
              sectionKey: 'notes',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildNotesSection(colorScheme),

            const SizedBox(height: 32),

            // Cancel + Save button row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                        : Text(
                            saveLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
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

  Widget _buildPersonalSection(ColorScheme colorScheme) {
    if (!_expandedSections['personal']!) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildContactSection(ColorScheme colorScheme) {
    if (!_expandedSections['contact']!) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        const SizedBox(height: 24),

        // Location fields (merged from old Location section)
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
                final psgcRepository = ref.read(psgcRepositoryProvider);
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
                if (mounted) {
                  _showErrorDialog('Failed to load provinces', e);
                }
              }
            }
          },
          validator: (value) => value == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),

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
                        final psgcRepository = ref.read(psgcRepositoryProvider);
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
                        if (mounted) {
                          _showErrorDialog('Failed to load municipalities', e);
                        }
                      }
                    }
                  },
          ),
        ),
        const SizedBox(height: 16),

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

  Widget _buildProfessionalSection(ColorScheme colorScheme) {
    if (!_expandedSections['professional']!) return const SizedBox.shrink();

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

  Widget _buildProductSection(ColorScheme colorScheme) {
    if (!_expandedSections['product']!) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Client Type (moved from Personal)
        const Text(
          'Client Type',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ClientTypeButton(
                label: 'Virgin',
                isSelected: _clientType == 'VIRGIN',
                colorScheme: colorScheme,
                onTap: () {
                  HapticUtils.selectionClick();
                  setState(() => _clientType = 'VIRGIN');
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

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Type',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _productType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: const [
                      'BFP ACTIVE',
                      'BFP PENSION',
                      'BFP STP',
                      'NAPOLCOM',
                      'PNP PENSION',
                      'PNP - RETIREE OPTIONAL',
                      'PNP - RETIREE COMPULSORY',
                      'PNP - RETIREE',
                      'BFP - RETIREE',
                      'BFP STP - RETIREE',
                      'PNP - TRANSFEREE',
                      'BFP - SURVIVOR',
                      'PNP - SURVIVOR',
                      'PNP - TPPD',
                      'BFP - TPPD',
                      'PNP - MINOR',
                      'BFP - MINOR',
                      'PNP - POSTHUMOUS MINOR',
                      'PNP - POSTHUMOUS SPOUSE',
                      'OTHERS',
                    ]
                        .map((type) => DropdownMenuItem(value: type, child: Text(type, style: TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        HapticUtils.lightImpact();
                        setState(() => _productType = value);
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
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _pensionType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: const [
                      'PNP - RETIREE OPTIONAL',
                      'PNP - RETIREE COMPULSORY',
                      'PNP - RETIREE',
                      'BFP - RETIREE',
                      'BFP STP - RETIREE',
                      'PNP - TRANSFEREE',
                      'BFP - SURVIVOR',
                      'PNP - SURVIVOR',
                      'PNP - TPPD',
                      'BFP - TPPD',
                      'PNP - MINOR',
                      'BFP - MINOR',
                      'PNP - POSTHUMOUS MINOR',
                      'PNP - POSTHUMOUS SPOUSE',
                      'OTHERS',
                    ]
                        .map((type) => DropdownMenuItem(value: type, child: Text(type, style: TextStyle(fontSize: 12))))
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
          items: const [
            'BFP ACTIVE',
            'BFP PENSION',
            'EXISTING',
            'FULLY PAID',
            'OTHERS',
          ]
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              HapticUtils.lightImpact();
              setState(() => _marketType = value);
            }
          },
        ),
        const SizedBox(height: 16),
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
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              HapticUtils.lightImpact();
              setState(() => _loanType = value);
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _panController,
          decoration: const InputDecoration(
            labelText: 'PAN',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(ColorScheme colorScheme) {
    if (!_expandedSections['notes']!) return const SizedBox.shrink();

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
