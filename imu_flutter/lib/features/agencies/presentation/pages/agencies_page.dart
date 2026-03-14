import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';

class AgenciesPage extends ConsumerStatefulWidget {
  const AgenciesPage({super.key});

  @override
  ConsumerState<AgenciesPage> createState() => _AgenciesPageState();
}

class _AgenciesPageState extends ConsumerState<AgenciesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTabIndex = 0;

  // Tab options matching Figma design
  final List<String> _tabs = [
    'Open Agencies',
    'For Implementation',
    'For Reimplementation',
  ];

  // Sample agencies data - to be replaced with actual data from backend
  final List<Agency> _agencies = [
    Agency(
      id: '1',
      name: 'PNP Regional Office',
      address: 'Camp Crame, Quezon City',
      contactNumber: '+63 2 8123 4567',
      type: 'Government',
      status: AgencyStatus.open,
    ),
    Agency(
      id: '2',
      name: 'Municipal Hall',
      address: 'City Hall, Manila',
      contactNumber: '+63 2 8527 1234',
      type: 'Local Government',
      status: AgencyStatus.forImplementation,
    ),
    Agency(
      id: '3',
      name: 'Barangay Office',
      address: 'Barangay 123, Makati',
      contactNumber: '+63 2 8812 9876',
      type: 'Local Government',
      status: AgencyStatus.open,
    ),
    Agency(
      id: '4',
      name: 'Cooperative Office',
      address: '123 Cooperative Rd, Pasig',
      contactNumber: '+63 2 8642 1111',
      type: 'Cooperative',
      status: AgencyStatus.forReimplementation,
    ),
    Agency(
      id: '5',
      name: 'Retirement Office',
      address: 'GSIS Building, QC',
      contactNumber: '+63 2 8976 5432',
      type: 'Government',
      status: AgencyStatus.forImplementation,
    ),
  ];

  List<Agency> get _filteredAgencies {
    // First filter by tab (status)
    List<Agency> filtered = _agencies.where((agency) {
      switch (_selectedTabIndex) {
        case 0:
          return agency.status == AgencyStatus.open;
        case 1:
          return agency.status == AgencyStatus.forImplementation;
        case 2:
          return agency.status == AgencyStatus.forReimplementation;
        default:
          return true;
      }
    }).toList();

    // Then filter by search query
    if (_searchQuery.isEmpty) return filtered;
    return filtered.where((agency) {
      return agency.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          agency.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          agency.type.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onAddProspectAgency() {
    HapticUtils.lightImpact();
    context.go('/agencies/add');
  }

  @override
  Widget build(BuildContext context) {
    final filteredAgencies = _filteredAgencies;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddProspectAgency,
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'Add Prospect Agency',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header with centered title
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Centered Title
                  const Text(
                    'Agencies',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search agencies...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(
                          LucideIcons.search,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pill-style Tabs
            Container(
              padding: const EdgeInsets.fromLTRB(17, 12, 17, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    final isSelected = _selectedTabIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticUtils.lightImpact();
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0F172A)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _tabs[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Agencies List
            Expanded(
              child: filteredAgencies.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(17, 0, 17, 100),
                      itemCount: filteredAgencies.length,
                      itemBuilder: (context, index) {
                        final agency = filteredAgencies[index];
                        return _AgencyCard(agency: agency);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.building2,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No ${_tabs[_selectedTabIndex].toLowerCase()}'
                : 'No matching agencies',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgencyCard extends StatelessWidget {
  final Agency agency;

  const _AgencyCard({required this.agency});

  Color _getStatusColor() {
    switch (agency.status) {
      case AgencyStatus.open:
        return const Color(0xFF22C55E); // Green
      case AgencyStatus.forImplementation:
        return const Color(0xFFF59E0B); // Amber
      case AgencyStatus.forReimplementation:
        return const Color(0xFFEF4444); // Red
    }
  }

  String _getStatusText() {
    switch (agency.status) {
      case AgencyStatus.open:
        return 'Open';
      case AgencyStatus.forImplementation:
        return 'For Implementation';
      case AgencyStatus.forReimplementation:
        return 'For Reimplementation';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticUtils.lightImpact();
            // TODO: Navigate to agency detail
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Agency Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.building2,
                    color: const Color(0xFF0F172A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Agency Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              agency.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        agency.address,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              agency.type,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.phone,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            agency.contactNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Agency status enum
enum AgencyStatus {
  open,
  forImplementation,
  forReimplementation,
}

// Agency data model
class Agency {
  final String id;
  final String name;
  final String address;
  final String contactNumber;
  final String type;
  final AgencyStatus status;

  const Agency({
    required this.id,
    required this.name,
    required this.address,
    required this.contactNumber,
    required this.type,
    required this.status,
  });
}
