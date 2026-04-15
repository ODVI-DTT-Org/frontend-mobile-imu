import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/debounce_utils.dart';
import '../../../../core/utils/app_notification.dart';

class CallLogPage extends ConsumerStatefulWidget {
  const CallLogPage({super.key});

  @override
  ConsumerState<CallLogPage> createState() => _CallLogPageState();
}

class _CallLogPageState extends ConsumerState<CallLogPage> {
  final _searchController = TextEditingController();
  final _searchDebounce = Debounce(milliseconds: 300);
  String _searchQuery = '';
  int _selectedMainTab = 0; // 0 = Client Contacts, 1 = Call Logs
  String _selectedFilter = 'all';

  // Tab options matching user requirements
  final List<String> _mainTabs = ['Client Contacts', 'Call Logs'];

  // Sample client contacts data - to be replaced with actual data from backend
  final List<ClientContact> _clientContacts = [
    ClientContact(
      id: '1',
      name: 'Amagar, Mina C.',
      phoneNumber: '+63 912 345 6789',
      address: '123 Main St, Quezon City',
      lastVisit: DateTime.now().subtract(const Duration(days: 3)),
      status: ContactStatus.active,
    ),
    ClientContact(
      id: '2',
      name: 'Reyes, Kristine D.',
      phoneNumber: '+63 917 234 5678',
      address: '456 Oak Ave, Manila',
      lastVisit: DateTime.now().subtract(const Duration(days: 7)),
      status: ContactStatus.active,
    ),
    ClientContact(
      id: '3',
      name: 'Santos, Juan M.',
      phoneNumber: '+63 918 123 4567',
      address: '789 Pine Rd, Makati',
      lastVisit: DateTime.now().subtract(const Duration(days: 14)),
      status: ContactStatus.overdue,
    ),
    ClientContact(
      id: '4',
      name: 'Cruz, Ana P.',
      phoneNumber: '+63 919 876 5432',
      address: '321 Elm St, Pasig',
      lastVisit: DateTime.now().subtract(const Duration(days: 5)),
      status: ContactStatus.active,
    ),
    ClientContact(
      id: '5',
      name: 'Garcia, Pedro L.',
      phoneNumber: '+63 920 765 4321',
      address: '654 Maple Dr, Taguig',
      lastVisit: DateTime.now().subtract(const Duration(days: 21)),
      status: ContactStatus.overdue,
    ),
    ClientContact(
      id: '6',
      name: 'Torres, Maria R.',
      phoneNumber: '+63 921 654 3210',
      address: '987 Cedar Ln, Mandaluyong',
      lastVisit: DateTime.now().subtract(const Duration(days: 2)),
      status: ContactStatus.active,
    ),
  ];

