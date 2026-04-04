import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../services/api/client_api_service.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/client_model.dart';

class EditClientPage extends ConsumerStatefulWidget {
  final String clientId;

  const EditClientPage({super.key, required this.clientId});

  @override
  ConsumerState<EditClientPage> createState() => _EditClientPageState();
}

class _EditClientPageState extends ConsumerState<EditClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _hiveService = HiveService();

  bool _isLoading = true;
  bool _isSaving = false;
  Client? _client;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _facebookController = TextEditingController();
  final _remarksController = TextEditingController();

  // Dropdown values
  String _productType = 'SSS Pensioner';
  String _pensionType = 'SSS';
  String _marketType = 'Residential';
  String _clientType = 'POTENTIAL';

  // Address and phone lists
  List<Map<String, Object?>> _addresses = [];
  List<Map<String, Object?>> _phoneNumbers = [];

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  Future<void> _loadClient() async {
    try {
      if (!_hiveService.isInitialized) {
        await _hiveService.init();
      }

      // First try to load from Hive (offline support)
      final clientData = _hiveService.getClient(widget.clientId);
      if (clientData != null) {
        try {
          // Try fromRow first for API data (snake_case), fallback to fromJson for camelCase
          try {
            _client = Client.fromRow(clientData);
          } catch (e) {
            debugPrint('fromRow failed, trying fromJson: $e');
            // If fromRow fails, try fromJson
            _client = Client.fromJson(clientData);
          }
          // Populate form and update state atomically
          setState(() {
            _populateForm();
            _isLoading = false;
          });
          return;
        } catch (e, stack) {
          debugPrint('Error parsing client data from Hive: $e\n$stack');
          // Fall through to API fetch
        }
      }

      // If not in Hive or parsing failed, fetch from API
      debugPrint('Client not in Hive, fetching from API: ${widget.clientId}');
      final clientApiService = ref.read(clientApiServiceProvider);
      final client = await clientApiService.fetchClient(widget.clientId);

      if (client != null && mounted) {
        _client = client;
        // Store in Hive for future use
        try {
          await _hiveService.addClient(client.toJson());
          debugPrint('Client stored in Hive successfully');
        } catch (e) {
          debugPrint('Warning: Failed to store client in Hive: $e');
          // Continue anyway - we have the client data
        }
        // Populate form and update state atomically
        setState(() {
          _populateForm();
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showNotFoundError();
        }
      }
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
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Go Back'),
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

  void _populateForm() {
    if (_client == null) return;

    _firstNameController.text = _client!.firstName;
    _middleNameController.text = _client!.middleName ?? '';
    _lastNameController.text = _client!.lastName;
    _contactNumberController.text = _client!.phoneNumbers.isNotEmpty
        ? _client!.phoneNumbers.first.number
        : '';
    _emailController.text = _client!.email ?? '';
    _facebookController.text = _client!.facebookLink ?? '';
    _remarksController.text = _client!.remarks ?? '';

    _productType = _getProductTypeLabel(_client!.productType);
    _pensionType = _getPensionTypeLabel(_client!.pensionType);
    _marketType = _client!.marketType != null
        ? _getMarketTypeLabel(_client!.marketType!)
        : 'Residential';
    _clientType = _client!.clientType.name.toUpperCase();

    _addresses = _client!.addresses
        .map((a) => <String, Object?>{
              'id': a.id,
              'street': a.street,
              'barangay': a.barangay ?? '',
              'city': a.city,
              'province': a.province ?? '',
              'isPrimary': a.isPrimary,
            })
        .toList();

    _phoneNumbers = _client!.phoneNumbers
        .map((p) => <String, Object?>{
              'id': p.id,
              'number': p.number,
              'label': p.label ?? 'Mobile',
              'isPrimary': p.isPrimary,
            })
        .toList();

    if (_addresses.isEmpty) {
      _addresses.add(<String, Object?>{
        'id': '1',
        'street': '',
        'barangay': '',
        'city': '',
        'province': '',
        'isPrimary': true,
      });
    }

    if (_phoneNumbers.isEmpty) {
      _phoneNumbers.add(<String, Object?>{
        'id': '1',
        'number': '',
        'label': 'Mobile',
        'isPrimary': true,
      });
    }
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _facebookController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      // Validation failed - scroll to first error and show message
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

    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Updating client...',
      operation: () async {
        final updatedData = {
          'id': widget.clientId,
          'firstName': _firstNameController.text.trim(),
          'middleName': _middleNameController.text.trim().isEmpty
              ? null
              : _middleNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'contactNumber': _contactNumberController.text.trim().isEmpty
              ? null
              : _contactNumberController.text.trim(),
          'email': _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          'facebookLink': _facebookController.text.trim().isEmpty
              ? null
              : _facebookController.text.trim(),
          'remarks': _remarksController.text.trim().isEmpty
              ? null
              : _remarksController.text.trim(),
          'productType': _productType.toLowerCase().replaceAll(' ', ''),
          'pensionType': _pensionType.toLowerCase(),
          'marketType': _marketType.toLowerCase(),
          'clientType': _clientType.toLowerCase(),
          'addresses': _addresses,
          'phoneNumbers': _phoneNumbers,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        // Save to local storage (saveClient updates if exists)
        debugPrint('[EDIT_CLIENT] Saving client ${widget.clientId}');
        debugPrint('[EDIT_CLIENT] Remarks value: "${updatedData['remarks']}"');

        await _hiveService.saveClient(widget.clientId, {
          ..._client!.toJson(),
          ...updatedData,
        });

        debugPrint('[EDIT_CLIENT] Client saved successfully');
        // PowerSync handles sync automatically
      },
      onError: (e) {
        HapticUtils.error();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update client: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    HapticUtils.success();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true); // Return true to indicate success
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
            'Are you sure you want to delete ${_firstNameController.text} ${_lastNameController.text}?'),
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
          // PowerSync handles sync automatically
        },
        onError: (e) {
          HapticUtils.error();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete client: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client deleted')),
        );
        context.pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Client')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Client'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Type Toggle
              const Text(
                'Client Type',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'Potential',
                      isSelected: _clientType == 'POTENTIAL',
                      onTap: () {
                        HapticUtils.selectionClick();
                        setState(() => _clientType = 'POTENTIAL');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeButton(
                      label: 'Existing',
                      isSelected: _clientType == 'EXISTING',
                      onTap: () {
                        HapticUtils.selectionClick();
                        setState(() => _clientType = 'EXISTING');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Name Section
              const Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _middleNameController,
                      decoration: const InputDecoration(
                        labelText: 'Middle',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name *',
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Product & Pension Type
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product Type',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _productType,
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
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _pensionType,
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
              const SizedBox(height: 20),

              // Market Type
              const Text(
                'Market Type',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _marketType,
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
              const SizedBox(height: 20),

              // Contact Number
              const Text(
                'Contact Number',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactNumberController,
                decoration: const InputDecoration(
                  hintText: '+63 912 345 6789',
                  prefixIcon: Icon(LucideIcons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Email
              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'email@example.com',
                  prefixIcon: Icon(LucideIcons.mail),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Facebook
              const Text(
                'Facebook Profile',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _facebookController,
                decoration: const InputDecoration(
                  hintText: 'Facebook profile URL',
                  prefixIcon: Icon(LucideIcons.facebook),
                ),
              ),
              const SizedBox(height: 20),

              // Address
              const Text(
                'Address',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ..._addresses.asMap().entries.map((entry) {
                final index = entry.key;
                final address = entry.value;
                return _AddressField(
                  address: address,
                  onChanged: (updated) {
                    _addresses[index] = updated;
                  },
                  onRemove: _addresses.length > 1
                      ? () {
                          HapticUtils.lightImpact();
                          setState(() => _addresses.removeAt(index));
                        }
                      : null,
                );
              }),
              TextButton.icon(
                onPressed: () {
                  HapticUtils.lightImpact();
                  setState(() {
                    _addresses.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'street': '',
                      'barangay': '',
                      'city': '',
                      'province': '',
                      'isPrimary': false,
                    });
                  });
                },
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add Address'),
              ),
              const SizedBox(height: 20),

              // Phone Numbers
              const Text(
                'Phone Numbers',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ..._phoneNumbers.asMap().entries.map((entry) {
                final index = entry.key;
                final phone = entry.value;
                return _PhoneField(
                  phone: phone,
                  onChanged: (updated) {
                    _phoneNumbers[index] = updated;
                  },
                  onRemove: _phoneNumbers.length > 1
                      ? () {
                          HapticUtils.lightImpact();
                          setState(() => _phoneNumbers.removeAt(index));
                        }
                      : null,
                );
              }),
              TextButton.icon(
                onPressed: () {
                  HapticUtils.lightImpact();
                  setState(() {
                    _phoneNumbers.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'number': '',
                      'label': 'Mobile',
                      'isPrimary': false,
                    });
                  });
                },
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add Phone'),
              ),
              const SizedBox(height: 20),

              // Remarks
              const Text(
                'Remarks',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  hintText: 'Additional notes...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
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
                      : const Text('SAVE CHANGES'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  final Map<String, dynamic> address;
  final Function(Map<String, dynamic>) onChanged;
  final VoidCallback? onRemove;

  const _AddressField({
    required this.address,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: address['street'],
                  decoration: const InputDecoration(
                    labelText: 'Street',
                    isDense: true,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  onChanged: (value) {
                    onChanged({...address, 'street': value});
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: address['barangay'],
                  decoration: const InputDecoration(
                    labelText: 'Barangay',
                    isDense: true,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  onChanged: (value) {
                    onChanged({...address, 'barangay': value});
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
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: address['city'],
                  decoration: const InputDecoration(
                    labelText: 'City',
                    isDense: true,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  onChanged: (value) {
                    onChanged({...address, 'city': value});
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: address['province'],
                  decoration: const InputDecoration(
                    labelText: 'Province',
                    isDense: true,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  onChanged: (value) {
                    onChanged({...address, 'province': value});
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

class _PhoneField extends StatelessWidget {
  final Map<String, dynamic> phone;
  final Function(Map<String, dynamic>) onChanged;
  final VoidCallback? onRemove;

  const _PhoneField({
    required this.phone,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: DropdownButtonFormField<String>(
              value: phone['label'],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.all(12),
              ),
              items: ['Mobile', 'Home', 'Work', 'Other']
                  .map((label) => DropdownMenuItem(
                        value: label,
                        child: Text(label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged({...phone, 'label': value});
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: phone['number'],
              decoration: const InputDecoration(
                hintText: '+63 912 345 6789',
                isDense: true,
                contentPadding: EdgeInsets.all(12),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                onChanged({...phone, 'number': value});
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
            ),
          ],
        ],
      ),
    );
  }
}
