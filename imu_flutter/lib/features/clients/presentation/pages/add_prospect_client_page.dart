import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../services/api/psgc_api_service.dart' show PsgcRegion, PsgcProvince, PsgcMunicipality, PsgcBarangay, psgcApiServiceProvider;
import '../../../../shared/providers/app_providers.dart' show assignedClientsProvider, isOnlineProvider, clientApiServiceProvider;
import '../../../../shared/utils/loading_helper.dart';
import '../../data/models/client_model.dart';

class AddProspectClientPage extends ConsumerStatefulWidget {
  const AddProspectClientPage({super.key});

  @override
  ConsumerState<AddProspectClientPage> createState() => _AddProspectClientPageState();
}

class _AddProspectClientPageState extends ConsumerState<AddProspectClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _hiveService = HiveService();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();
  final _tenureController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _remarksController = TextEditingController();

  // Additional fields for complete client data
  final _emailController = TextEditingController();
  final _facebookController = TextEditingController();
  final _streetController = TextEditingController();
  final _barangayController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _panController = TextEditingController();

  // PSGC Location dropdowns
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedMunicipality;
  String? _selectedBarangay;
  final _barangaySearchController = TextEditingController();

  // PSGC Data
  List<PsgcRegion> _regions = [];
  List<PsgcProvince> _provinces = [];
  List<PsgcMunicipality> _municipalities = [];
  List<PsgcBarangay> _barangays = [];
  List<String> _barangayNames = [];
  bool _isLoadingPsgc = false;

  String? _selectedAgency;
  String? _selectedEmploymentStatus;
  String? _selectedPayrollDate;
  String _selectedProductType = 'BFP ACTIVE';
  String _selectedPensionType = 'SSS';
  String _selectedMarketType = 'Residential';
  DateTime? _selectedBirthDate;
  bool _isSaving = false;

  final List<String> _agencies = [
    'Philippine National Police (PNP)',
    'Bureau of Fire Protection (BFP)',
    'Bureau of Jail Management and Penology (BJMP)',
    'Armed Forces of the Philippines (AFP)',
    'Philippine Coast Guard (PCG)',
    'Other',
  ];

  final List<String> _employmentStatuses = [
    'Permanent',
    'Casual',
    'JO (Job Order)',
  ];

  final List<String> _payrollDates = [
    '30 / 15',
    '30 / 10',
    '25',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _tenureController.dispose();
    _contactNumberController.dispose();
    _remarksController.dispose();
    _emailController.dispose();
    _facebookController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _panController.dispose();
    _barangaySearchController.dispose();
    super.dispose();
  }

  // PSGC Data Loading Methods
  Future<void> _loadPsgcRegions() async {
    setState(() => _isLoadingPsgc = true);
    try {
      final service = ref.read(psgcApiServiceProvider);
      _regions = await service.getRegions();
    } catch (e) {
      debugPrint('Failed to load regions: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPsgc = false);
    }
  }

  Future<void> _loadPsgcProvinces(String region) async {
    setState(() => _isLoadingPsgc = true);
    try {
      final service = ref.read(psgcApiServiceProvider);
      _provinces = await service.getProvinces(region: region);
      _selectedProvince = null;
      _selectedMunicipality = null;
      _selectedBarangay = null;
      _municipalities = [];
      _barangays = [];
      _barangayNames = [];
    } catch (e) {
      debugPrint('Failed to load provinces: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPsgc = false);
    }
  }

  Future<void> _loadPsgcMunicipalities(String province) async {
    setState(() => _isLoadingPsgc = true);
    try {
      final service = ref.read(psgcApiServiceProvider);
      _municipalities = await service.getMunicipalities(
        region: _selectedRegion,
        province: province,
      );
      _selectedMunicipality = null;
      _selectedBarangay = null;
      _barangays = [];
      _barangayNames = [];
    } catch (e) {
      debugPrint('Failed to load municipalities: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPsgc = false);
    }
  }

  Future<void> _loadPsgcBarangays(String municipality) async {
    setState(() => _isLoadingPsgc = true);
    try {
      final service = ref.read(psgcApiServiceProvider);
      final result = await service.getBarangays(
        region: _selectedRegion,
        province: _selectedProvince,
        municipality: municipality,
        perPage: 500,
      );
      _barangays = result['items'] as List<PsgcBarangay>;
      _barangayNames = _barangays.map((b) => b.barangay).toList();
    } catch (e) {
      debugPrint('Failed to load barangays: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPsgc = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPsgcRegions();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    HapticUtils.mediumImpact();

    final isOnline = ref.read(isOnlineProvider);

    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Saving client...',
      operation: () async {
        if (isOnline) {
          // Online mode: Use backend API
          final clientApi = ref.read(clientApiServiceProvider);

          // Create Client object
          final now = DateTime.now();
          final client = Client(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            firstName: _firstNameController.text.trim(),
            middleName: _middleNameController.text.trim().isEmpty
                ? null
                : _middleNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            agencyName: _selectedAgency,
            department: _departmentController.text.trim().isEmpty
                ? null
                : _departmentController.text.trim(),
            position: _positionController.text.trim().isEmpty
                ? null
                : _positionController.text.trim(),
            employmentStatus: _selectedEmploymentStatus,
            payrollDate: _selectedPayrollDate,
            tenure: _tenureController.text.trim().isEmpty
                ? null
                : int.tryParse(_tenureController.text.trim()),
            birthDate: _selectedBirthDate,
            phone: _contactNumberController.text.trim().isEmpty
                ? null
                : _contactNumberController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            facebookLink: _facebookController.text.trim().isEmpty
                ? null
                : _facebookController.text.trim(),
            remarks: _remarksController.text.trim().isEmpty
                ? null
                : _remarksController.text.trim(),
            pan: _panController.text.trim().isEmpty
                ? null
                : _panController.text.trim(),
            region: _selectedRegion,
            province: _selectedProvince,
            municipality: _selectedMunicipality,
            barangay: _selectedBarangay,
            clientType: ClientType.potential,
            marketType: _parseMarketType(_selectedMarketType),
            productType: _parseProductType(_selectedProductType),
            pensionType: _parsePensionType(_selectedPensionType),
            touchpoints: [],
            createdAt: now,
            updatedAt: now,
            isStarred: false,
            loanReleased: false,
          );

          // Create client via API
          final createdClient = await clientApi.createClient(client);
          if (createdClient == null || createdClient.id == null) {
            throw Exception('Failed to create client');
          }

          // Add address via API
          final street = _streetController.text.trim();
          final barangayInput = _barangayController.text.trim();
          final cityInput = _cityController.text.trim();
          final provinceInput = _provinceController.text.trim();

          final address = Address(
            id: '${createdClient.id}_addr_1',
            type: AddressType.home,
            street: street,
            barangay: _selectedBarangay ?? (barangayInput.isEmpty ? null : barangayInput),
            city: _selectedMunicipality ?? cityInput,
            province: _selectedProvince ?? (provinceInput.isEmpty ? null : provinceInput),
            isPrimary: true,
          );
          await clientApi.addAddress(createdClient.id!, address);

          // Add phone number via API
          final phone = PhoneNumber(
            id: '${createdClient.id}_phone_1',
            type: PhoneType.mobile,
            number: _contactNumberController.text.trim(),
            label: 'Mobile',
            isPrimary: true,
          );
          await clientApi.addPhoneNumber(createdClient.id!, phone);
        } else {
          // Offline mode: Save to Hive
          final clientId = DateTime.now().millisecondsSinceEpoch.toString();
          final now = DateTime.now();

          final clientData = {
            'id': clientId,
            'firstName': _firstNameController.text.trim(),
            'middleName': _middleNameController.text.trim().isEmpty
                ? null
                : _middleNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'agencyName': _selectedAgency,
            'department': _departmentController.text.trim().isEmpty
                ? null
                : _departmentController.text.trim(),
            'position': _positionController.text.trim().isEmpty
                ? null
                : _positionController.text.trim(),
            'employmentStatus': _selectedEmploymentStatus,
            'payrollDate': _selectedPayrollDate,
            'tenure': _tenureController.text.trim().isEmpty
                ? null
                : int.tryParse(_tenureController.text.trim()),
            'birthDate': _selectedBirthDate?.toIso8601String(),
            'contactNumber': _contactNumberController.text.trim(),
            'email': _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            'facebookLink': _facebookController.text.trim().isEmpty
                ? null
                : _facebookController.text.trim(),
            'remarks': _remarksController.text.trim().isEmpty
                ? null
                : _remarksController.text.trim(),
            'pan': _panController.text.trim().isEmpty
                ? null
                : _panController.text.trim(),
            'region': _selectedRegion,
            'province': _selectedProvince,
            'municipality': _selectedMunicipality,
            'barangay': _selectedBarangay,
            'psgcId': null,
            'clientType': 'potential',
            'marketType': _selectedMarketType.toLowerCase(),
            'productType': _selectedProductType.toLowerCase().replaceAll(' ', ''),
            'pensionType': _selectedPensionType.toLowerCase(),
            'addresses': [
              {
                'id': '${clientId}_addr_1',
                'type': 'home',
                'street': _streetController.text.trim(),
                'barangay': _selectedBarangay ?? _barangayController.text.trim(),
                'city': _selectedMunicipality ?? _cityController.text.trim(),
                'province': _selectedProvince ?? _provinceController.text.trim(),
                'isPrimary': true,
              }
            ],
            'phoneNumbers': [
              {
                'id': '${clientId}_phone_1',
                'type': 'mobile',
                'number': _contactNumberController.text.trim(),
                'label': 'Mobile',
                'isPrimary': true,
              }
            ],
            'touchpoints': [],
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          };

          await _hiveService.saveClient(clientId, clientData);
        }

        // Refresh client list
        ref.invalidate(assignedClientsProvider);
      },
      onError: (e) {
        HapticUtils.error();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save client: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    // Success handling
    HapticUtils.success();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isOnline ? 'Client added successfully' : 'Client saved locally (will sync when online)'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true);
    }
  }

  ProductType _parseProductType(String value) {
    switch (value.toLowerCase()) {
      case 'bfp active':
        return ProductType.bfpActive;
      case 'bfp pension':
        return ProductType.bfpPension;
      case 'pnp pension':
        return ProductType.pnpPension;
      case 'napolcom':
        return ProductType.napolcom;
      case 'bfp stp':
        return ProductType.bfpStp;
      default:
        return ProductType.bfpActive;
    }
  }

  MarketType _parseMarketType(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'residential') {
      return MarketType.residential;
    } else if (normalized == 'commercial') {
      return MarketType.commercial;
    } else if (normalized == 'industrial') {
      return MarketType.industrial;
    }
    return MarketType.residential;
  }

  PensionType _parsePensionType(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'sss') {
      return PensionType.sss;
    } else if (normalized == 'gsis') {
      return PensionType.gsis;
    } else if (normalized == 'private') {
      return PensionType.private;
    } else if (normalized == 'none') {
      return PensionType.none;
    }
    return PensionType.none;
  }

  Future<void> _selectBirthDate() async {
    HapticUtils.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1970),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and centered title
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text(
                          '< Back',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add Prospect Client',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  children: [
                    // Product & Pension Type
                    _buildExpansionPanel(
                      title: 'Product & Pension Information',
                      isExpanded: true,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Product Type'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedProductType,
                                    decoration: _inputDecoration,
                                    items: ['BFP ACTIVE', 'BFP PENSION', 'PNP PENSION', 'NAPOLCOM', 'BFP STP']
                                        .map((type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(type),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        HapticUtils.lightImpact();
                                        setState(() {
                                          _selectedProductType = value;
                                          // No auto-set for pension type with new product types
                                        });
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
                                  _buildLabel('Pension Type'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedPensionType,
                                    decoration: _inputDecoration,
                                    items: ['SSS', 'GSIS', 'Private', 'None']
                                        .map((type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(type),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        HapticUtils.lightImpact();
                                        setState(() => _selectedPensionType = value);
                                      }
                                    },
                                  ),
                                ],
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
                                  _buildLabel('Market Type'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedMarketType,
                                    decoration: _inputDecoration,
                                    items: ['Residential', 'Commercial', 'Industrial']
                                        .map((type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(type),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        HapticUtils.lightImpact();
                                        setState(() => _selectedMarketType = value);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Personal Information
                    _buildExpansionPanel(
                      title: 'Personal Information',
                      isExpanded: false,
                      children: [
                        _buildLabel('Name *'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: _inputDecoration.copyWith(hintText: 'First Name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('or'),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration: _inputDecoration.copyWith(hintText: 'Last Name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _middleNameController,
                          decoration: _inputDecoration.copyWith(hintText: 'Middle Name'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Birth Date'),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _selectBirthDate,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _selectedBirthDate != null
                                                  ? '${_selectedBirthDate!.month}/${_selectedBirthDate!.day}/${_selectedBirthDate!.year}'
                                                  : 'Select Birth Date',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: _selectedBirthDate != null
                                                    ? Colors.black
                                                    : Colors.grey.shade400,
                                              ),
                                            ),
                                          ),
                                          const Icon(LucideIcons.calendar, size: 18, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Employment Information
                    _buildExpansionPanel(
                      title: 'Employment Information',
                      isExpanded: true,
                      children: [
                        _buildLabel('Agency Name *'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedAgency,
                          decoration: _inputDecoration.copyWith(
                            hintText: 'Select agency',
                            suffixIcon: const Icon(LucideIcons.chevronDown),
                          ),
                          items: _agencies
                              .map((agency) => DropdownMenuItem(
                                    value: agency,
                                    child: Text(agency),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            HapticUtils.lightImpact();
                            setState(() => _selectedAgency = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Department'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _departmentController,
                                    decoration: _inputDecoration.copyWith(hintText: 'Department'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Position'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _positionController,
                                    decoration: _inputDecoration.copyWith(hintText: 'Position'),
                                  ),
                                ],
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
                                  _buildLabel('Employment Status'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedEmploymentStatus,
                                    decoration: _inputDecoration.copyWith(
                                      hintText: 'Status',
                                      suffixIcon: const Icon(LucideIcons.chevronDown),
                                    ),
                                    items: _employmentStatuses
                                        .map((status) => DropdownMenuItem(
                                              value: status,
                                              child: Text(status),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      HapticUtils.lightImpact();
                                      setState(() => _selectedEmploymentStatus = value);
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
                                  _buildLabel('Payroll Date'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedPayrollDate,
                                    decoration: _inputDecoration.copyWith(
                                      hintText: 'Payroll',
                                      suffixIcon: const Icon(LucideIcons.calendarDays),
                                    ),
                                    items: _payrollDates
                                        .map((date) => DropdownMenuItem(
                                              value: date,
                                              child: Text(date),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      HapticUtils.lightImpact();
                                      setState(() => _selectedPayrollDate = value);
                                    },
                                  ),
                                ],
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
                                  _buildLabel('Tenure'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _tenureController,
                                    decoration: _inputDecoration.copyWith(hintText: 'Months'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Contact Information
                    _buildExpansionPanel(
                      title: 'Contact Information',
                      isExpanded: false,
                      children: [
                        _buildLabel('Contact Number *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _contactNumberController,
                          decoration: _inputDecoration.copyWith(hintText: 'Mobile number'),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Email'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration.copyWith(hintText: 'Email address'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Facebook Link'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _facebookController,
                          decoration: _inputDecoration.copyWith(hintText: 'Facebook profile URL'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Location (PSGC)
                    _buildExpansionPanel(
                      title: 'Location (PSGC)',
                      isExpanded: true,
                      children: [
                        _buildLabel('Region *'),
                        const SizedBox(height: 8),
                        _regions.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<String>(
                                value: _selectedRegion,
                                decoration: _inputDecoration.copyWith(
                                  hintText: 'Select Region',
                                  suffixIcon: const Icon(LucideIcons.chevronDown),
                                ),
                                items: _regions
                                    .map((region) => DropdownMenuItem(
                                          value: region.name,
                                          child: Text(region.name),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    HapticUtils.lightImpact();
                                    setState(() {
                                      _selectedRegion = value;
                                      _loadPsgcProvinces(value!);
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                        const SizedBox(height: 16),
                        _buildLabel('Province'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedProvince,
                          decoration: _inputDecoration.copyWith(
                            hintText: 'Select Province',
                            suffixIcon: const Icon(LucideIcons.chevronDown),
                          ),
                          items: _provinces
                              .map((province) => DropdownMenuItem(
                                    value: province.name,
                                    child: Text(province.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              HapticUtils.lightImpact();
                              setState(() {
                                _selectedProvince = value;
                                _loadPsgcMunicipalities(value!);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Municipality/City'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedMunicipality,
                          decoration: _inputDecoration.copyWith(
                            hintText: 'Select Municipality/City',
                            suffixIcon: const Icon(LucideIcons.chevronDown),
                          ),
                          items: _municipalities
                              .map((municipality) => DropdownMenuItem(
                                    value: municipality.name,
                                    child: Text('${municipality.name} (${municipality.kind})'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              HapticUtils.lightImpact();
                              setState(() {
                                _selectedMunicipality = value;
                                _loadPsgcBarangays(value!);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Barangay'),
                        const SizedBox(height: 8),
                        _barangays.isEmpty
                            ? const Text('Select municipality first', style: TextStyle(color: Colors.grey))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Autocomplete<String>(
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return _barangayNames.take(50).toList();
                                      }
                                      return _barangayNames
                                          .where((barangay) => barangay
                                              .toLowerCase()
                                              .contains(textEditingValue.text.toLowerCase()))
                                          .take(50)
                                          .toList();
                                    },
                                    onSelected: (String selection) {
                                      HapticUtils.lightImpact();
                                      setState(() {
                                        _selectedBarangay = selection;
                                      });
                                    },
                                  ),
                                  if (_selectedBarangay != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Selected: $_selectedBarangay',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                        const SizedBox(height: 16),
                        _buildLabel('Street Address'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _streetController,
                          decoration: _inputDecoration.copyWith(hintText: 'Street address'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Other Information
                    _buildExpansionPanel(
                      title: 'Other Information',
                      isExpanded: false,
                      children: [
                        _buildLabel('PAN'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _panController,
                          decoration: _inputDecoration.copyWith(hintText: 'PAN number'),
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Remarks'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _remarksController,
                          decoration: _inputDecoration.copyWith(hintText: 'Enter remarks'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.all(17),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 152,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('SUBMIT'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration get _inputDecoration => const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(),
      );

  Widget _buildLabel(String text) {
    return SizedBox(
      width: 82,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildExpansionPanel({
    required String title,
    required bool isExpanded,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              // Toggle expansion state
              // Note: This requires state management to actually work
              // For now, panels use fixed expansion state
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }
}
