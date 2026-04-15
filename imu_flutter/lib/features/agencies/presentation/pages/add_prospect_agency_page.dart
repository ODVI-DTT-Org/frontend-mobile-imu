import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../shared/utils/loading_helper.dart';
import 'agencies_page.dart';

class AddProspectAgencyPage extends ConsumerStatefulWidget {
  const AddProspectAgencyPage({super.key});

  @override
  ConsumerState<AddProspectAgencyPage> createState() => _AddProspectAgencyPageState();
}

class _AddProspectAgencyPageState extends ConsumerState<AddProspectAgencyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _remarksController = TextEditingController();

  String _selectedType = 'Government';
  AgencyStatus _selectedStatus = AgencyStatus.open;
  bool _isSaving = false;

  final List<String> _agencyTypes = [
    'Government',
    'Local Government',
    'Cooperative',
    'Private',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    HapticUtils.mediumImpact();

    try {
      // Generate UUID-based agency ID for uniqueness and collision resistance
      final agencyId = 'agency_${const Uuid().v4()}';

      // Create agency data
      final agencyData = Agency(
        id: agencyId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        type: _selectedType,
        status: _selectedStatus,
      );

      // TODO: Save to backend/Hive when integrated
      // For now, just return the new agency to the caller
      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Saving agency...',
        operation: () async {
          await Future.delayed(const Duration(milliseconds: 500)); // Simulate save
          HapticUtils.success();
          return agencyData;
        },
        onError: (e) {
          HapticUtils.error();
          if (mounted) {
            AppNotification.showError(context, 'Failed to save agency: $e');
          }
        },
      );

      if (mounted) {
        AppNotification.showSuccess(context, 'Prospect agency added successfully');

        // Return the new agency to the previous page
        context.pop(agencyData);
      }
    } catch (e) {
      HapticUtils.error();
      if (mounted) {
        AppNotification.showError(context, 'Failed to save agency');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text(
                          '< Back',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Add Prospect Agency',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
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
                      const SizedBox(height: 16),

                      // Agency Name
                      _buildLabel('Agency Name *'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration.copyWith(
                          hintText: 'Enter agency name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address
                      _buildLabel('Address *'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        decoration: _inputDecoration.copyWith(
                          hintText: 'Enter address',
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Contact Number
                      _buildLabel('Contact Number *'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contactNumberController,
                        decoration: _inputDecoration.copyWith(
                          hintText: '+63 XXX XXX XXXX',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Agency Type
                      _buildLabel('Agency Type'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: _inputDecoration.copyWith(
                          hintText: 'Select type',
                          suffixIcon: const Icon(LucideIcons.chevronDown),
                        ),
                        items: _agencyTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            HapticUtils.lightImpact();
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Status
                      _buildLabel('Status'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus == AgencyStatus.open
                            ? 'Open'
                            : _selectedStatus == AgencyStatus.forImplementation
                                ? 'For Implementation'
                                : 'For Reimplementation',
                        decoration: _inputDecoration.copyWith(
                          hintText: 'Select status',
                          suffixIcon: const Icon(LucideIcons.chevronDown),
                        ),
                        items: ['Open', 'For Implementation', 'For Reimplementation']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            HapticUtils.lightImpact();
                            setState(() {
                              _selectedStatus = value == 'Open'
                                  ? AgencyStatus.open
                                  : value == 'For Implementation'
                                      ? AgencyStatus.forImplementation
                                      : AgencyStatus.forReimplementation;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Remarks
                      _buildLabel('Remarks'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _remarksController,
                        decoration: _inputDecoration.copyWith(
                          hintText: 'Enter remarks',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isSaving ? null : _handleSave,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('SAVE'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration get _inputDecoration => InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: const OutlineInputBorder(),
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
