import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../data/models/agency_model.dart';

final agencyDetailProvider = FutureProvider.family<Agency?, String>((ref, agencyId) async {
  return _getMockAgency(agencyId);
});

Agency _getMockAgency(String id) {
  return Agency(
    id: id,
    name: 'PNP Regional Office',
    address: 'Camp Crame, Quezon City, Metro Manila',
    contactNumber: '+63 2 8123 4567',
    type: 'Government',
    status: AgencyStatus.open,
    email: 'info@pnpcrame.gov.ph',
    description: 'Philippine National Police Regional Office responsible for coordination and administration of police services in the region.',
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
  );
}

class AgencyDetailPage extends ConsumerStatefulWidget {
  final String agencyId;

  const AgencyDetailPage({
    super.key,
    required this.agencyId,
  });

  @override
  ConsumerState<AgencyDetailPage> createState() => _AgencyDetailPageState();
}

class _AgencyDetailPageState extends ConsumerState<AgencyDetailPage> {
  Agency? _agency;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgency();
  }

  Future<void> _loadAgency() async {
    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Loading agency...',
      operation: () async {
        if (mounted) {
          setState(() {
            _agency = _getMockAgency(widget.agencyId);
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _handleDelete() async {
    if (_agency == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Agency'),
        content: Text('Are you sure you want to delete ${_agency!.name}? This action cannot be undone.'),
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

      if (mounted) {
        AppNotification.showSuccess(context, 'Agency deleted');
        context.pop();
      }
    }
  }

  void _editAgency() {
    HapticUtils.lightImpact();
    // TODO: Navigate to edit agency page - stub implementation
    LoadingHelper.withLoading(
      ref: ref,
      message: 'Opening edit form...',

      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          AppNotification.showNeutral(context, 'Edit agency - Coming soon');
        }
      },
    );
  }

  void _callAgency(String? phone) {
    if (phone == null || phone.isEmpty) {
      AppNotification.showError(context, 'No phone number available');
      return;
    }
    HapticUtils.lightImpact();
    AppNotification.showNeutral(context, 'Calling $phone...');
  }

  void _navigateToAddress(String? address) {
    if (address == null || address.isEmpty) {
      AppNotification.showError(context, 'No address available');
      return;
    }
    HapticUtils.lightImpact();
    AppNotification.showNeutral(context, 'Navigating to $address...');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agency Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_agency == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agency Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.building2, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Agency not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            onPressed: _editAgency,
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agency header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.building2,
                      color: Color(0xFF0F172A),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _agency!.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _agency!.type,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_agency!.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(_agency!.status),
                      style: TextStyle(
                        color: _getStatusColor(_agency!.status),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: LucideIcons.phone,
                      label: 'Call',
                      onTap: () => _callAgency(_agency!.contactNumber),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      icon: LucideIcons.mapPin,
                      label: 'Navigate',
                      onTap: () => _navigateToAddress(_agency!.address),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      icon: LucideIcons.mail,
                      label: 'Email',
                      onTap: () {
                        if (_agency!.email != null && _agency!.email!.isNotEmpty) {
                          HapticUtils.lightImpact();
                          AppNotification.showNeutral(context, 'Emailing ${_agency!.email}...');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Agency Information Section
            const _Section(title: 'Agency Information'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: LucideIcons.building2,
                    label: 'Agency Name',
                    value: _agency!.name,
                  ),
                  _InfoRow(
                    icon: LucideIcons.mapPin,
                    label: 'Address',
                    value: _agency!.address,
                  ),
                  _InfoRow(
                    icon: LucideIcons.phone,
                    label: 'Contact Number',
                    value: _agency!.contactNumber,
                  ),
                  if (_agency!.email != null)
                    _InfoRow(
                      icon: LucideIcons.mail,
                      label: 'Email',
                      value: _agency!.email!,
                    ),
                  _InfoRow(
                    icon: LucideIcons.tag,
                    label: 'Agency Type',
                    value: _agency!.type,
                  ),
                  _InfoRow(
                    icon: LucideIcons.activity,
                    label: 'Status',
                    value: _getStatusText(_agency!.status),
                    valueColor: _getStatusColor(_agency!.status),
                  ),
                ],
              ),
            ),

            // Description Section
            if (_agency!.description != null && _agency!.description!.isNotEmpty) ...[
              const _Section(title: 'Description'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _agency!.description!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],

            // Assigned Clients Section
            const _Section(title: 'Assigned Clients'),
            if (_agency!.assignedClients.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No clients assigned to this agency',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _agency!.assignedClients.length,
                itemBuilder: (context, index) {
                  final client = _agency!.assignedClients[index];
                  return _ClientListTile(client: client);
                },
              ),

            // Metadata Section
            const _Section(title: 'Details'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: LucideIcons.calendar,
                    label: 'Created',
                    value: _formatDate(_agency!.createdAt),
                  ),
                  if (_agency!.updatedAt != null)
                    _InfoRow(
                      icon: LucideIcons.clock,
                      label: 'Last Updated',
                      value: _formatDate(_agency!.updatedAt!),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AgencyStatus status) {
    switch (status) {
      case AgencyStatus.open:
        return const Color(0xFF22C55E); // Green
      case AgencyStatus.forImplementation:
        return const Color(0xFFF59E0B); // Amber
      case AgencyStatus.forReimplementation:
        return const Color(0xFFEF4444); // Red
    }
  }

  String _getStatusText(AgencyStatus status) {
    switch (status) {
      case AgencyStatus.open:
        return 'Open';
      case AgencyStatus.forImplementation:
        return 'For Implementation';
      case AgencyStatus.forReimplementation:
        return 'For Reimplementation';
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.grey[700],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientListTile extends StatelessWidget {
  final dynamic client;

  const _ClientListTile({required this.client});

  @override
  Widget build(BuildContext context) {
    final fullName = client.fullName ?? 'Unknown Client';
    final address = client.addresses?.isNotEmpty == true
        ? client.addresses[0].fullAddress
        : 'No address';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.user,
              color: Colors.blue[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}
