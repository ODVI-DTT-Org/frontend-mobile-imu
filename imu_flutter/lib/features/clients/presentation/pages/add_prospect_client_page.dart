import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../shared/providers/app_providers.dart';
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

  String? _selectedAgency;
  String? _selectedEmploymentStatus;
  String? _selectedPayrollDate;
  String _selectedProductType = 'SSS Pensioner';
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
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    HapticUtils.mediumImpact();

    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Saving client...',
      operation: () async {
        final clientId = DateTime.now().millisecondsSinceEpoch.toString();
        final now = DateTime.now();

        // Create client data
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
          'clientType': 'potential',
          'marketType': _selectedMarketType.toLowerCase(),
          'productType': _selectedProductType.toLowerCase().replaceAll(' ', ''),
          'pensionType': _selectedPensionType.toLowerCase(),
          'addresses': [
            {
              'id': '${clientId}_addr_1',
              'street': _streetController.text.trim(),
              'barangay': _barangayController.text.trim(),
              'city': _cityController.text.trim(),
              'province': _provinceController.text.trim(),
              'isPrimary': true,
            }
          ],
          'phoneNumbers': [
            {
              'id': '${clientId}_phone_1',
              'number': _contactNumberController.text.trim(),
              'label': 'Mobile',
              'isPrimary': true,
            }
          ],
          'touchpoints': [],
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };

        // Save to Hive
        await _hiveService.saveClient(clientId, clientData);

        // PowerSync will handle sync automatically via the repository
        ref.invalidate(clientsProvider);
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
        const SnackBar(
          content: Text('Prospect client added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true);
    }
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
            // Header with breadcrumb
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 10),
                  const Text(
                    'My Clients > Add Prospect Client',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product & Pension Type
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
                                  items: ['SSS Pensioner', 'GSIS Pensioner', 'Private']
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
                                        if (value == 'SSS Pensioner') {
                                          _selectedPensionType = 'SSS';
                                        } else if (value == 'GSIS Pensioner') {
                                          _selectedPensionType = 'GSIS';
                                        }
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
                      const SizedBox(height: 16),

                      // Name row
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

                      // Agency Name
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
                          if (value == null) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Department & Position
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

                      // Employment Status & Payroll
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

                      // Tenure & Birth Date
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
                                  decoration: _inputDecoration.copyWith(hintText: 'Years of service'),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Birth Date'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _selectBirthDate,
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      decoration: _inputDecoration.copyWith(
                                        hintText: _selectedBirthDate != null
                                            ? '${_selectedBirthDate!.month}/${_selectedBirthDate!.day}/${_selectedBirthDate!.year}'
                                            : 'Select date',
                                        suffixIcon: const Icon(LucideIcons.calendar),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Contact Number
                      _buildLabel('Contact Number *'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contactNumberController,
                        decoration: _inputDecoration.copyWith(hintText: '+63 XXX XXX XXXX'),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email & Facebook
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Email'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: _inputDecoration.copyWith(hintText: 'email@example.com'),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Facebook'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _facebookController,
                                  decoration: _inputDecoration.copyWith(hintText: 'Profile URL'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Address
                      _buildLabel('Address'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _streetController,
                        decoration: _inputDecoration.copyWith(hintText: 'Street'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _barangayController,
                              decoration: _inputDecoration.copyWith(hintText: 'Barangay'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: _inputDecoration.copyWith(hintText: 'City'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _provinceController,
                              decoration: _inputDecoration.copyWith(hintText: 'Province'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Remarks
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
                          : const Text('SAVE'),
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
}
