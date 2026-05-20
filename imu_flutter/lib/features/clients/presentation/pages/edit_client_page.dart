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
  final _payrollDateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _panController = TextEditingController();
  final _remarksController = TextEditingController();
  final _streetController = TextEditingController();

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
  String _pensionType = 'PNP - RETIREE OPTIONAL';
  String _marketType = 'VIRGIN';
  String _clientType = 'POTENTIAL';
  String? _loanType;
  DateTime? _birthDate;

  // Wizard navigation
  int _currentStep = 0;
  final Set<int> _completedSteps = {};
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();
  final _step5Key = GlobalKey<FormState>();

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
    _payrollDateController.dispose();
    _tenureController.dispose();
    _panController.dispose();
    _remarksController.dispose();
    _streetController.dispose();
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
              matchedProvince = provinces.firstWhere((p) => p.name == _client!.province);
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
            final municipalities =
                await psgcRepository.getMunicipalitiesByProvince(_client!.province!);
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
                    // No match — leave null
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
    _payrollDateController.text = _client!.payrollDate ?? '';
    _tenureController.text = _client!.tenure?.toString() ?? '';

    _productType = _getProductTypeLabel(_client!.productType);
    _pensionType = _getPensionTypeLabel(_client!.pensionType);
    _marketType = _client!.marketType != null
        ? _getMarketTypeLabel(_client!.marketType!)
        : 'VIRGIN';
    _clientType = _client!.clientType.name.toUpperCase();
    _loanType = _client!.loanTypeDisplay;

    if (_client!.region != null && _client!.region!.isNotEmpty && _regions.isNotEmpty) {
      try {
        _selectedRegion = _regions.firstWhere(
          (r) => r.name == _client!.region || r.code == _client!.region,
        );
      } catch (_) {
        // No match — leave null
      }
    }

    _panController.text = _client!.pan ?? '';
    _remarksController.text = _client!.remarks ?? '';
    _streetController.text = _client!.street ?? '';

    // In edit mode all steps start completed — user can jump freely
    setState(() => _completedSteps.addAll({0, 1, 2, 3, 4}));
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
      case MarketType.bfpActive: return 'BFP ACTIVE';
      case MarketType.bfpPension: return 'BFP PENSION';
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
    switch (value.toUpperCase()) {
      case 'POTENTIAL': return ClientType.potential;
      case 'EXISTING': return ClientType.existing;
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
    final allValid = [_step1Key, _step2Key, _step3Key, _step4Key, _step5Key]
        .every((key) => key.currentState?.validate() ?? false);
    if (!allValid) {
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
        tableFullAddress: _client?.tableFullAddress,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        facebookLink: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
        agencyName: _agencyNameController.text.trim().isEmpty ? null : _agencyNameController.text.trim(),
        department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
        employmentStatus: _client?.employmentStatus,
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
        street: _streetController.text.trim().isEmpty
            ? null
            : _streetController.text.trim(),
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
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
      age--;
    }
    return age;
  }

  // ── Wizard navigation ──────────────────────────────────────────────────────

  List<GlobalKey<FormState>> get _stepKeys =>
      [_step1Key, _step2Key, _step3Key, _step4Key, _step5Key];

  void _goToStep(int step) {
    HapticUtils.lightImpact();
    setState(() => _currentStep = step);
  }

  void _nextStep() {
    if (!_stepKeys[_currentStep].currentState!.validate()) {
      HapticUtils.error();
      return;
    }
    HapticUtils.lightImpact();
    setState(() {
      _completedSteps.add(_currentStep);
      _currentStep++;
    });
  }

  void _prevStep() {
    HapticUtils.lightImpact();
    setState(() => _currentStep--);
  }

  // ── Shared UI ──────────────────────────────────────────────────────────────

  Widget _buildStepPillsRow() {
    const labels = ['👤 Personal', '📞 Contact', '📍 Location', '💼 Work', '💳 Product'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: List.generate(5, (i) {
            final isDone = _completedSteps.contains(i);
            final isActive = _currentStep == i;
            return GestureDetector(
              onTap: () => _goToStep(i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF6366F1)
                      : isDone
                          ? const Color(0xFFEDE9FE)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isDone ? '✓ ${labels[i].substring(3)}' : labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? Colors.white
                        : isDone
                            ? const Color(0xFF5B21B6)
                            : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStepNavBar(String saveLabel) {
    const nextLabels = ['Contact', 'Location', 'Work', 'Product'];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('← Back', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (_currentStep < 4)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Next: ${nextLabels[_currentStep]} →',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentStep == 4)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(saveLabel,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Step content builders ──────────────────────────────────────────────────

  Widget _buildStep1Personal() {
    final age = _calculateAge();
    final createdAtText = _formatCreatedAt();

    return Form(
      key: _step1Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (createdAtText.isNotEmpty) ...[
              Text(createdAtText,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 12),
            ],
            const Text('Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _middleNameController,
              decoration: const InputDecoration(
                labelText: 'Middle Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
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
                        suffixIcon: Icon(LucideIcons.calendar, size: 20),
                      ),
                      child: Text(
                        _birthDate != null
                            ? '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}'
                            : 'Select birth date',
                        style: TextStyle(
                          color: _birthDate != null ? Colors.black87 : Colors.grey,
                        ),
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
                      ),
                      child: Text('$age years',
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            const Text('Client Type *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ClientTypeButton(
                    label: 'Potential',
                    isSelected: _clientType == 'POTENTIAL',
                    colorScheme: Theme.of(context).colorScheme,
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
                    colorScheme: Theme.of(context).colorScheme,
                    onTap: () {
                      HapticUtils.selectionClick();
                      setState(() => _clientType = 'EXISTING');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Contact() {
    return Form(
      key: _step2Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: '+63 912 345 6789',
                prefixIcon: Icon(LucideIcons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'email@example.com',
                prefixIcon: Icon(LucideIcons.mail),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _facebookController,
              decoration: const InputDecoration(
                labelText: 'Facebook Profile',
                hintText: 'Facebook profile URL or name',
                prefixIcon: Icon(LucideIcons.facebook),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Location() {
    return Form(
      key: _step3Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<PsgcRegion>(
              value: _selectedRegion,
              decoration: InputDecoration(
                labelText: 'Region *',
                border: const OutlineInputBorder(),
                suffixIcon: _regions.isEmpty
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
              ),
              items: _regions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                  .toList(),
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
                    final provinces =
                        await psgcRepository.getProvincesByRegion(region.name);
                    if (mounted) {
                      setState(() {
                        _provinces = provinces;
                        _isLoadingProvinces = false;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoadingProvinces = false);
                      _showErrorDialog('Failed to load provinces', e);
                    }
                  }
                }
              },
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: _selectedRegion == null || _isLoadingProvinces,
              child: DropdownButtonFormField<PsgcProvince>(
                value: _selectedProvince,
                decoration: InputDecoration(
                  labelText: 'Province *',
                  border: const OutlineInputBorder(),
                  filled: _selectedRegion == null,
                  fillColor: _selectedRegion == null ? Colors.grey.shade100 : null,
                  hintText: _selectedRegion == null ? 'Select region first' : null,
                  suffixIcon: _isLoadingProvinces
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                ),
                items: _provinces.isEmpty && _selectedRegion != null && !_isLoadingProvinces
                    ? [const DropdownMenuItem<PsgcProvince>(
                        value: null, enabled: false,
                        child: Text('No provinces available',
                            style: TextStyle(color: Colors.grey)))]
                    : _provinces
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
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
                            final municipalities = await psgcRepository
                                .getMunicipalitiesByProvince(province.name);
                            if (mounted) {
                              setState(() {
                                _municipalities = municipalities;
                                _isLoadingMunicipalities = false;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isLoadingMunicipalities = false);
                              _showErrorDialog('Failed to load municipalities', e);
                            }
                          }
                        }
                      },
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: _selectedProvince == null || _isLoadingMunicipalities,
              child: DropdownButtonFormField<PsgcMunicipality>(
                value: _selectedMunicipality,
                decoration: InputDecoration(
                  labelText: 'Municipality / City *',
                  border: const OutlineInputBorder(),
                  filled: _selectedProvince == null,
                  fillColor: _selectedProvince == null ? Colors.grey.shade100 : null,
                  hintText: _selectedProvince == null ? 'Select province first' : null,
                  suffixIcon: _isLoadingMunicipalities
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                ),
                items: _municipalities.isEmpty &&
                        _selectedProvince != null &&
                        !_isLoadingMunicipalities
                    ? [const DropdownMenuItem<PsgcMunicipality>(
                        value: null, enabled: false,
                        child: Text('No municipalities available',
                            style: TextStyle(color: Colors.grey)))]
                    : _municipalities
                        .map((m) =>
                            DropdownMenuItem(value: m, child: Text(m.displayName)))
                        .toList(),
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
                validator: (v) => v == null ? 'Required' : null,
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
                  filled: _selectedMunicipality == null,
                  fillColor:
                      _selectedMunicipality == null ? Colors.grey.shade100 : null,
                  hintText:
                      _selectedMunicipality == null ? 'Select municipality first' : null,
                  suffixIcon: _isLoadingBarangays
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                ),
                items: _barangays.isEmpty &&
                        _selectedMunicipality != null &&
                        !_isLoadingBarangays
                    ? [const DropdownMenuItem<PsgcBarangay>(
                        value: null, enabled: false,
                        child: Text('No barangays available',
                            style: TextStyle(color: Colors.grey)))]
                    : _barangays
                        .map((b) => DropdownMenuItem(
                            value: b, child: Text(b.barangay ?? 'Unknown')))
                        .toList(),
                onChanged: _selectedMunicipality == null
                    ? null
                    : (barangay) {
                        HapticUtils.lightImpact();
                        setState(() => _selectedBarangay = barangay);
                      },
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                hintText: 'House/Unit/Lot number, Street name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.mapPin),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Work() {
    return Form(
      key: _step4Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Work & Employment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _agencyNameController,
              decoration: const InputDecoration(
                labelText: 'Agency Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
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
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _panController,
              decoration: const InputDecoration(
                labelText: 'PAN (Pension Account No.)',
                border: OutlineInputBorder(),
              ),
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
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep5ProductNotes() {
    return Form(
      key: _step5Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Product & Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _productType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Product Type *',
                border: OutlineInputBorder(),
              ),
              items: const ['BFP ACTIVE', 'BFP PENSION', 'BFP STP', 'NAPOLCOM', 'PNP PENSION']
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) {
                if (v != null) { HapticUtils.lightImpact(); setState(() => _productType = v); }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _pensionType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pension Type *',
                border: OutlineInputBorder(),
              ),
              items: const [
                'PNP - RETIREE OPTIONAL', 'PNP - RETIREE COMPULSORY', 'PNP - RETIREE',
                'BFP - RETIREE', 'BFP STP - RETIREE', 'PNP - TRANSFEREE',
                'BFP - SURVIVOR', 'PNP - SURVIVOR', 'PNP - TPPD', 'BFP - TPPD',
                'PNP - MINOR', 'BFP - MINOR', 'PNP - POSTHUMOUS MINOR',
                'PNP - POSTHUMOUS SPOUSE', 'OTHERS',
              ]
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) {
                if (v != null) { HapticUtils.lightImpact(); setState(() => _pensionType = v); }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _marketType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Market Type *',
                border: OutlineInputBorder(),
              ),
              items: const ['VIRGIN', 'EXISTING', 'FULLY PAID']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) { HapticUtils.lightImpact(); setState(() => _marketType = v); }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _loanType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Loan Type',
                border: OutlineInputBorder(),
              ),
              items: const ['NEW', 'ADDITIONAL', 'RENEWAL', 'PRETERM']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) { HapticUtils.lightImpact(); setState(() => _loanType = v); }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks / Notes',
                hintText: 'Add any notes about this client...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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

    final role = ref.watch(currentUserRoleProvider);
    final saveLabel = role == UserRole.admin ? 'Save Changes' : 'Submit for Approval';

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
      body: Column(
        children: [
          _buildStepPillsRow(),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep1Personal(),
                _buildStep2Contact(),
                _buildStep3Location(),
                _buildStep4Work(),
                _buildStep5ProductNotes(),
              ],
            ),
          ),
          _buildStepNavBar(saveLabel),
        ],
      ),
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
