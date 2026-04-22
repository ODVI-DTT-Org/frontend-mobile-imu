import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../services/client/client_mutation_service.dart' show ClientMutationResult;
import '../../data/repositories/client_repository.dart' show clientRepositoryProvider;
import '../../data/models/client_model.dart';
import '../../../psgc/data/models/psgc_models.dart';
import '../../../psgc/data/repositories/psgc_repository.dart';

class EditClientPage extends ConsumerStatefulWidget {
  final String clientId;

  const EditClientPage({super.key, required this.clientId});

  @override
  ConsumerState<EditClientPage> createState() => _EditClientPageState();
}

class _EditClientPageState extends ConsumerState<EditClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSaving = false;
  Client? _client;

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

  PsgcRegion? _selectedRegion;
  PsgcProvince? _selectedProvince;
  PsgcMunicipality? _selectedMunicipality;
  PsgcBarangay? _selectedBarangay;

  List<PsgcRegion> _regions = [];
  List<PsgcProvince> _provinces = [];
  List<PsgcMunicipality> _municipalities = [];
  List<PsgcBarangay> _barangays = [];

  bool _isLoadingProvinces = false;
  bool _isLoadingMunicipalities = false;
  bool _isLoadingBarangays = false;

  String _productType = 'BFP ACTIVE';
  String _pensionType = 'SSS';
  String _marketType = 'Residential';
  String _clientType = 'POTENTIAL';
  String? _loanType;
  DateTime? _birthDate;

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
      final psgcRepository = ref.read(psgcRepositoryProvider);
      final regions = await psgcRepository.getRegions();

      final clientRepo = ref.read(clientRepositoryProvider);
      Client? client = await clientRepo.getClient(widget.clientId);

      if (client != null && mounted) {
        _client = client;
        setState(() {
          _regions = regions;
          _isLoading = false;
        });
        _populateFormFields();
        _loadLocationDataInBackground();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showNotFoundError();
        }
      }
    } catch (e, stack) {
      debugPrint('[EditClientPage] Error loading client: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to load client', e);
      }
    }
  }

  Future<void> _loadLocationDataInBackground() async {
    if (_client == null) return;

    try {
      final psgcRepository = ref.read(psgcRepositoryProvider);

      if (_client!.region != null && _client!.region!.isNotEmpty) {
        if (mounted) setState(() => _isLoadingProvinces = true);
        final provinces = await psgcRepository.getProvincesByRegion(_client!.region!);
        if (mounted) {
          PsgcProvince? matchedProvince;
          if (_client!.province != null && provinces.isNotEmpty) {
            try {
              matchedProvince = provinces.firstWhere(
                (p) => p.name == _client!.province,
              );
            } catch (_) {
              matchedProvince = null;
            }
          }
          setState(() {
            _provinces = provinces;
            _selectedProvince = matchedProvince;
            _isLoadingProvinces = false;
          });

          if (_client!.province != null) {
            setState(() => _isLoadingMunicipalities = true);
            final municipalities = await psgcRepository.getMunicipalitiesByProvince(_client!.province!);
            if (mounted) {
              PsgcMunicipality? matchedMunicipality;
              if (_client!.municipality != null && municipalities.isNotEmpty) {
                try {
                  matchedMunicipality = municipalities.firstWhere(
                    (m) => m.name == _client!.municipality || m.displayName == _client!.municipality,
                  );
                } catch (_) {
                  matchedMunicipality = null;
                }
              }
              setState(() {
                _municipalities = municipalities;
                _selectedMunicipality = matchedMunicipality;
                _isLoadingMunicipalities = false;
              });

              if (_client!.municipality != null) {
                setState(() => _isLoadingBarangays = true);
                await _loadBarangays(_client!.municipality!);
                if (mounted && _client!.barangay != null && _barangays.isNotEmpty) {
                  try {
                    final foundBarangay = _barangays.firstWhere(
                      (b) => b.barangay == _client!.barangay,
                    );
                    setState(() => _selectedBarangay = foundBarangay);
                  } catch (_) {
                    // No match — leave null rather than selecting wrong barangay
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[EditClientPage] Error loading location data in background: $e');
      if (mounted) {
        setState(() {
          _isLoadingProvinces = false;
          _isLoadingMunicipalities = false;
          _isLoadingBarangays = false;
        });
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
      debugPrint('[EditClientPage] Error loading barangays: $e');
      if (mounted) setState(() => _isLoadingBarangays = false);
    }
  }

  void _populateFormFields() {
    if (_client == null) return;

    _firstNameController.text = _client!.firstName;
    _middleNameController.text = _client!.middleName ?? '';
    _lastNameController.text = _client!.lastName;
    _birthDate = _client!.birthDate;

    _emailController.text = _client!.email ?? '';
    _phoneController.text = _client!.phone ?? '';
    _facebookController.text = _client!.facebookLink ?? '';

    _agencyNameController.text = _client!.agencyName ?? '';
    _departmentController.text = _client!.department ?? '';
    _positionController.text = _client!.position ?? '';
    _employmentStatusController.text = _client!.employmentStatus ?? '';
    _payrollDateController.text = _client!.payrollDate ?? '';
    _tenureController.text = _client!.tenure?.toString() ?? '';

    _productType = _getProductTypeLabel(_client!.productType);
    _pensionType = _getPensionTypeLabel(_client!.pensionType);
    _marketType = _client!.marketType != null ? _getMarketTypeLabel(_client!.marketType!) : 'Residential';
    _clientType = _client!.clientType.name.toUpperCase();
    _loanType = _client!.loanTypeDisplay;

    if (_client!.region != null && _client!.region!.isNotEmpty && _regions.isNotEmpty) {
      try {
        _selectedRegion = _regions.firstWhere(
          (r) => r.name == _client!.region || r.code == _client!.region,
        );
      } catch (_) {
        // No match — leave null rather than selecting wrong region
      }
    }

    _panController.text = _client!.pan ?? '';
    _remarksController.text = _client!.remarks ?? '';
  }

  String _getProductTypeLabel(ProductType type) {
    switch (type) {
      case ProductType.bfpActive: return 'BFP ACTIVE';
      case ProductType.bfpPension: return 'BFP PENSION';
      case ProductType.pnpPension: return 'PNP PENSION';
      case ProductType.napolcom: return 'NAPOLCOM';
      case ProductType.bfpStp: return 'BFP STP';
    }
  }

  String _getPensionTypeLabel(PensionType type) {
    switch (type) {
      case PensionType.pnpRetireeOptional: return 'PNP - RETIREE OPTIONAL';
      case PensionType.pnpRetireeCompulsory: return 'PNP - RETIREE COMPULSORY';
      case PensionType.pnpRetiree: return 'PNP - RETIREE';
      case PensionType.bfpRetiree: return 'BFP - RETIREE';
      case PensionType.bfpStpRetiree: return 'BFP STP - RETIREE';
      case PensionType.pnpTransferree: return 'PNP - TRANSFEREE';
      case PensionType.bfpSurvivor: return 'BFP - SURVIVOR';
      case PensionType.pnpSurvivor: return 'PNP - SURVIVOR';
      case PensionType.pnpTppd: return 'PNP - TPPD';
      case PensionType.bfpTppd: return 'BFP - TPPD';
      case PensionType.pnpMinor: return 'PNP - MINOR';
      case PensionType.bfpMinor: return 'BFP - MINOR';
      case PensionType.pnpPosthumousMinor: return 'PNP - POSTHUMOUS MINOR';
      case PensionType.pnpPosthumousSpouse: return 'PNP - POSTHUMOUS SPOUSE';
      case PensionType.others: return 'OTHERS';
    }
  }

  String _getMarketTypeLabel(MarketType type) {
    switch (type) {
      case MarketType.virgin: return 'VIRGIN';
      case MarketType.existing: return 'EXISTING';
      case MarketType.fullyPaid: return 'FULLY PAID';
    }
  }

  ProductType _parseProductType(String value) {
    switch (value) {
      case 'BFP ACTIVE': return ProductType.bfpActive;
      case 'BFP PENSION': return ProductType.bfpPension;
      case 'PNP PENSION': return ProductType.pnpPension;
      case 'NAPOLCOM': return ProductType.napolcom;
      case 'BFP STP': return ProductType.bfpStp;
      default: return ProductType.bfpActive;
    }
  }

  PensionType _parsePensionType(String value) {
    switch (value) {
      case 'PNP - RETIREE OPTIONAL': return PensionType.pnpRetireeOptional;
      case 'PNP - RETIREE COMPULSORY': return PensionType.pnpRetireeCompulsory;
      case 'PNP - RETIREE': return PensionType.pnpRetiree;
      case 'BFP - RETIREE': return PensionType.bfpRetiree;
      case 'BFP STP - RETIREE': return PensionType.bfpStpRetiree;
      case 'PNP - TRANSFEREE': return PensionType.pnpTransferree;
      case 'BFP - SURVIVOR': return PensionType.bfpSurvivor;
      case 'PNP - SURVIVOR': return PensionType.pnpSurvivor;
      case 'PNP - TPPD': return PensionType.pnpTppd;
      case 'BFP - TPPD': return PensionType.bfpTppd;
      case 'PNP - MINOR': return PensionType.pnpMinor;
      case 'BFP - MINOR': return PensionType.bfpMinor;
      case 'PNP - POSTHUMOUS MINOR': return PensionType.pnpPosthumousMinor;
      case 'PNP - POSTHUMOUS SPOUSE': return PensionType.pnpPosthumousSpouse;
      case 'OTHERS': return PensionType.others;
      default: return PensionType.others;
    }
  }

  MarketType _parseMarketType(String value) {
    switch (value) {
      case 'VIRGIN': return MarketType.virgin;
      case 'EXISTING': return MarketType.existing;
      case 'FULLY PAID': return MarketType.fullyPaid;
      default: return MarketType.virgin;
    }
  }

  ClientType _parseClientType(String value) {
    switch (value.toLowerCase()) {
      case 'potential': return ClientType.potential;
      case 'existing': return ClientType.existing;
      default: return ClientType.potential;
    }
  }

  LoanType? _parseLoanType(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toUpperCase()) {
      case 'NEW': return LoanType.newLoan;
      case 'ADDITIONAL': return LoanType.additional;
      case 'RENEWAL': return LoanType.renewal;
      case 'PRETERM': return LoanType.preterm;
      default: return null;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      HapticUtils.error();
      if (mounted) AppNotification.showError(context, 'Please fix the errors before saving');
      return;
    }

    HapticUtils.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final updatedClient = Client(
        id: widget.clientId,
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        facebookLink: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
        agencyName: _agencyNameController.text.trim().isEmpty ? null : _agencyNameController.text.trim(),
        department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
        employmentStatus: _employmentStatusController.text.trim().isEmpty ? null : _employmentStatusController.text.trim(),
        payrollDate: _payrollDateController.text.trim().isEmpty ? null : _payrollDateController.text.trim(),
        tenure: _tenureController.text.trim().isEmpty ? null : int.tryParse(_tenureController.text.trim()),
        birthDate: _birthDate,
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        productType: _parseProductType(_productType),
        pensionType: _parsePensionType(_pensionType),
        loanType: _parseLoanType(_loanType),
        marketType: _parseMarketType(_marketType),
        clientType: _parseClientType(_clientType),
        pan: _panController.text.trim().isEmpty ? null : _panController.text.trim(),
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

      final mutationService = ref.read(clientMutationServiceProvider);
      final result = await mutationService.updateClient(updatedClient);

      if (mounted) {
        switch (result) {
          case ClientMutationResult.success:
            AppNotification.showSuccess(context, 'Client updated successfully');
          case ClientMutationResult.requiresApproval:
            AppNotification.showSuccess(context, 'Client edit submitted for approval');
          case ClientMutationResult.queued:
            AppNotification.showWarning(context, 'Offline: Changes will sync when connected');
        }
        context.pop(true);
      }
    } catch (e, stack) {
      debugPrint('[EditClientPage] Error: $e\n$stack');
      HapticUtils.error();
      if (mounted) AppNotification.showError(context, 'Failed to update client: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
          'Are you sure you want to delete ${_client?.firstName ?? ''} ${_client?.lastName ?? ''}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    HapticUtils.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final mutationService = ref.read(clientMutationServiceProvider);
      final result = await mutationService.deleteClient(widget.clientId);

      if (mounted) {
        switch (result) {
          case ClientMutationResult.success:
            AppNotification.showSuccess(context, 'Client deleted');
            context.pop(true);
          case ClientMutationResult.requiresApproval:
            AppNotification.showSuccess(context, 'Client deletion submitted for approval');
            context.pop(true);
          case ClientMutationResult.queued:
            AppNotification.showSuccess(context, 'Client deleted (will sync when online)');
            context.pop(true);
        }
      }
    } catch (e) {
      debugPrint('[EditClientPage] Delete error: $e');
      HapticUtils.error();
      if (mounted) AppNotification.showError(context, 'Failed to delete client: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleSection(String section) {
    HapticUtils.lightImpact();
    setState(() => _expandedSections[section] = !_expandedSections[section]!);
  }

  void _showNotFoundError() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Client Not Found'),
        content: const Text('The client could not be found.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message, Object error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(message),
        content: Text('Error: ${error.toString()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatCreatedAt() {
    if (_client?.createdAt == null) return '';
    final date = _client!.createdAt!;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Created ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int? _calculateAge() {
    if (_birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month || (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Edit Client')),
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
    final saveLabel = role == UserRole.admin ? 'Save Changes' : 'Submit for Approval';
    final createdAtText = _formatCreatedAt();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Client'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _handleDelete,
            icon: const Icon(LucideIcons.trash2),
            tooltip: 'Delete client',
            color: Colors.red,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            if (createdAtText.isNotEmpty) ...[
              Text(
                createdAtText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
            ],

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

            // Contact Section
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            saveLabel,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
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

    final age = _calculateAge();

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
                validator: (value) => value?.trim().isEmpty == true ? 'Required' : null,
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
                validator: (value) => value?.trim().isEmpty == true ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ?? DateTime(1970),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _birthDate = picked);
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
            ),
            if (age != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(
                    '$age years',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
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

        DropdownButtonFormField<PsgcRegion>(
          value: _selectedRegion,
          decoration: InputDecoration(
            labelText: 'Region *',
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: _regions.isEmpty
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
          ),
          items: _regions.map((region) => DropdownMenuItem<PsgcRegion>(value: region, child: Text(region.name))).toList(),
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
                if (mounted) setState(() { _provinces = provinces; _isLoadingProvinces = false; });
              } catch (e) {
                if (mounted) { setState(() => _isLoadingProvinces = false); _showErrorDialog('Failed to load provinces', e); }
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
              suffixIcon: _isLoadingProvinces ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
              hintText: _selectedRegion == null ? 'Select region first' : null,
            ),
            items: _provinces.isEmpty && _selectedRegion != null && !_isLoadingProvinces
                ? [const DropdownMenuItem<PsgcProvince>(value: null, enabled: false, child: Text('No provinces available', style: TextStyle(color: Colors.grey)))]
                : _provinces.map((p) => DropdownMenuItem<PsgcProvince>(value: p, child: Text(p.name))).toList(),
            onChanged: _selectedRegion == null ? null : (province) async {
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
                  if (mounted) setState(() { _municipalities = municipalities; _isLoadingMunicipalities = false; });
                } catch (e) {
                  if (mounted) { setState(() => _isLoadingMunicipalities = false); _showErrorDialog('Failed to load municipalities', e); }
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
              suffixIcon: _isLoadingMunicipalities ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
              hintText: _selectedProvince == null ? 'Select province first' : null,
            ),
            items: _municipalities.isEmpty && _selectedProvince != null && !_isLoadingMunicipalities
                ? [const DropdownMenuItem<PsgcMunicipality>(value: null, enabled: false, child: Text('No municipalities available', style: TextStyle(color: Colors.grey)))]
                : _municipalities.map((m) => DropdownMenuItem<PsgcMunicipality>(value: m, child: Text(m.displayName))).toList(),
            onChanged: _selectedProvince == null ? null : (municipality) async {
              setState(() {
                _selectedMunicipality = municipality;
                _selectedBarangay = null;
                _barangays = [];
                _isLoadingBarangays = municipality != null;
              });
              if (municipality != null) await _loadBarangays(municipality.name);
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
              suffixIcon: _isLoadingBarangays ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
              hintText: _selectedMunicipality == null ? 'Select municipality first' : null,
            ),
            items: _barangays.isEmpty && _selectedMunicipality != null && !_isLoadingBarangays
                ? [const DropdownMenuItem<PsgcBarangay>(value: null, enabled: false, child: Text('No barangays available', style: TextStyle(color: Colors.grey)))]
                : _barangays.map((b) => DropdownMenuItem<PsgcBarangay>(value: b, child: Text(b.barangay ?? 'Unknown'))).toList(),
            onChanged: _selectedMunicipality == null ? null : (barangay) {
              HapticUtils.lightImpact();
              setState(() => _selectedBarangay = barangay);
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
                decoration: const InputDecoration(labelText: 'Agency Name', border: OutlineInputBorder(), isDense: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder(), isDense: true),
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
                decoration: const InputDecoration(labelText: 'Position', border: OutlineInputBorder(), isDense: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _employmentStatusController,
                decoration: const InputDecoration(labelText: 'Employment Status', border: OutlineInputBorder(), isDense: true),
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
                decoration: const InputDecoration(labelText: 'Payroll Date', hintText: 'YYYY-MM-DD', border: OutlineInputBorder(), isDense: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _tenureController,
                decoration: const InputDecoration(labelText: 'Tenure (months)', border: OutlineInputBorder(), isDense: true),
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
        const Text('Client Type', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ClientTypeButton(
                label: 'Potential',
                isSelected: _clientType == 'POTENTIAL',
                colorScheme: colorScheme,
                onTap: () { HapticUtils.selectionClick(); setState(() => _clientType = 'POTENTIAL'); },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ClientTypeButton(
                label: 'Existing',
                isSelected: _clientType == 'EXISTING',
                colorScheme: colorScheme,
                onTap: () { HapticUtils.selectionClick(); setState(() => _clientType = 'EXISTING'); },
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
                  const Text('Product Type', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _productType,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                    items: const ['BFP ACTIVE', 'BFP PENSION', 'PNP PENSION', 'NAPOLCOM', 'BFP STP']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (value) { if (value != null) { HapticUtils.lightImpact(); setState(() => _productType = value); } },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pension Type', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _pensionType,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                    items: ['SSS', 'GSIS', 'Private', 'None']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (value) { if (value != null) { HapticUtils.lightImpact(); setState(() => _pensionType = value); } },
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
          decoration: const InputDecoration(labelText: 'Market Type', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
          items: ['Residential', 'Commercial', 'Industrial']
              .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (value) { if (value != null) { HapticUtils.lightImpact(); setState(() => _marketType = value); } },
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _loanType,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Loan Type', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
          items: const ['NEW', 'ADDITIONAL', 'RENEWAL', 'PRETERM']
              .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (value) { if (value != null) { HapticUtils.lightImpact(); setState(() => _loanType = value); } },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _panController,
          decoration: const InputDecoration(labelText: 'PAN', border: OutlineInputBorder(), isDense: true),
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
          border: Border.all(color: isSelected ? colorScheme.primary : Colors.grey[300]!),
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