  // Sample call logs data - to be replaced with actual data from backend
  final List<CallLog> _callLogs = [
    CallLog(
      id: '1',
      clientName: 'Amagar, Mina C.',
      phoneNumber: '+63 912 345 6789',
      type: CallType.outgoing,
      duration: Duration(minutes: 5, seconds: 32),
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    CallLog(
      id: '2',
      clientName: 'Reyes, Kristine D.',
      phoneNumber: '+63 917 234 5678',
      type: CallType.incoming,
      duration: Duration(minutes: 3, seconds: 15),
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    CallLog(
      id: '3',
      clientName: 'Santos, Juan M.',
      phoneNumber: '+63 918 123 4567',
      type: CallType.missed,
      duration: Duration.zero,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CallLog(
      id: '4',
      clientName: 'Cruz, Ana P.',
      phoneNumber: '+63 919 876 5432',
      type: CallType.outgoing,
      duration: Duration(minutes: 8, seconds: 45),
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    CallLog(
      id: '5',
      clientName: 'Garcia, Pedro L.',
      phoneNumber: '+63 920 765 4321',
      type: CallType.incoming,
      duration: Duration(minutes: 2, seconds: 10),
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    CallLog(
      id: '6',
      clientName: 'Torres, Maria R.',
      phoneNumber: '+63 921 654 3210',
      type: CallType.missed,
      duration: Duration.zero,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    CallLog(
      id: '7',
      clientName: 'Flores, Jose A.',
      phoneNumber: '+63 922 543 2109',
      type: CallType.outgoing,
      duration: Duration(minutes: 12, seconds: 0),
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
  ];

  List<ClientContact> get _filteredContacts {
    if (_searchQuery.isEmpty) return _clientContacts;
    return _clientContacts.where((contact) {
      return contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          contact.phoneNumber.contains(_searchQuery);
    }).toList();
  }

  List<CallLog> get _filteredLogs {
    var logs = _callLogs;

    // Filter by type
    if (_selectedFilter != 'all') {
      CallType? filterType;
      switch (_selectedFilter) {
        case 'outgoing':
          filterType = CallType.outgoing;
          break;
        case 'incoming':
          filterType = CallType.incoming;
          break;
        case 'missed':
          filterType = CallType.missed;
          break;
      }
      if (filterType != null) {
        logs = logs.where((log) => log.type == filterType).toList();
      }
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      logs = logs.where((log) {
        return log.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            log.phoneNumber.contains(_searchQuery);
      }).toList();
    }

    return logs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce.dispose();
    super.dispose();
  }

  void _makeCall(String phoneNumber) {
    HapticUtils.lightImpact();
    AppNotification.showNeutral(context, 'Calling $phoneNumber...');
    // In production, use url_launcher to make the call
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    'Call',
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
                        _searchDebounce.run(() {
                          if (!mounted) return;
                          setState(() {
                            _searchQuery = value;
                          });
                        });
                      },
                      decoration: InputDecoration(
                        hintText: _selectedMainTab == 0
                            ? 'Search contacts...'
                            : 'Search call logs...',
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

            // Top-level Tabs (Client Contacts / Call Logs)
            Container(
              padding: const EdgeInsets.fromLTRB(17, 12, 17, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(_mainTabs.length, (index) {
                    final isSelected = _selectedMainTab == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticUtils.lightImpact();
                          setState(() {
                            _selectedMainTab = index;
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
                            _mainTabs[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Content based on selected tab
            Expanded(
              child: _selectedMainTab == 0
                  ? _buildClientContactsTab()
                  : _buildCallLogsTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientContactsTab() {
    final filteredContacts = _filteredContacts;

    if (filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.users,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No contacts' : 'No matching contacts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(17, 0, 17, 16),
      itemCount: filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = filteredContacts[index];
        return _ClientContactCard(
          contact: contact,
          onCall: () => _makeCall(contact.phoneNumber),
        );
      },
    );
  }

  Widget _buildCallLogsTab() {
    final filteredLogs = _filteredLogs;

    return Column(
      children: [
        // Filter Tabs for Call Logs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterTab(
                  label: 'All',
                  isSelected: _selectedFilter == 'all',
                  onTap: () {
                    HapticUtils.selectionClick();
                    setState(() => _selectedFilter = 'all');
                  },
                ),
                const SizedBox(width: 8),
                _FilterTab(
                  label: 'Outgoing',
                  isSelected: _selectedFilter == 'outgoing',
                  onTap: () {
                    HapticUtils.selectionClick();
                    setState(() => _selectedFilter = 'outgoing');
                  },
                ),
                const SizedBox(width: 8),
                _FilterTab(
                  label: 'Incoming',
                  isSelected: _selectedFilter == 'incoming',
                  onTap: () {
                    HapticUtils.selectionClick();
                    setState(() => _selectedFilter = 'incoming');
                  },
                ),
                const SizedBox(width: 8),
                _FilterTab(
                  label: 'Missed',
                  isSelected: _selectedFilter == 'missed',
                  onTap: () {
                    HapticUtils.selectionClick();
                    setState(() => _selectedFilter = 'missed');
                  },
                ),
              ],
            ),
          ),
        ),

        // Call Logs List
        Expanded(
          child: filteredLogs.isEmpty
              ? _buildCallLogsEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(17, 0, 17, 16),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    return _CallLogCard(
                      callLog: log,
                      onCall: () => _makeCall(log.phoneNumber),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCallLogsEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.phoneOff,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No call logs' : 'No matching calls',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Your call history will appear here'
                : 'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _ClientContactCard extends StatelessWidget {
  final ClientContact contact;
  final VoidCallback onCall;

  const _ClientContactCard({
    required this.contact,
    required this.onCall,
  });

  Color _getStatusColor() {
    switch (contact.status) {
      case ContactStatus.active:
        return const Color(0xFF22C55E); // Green
      case ContactStatus.overdue:
        return const Color(0xFFEF4444); // Red
    }
  }

  String _formatLastVisit(DateTime lastVisit) {
    final now = DateTime.now();
    final diff = now.difference(lastVisit).inDays;

    if (diff == 0) {
      return 'Today';
    } else if (diff == 1) {
      return 'Yesterday';
    } else {
      return '$diff days ago';
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
          onTap: onCall,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Contact Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.user,
                    color: const Color(0xFF0F172A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Contact Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status indicator
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.address,
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
                          Icon(
                            LucideIcons.phone,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              contact.phoneNumber,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            LucideIcons.calendar,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formatLastVisit(contact.lastVisit),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Call Button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.phone, color: Colors.white, size: 18),
                    onPressed: onCall,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallLogCard extends StatelessWidget {
  final CallLog callLog;
  final VoidCallback onCall;

  const _CallLogCard({
    required this.callLog,
    required this.onCall,
  });

  Color _getTypeColor() {
    switch (callLog.type) {
      case CallType.outgoing:
        return const Color(0xFF22C55E); // Green
      case CallType.incoming:
        return const Color(0xFF3B82F6); // Blue
      case CallType.missed:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData _getTypeIcon() {
    switch (callLog.type) {
      case CallType.outgoing:
        return LucideIcons.phoneOutgoing;
      case CallType.incoming:
        return LucideIcons.phoneIncoming;
      case CallType.missed:
        return LucideIcons.phoneMissed;
    }
  }

  String _getTypeLabel() {
    switch (callLog.type) {
      case CallType.outgoing:
        return 'Outgoing';
      case CallType.incoming:
        return 'Incoming';
      case CallType.missed:
        return 'Missed';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (logDate == today) {
      return DateFormat.jm().format(timestamp); // e.g., "2:30 PM"
    } else if (logDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(timestamp); // e.g., "Sep 15"
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
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCall,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Call Type Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Client Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        callLog.clientName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.phone,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            callLog.phoneNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (callLog.duration != Duration.zero) ...[
                            const SizedBox(width: 8),
                            Icon(
                              LucideIcons.clock,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(callLog.duration),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Timestamp and Type
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTimestamp(callLog.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getTypeLabel(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _getTypeColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Client Contact data model
enum ContactStatus { active, overdue }

class ClientContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final DateTime lastVisit;
  final ContactStatus status;

  const ClientContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.lastVisit,
    required this.status,
  });
}

// Call Log data model
enum CallType { outgoing, incoming, missed }

class CallLog {
  final String id;
  final String clientName;
  final String phoneNumber;
  final CallType type;
  final Duration duration;
  final DateTime timestamp;

  const CallLog({
    required this.id,
    required this.clientName,
    required this.phoneNumber,
    required this.type,
    required this.duration,
    required this.timestamp,
  });
}
