import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/widgets/swipeable_list_tile.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/sync/sync_service.dart';

class ItineraryPage extends StatefulWidget {
  const ItineraryPage({super.key});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  String _selectedFilter = 'tomorrow';
  DateTime? _selectedDate;
  bool _isCalendarMode = false;
  Map<String, dynamic>? _recentlyDeletedVisit;
  int? _recentlyDeletedIndex;

  // Mock data
  final List<Map<String, dynamic>> _visits = [
    {
      'id': '1',
      'clientName': 'Maria Santos',
      'address': '123 Main Street, Makati City',
      'productType': 'SSS Pensioner',
      'pensionType': 'SSS',
      'touchpoint': 2,
      'reason': 'INTERESTED',
      'date': '2025-02-20',
      'timeArrival': '09:00',
      'timeDeparture': '09:45',
      'dayStatus': 'tomorrow',
    },
    {
      'id': '2',
      'clientName': 'Juan Dela Cruz',
      'address': '456 Oak Avenue, Quezon City',
      'productType': 'GSIS Pensioner',
      'pensionType': 'GSIS',
      'touchpoint': 4,
      'reason': 'FOR UPDATE',
      'date': '2025-02-20',
      'timeArrival': '14:30',
      'timeDeparture': '15:15',
      'dayStatus': 'tomorrow',
    },
    {
      'id': '3',
      'clientName': 'Ana Reyes',
      'address': '789 Pine Road, Pasig City',
      'productType': 'SSS Pensioner',
      'pensionType': 'SSS',
      'touchpoint': 1,
      'reason': 'LOAN INQUIRY',
      'date': '2025-02-19',
      'timeArrival': '10:00',
      'timeDeparture': '10:30',
      'dayStatus': 'today',
    },
  ];

  List<Map<String, dynamic>> get _filteredVisits {
    if (_isCalendarMode && _selectedDate != null) {
      // For calendar mode, return visits for selected date
      return _visits; // In production, filter by selected date
    }
    return _visits.where((visit) {
      return visit['dayStatus'] == _selectedFilter;
    }).toList();
  }

  Future<void> _handleRefresh() async {
    HapticUtils.pullToRefresh();
    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 1));
    // In production, this would fetch from API/local DB
    setState(() {});
  }

  void _addVisit() {
    HapticUtils.lightImpact();
    _showVisitForm();
  }

  void _editVisit(String visitId) {
    HapticUtils.lightImpact();
    final visit = _visits.firstWhere((v) => v['id'] == visitId);
    _showVisitForm(existingVisit: visit);
  }

  void _deleteVisit(String visitId) {
    final index = _visits.indexWhere((v) => v['id'] == visitId);
    if (index != -1) {
      setState(() {
        _recentlyDeletedVisit = Map.from(_visits[index]);
        _recentlyDeletedIndex = index;
        _visits.removeAt(index);
      });

      HapticUtils.delete();

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Visit deleted'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: _undoDelete,
          ),
        ),
      );
    }
  }

  void _undoDelete() {
    if (_recentlyDeletedVisit != null && _recentlyDeletedIndex != null) {
      setState(() {
        _visits.insert(_recentlyDeletedIndex!, _recentlyDeletedVisit!);
        _recentlyDeletedVisit = null;
        _recentlyDeletedIndex = null;
      });

      HapticUtils.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit restored')),
      );
    }
  }

  void _showVisitForm({Map<String, dynamic>? existingVisit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VisitFormModal(
        existingVisit: existingVisit,
        onSave: (visitData) {
          HapticUtils.success();
          setState(() {
            if (existingVisit != null) {
              final index = _visits.indexWhere((v) => v['id'] == existingVisit['id']);
              if (index != -1) {
                _visits[index] = {...existingVisit, ...visitData};
              }
            } else {
              _visits.add({
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                ...visitData,
              });
            }
          });
        },
      ),
    );
  }

  void _navigateToVisit(String address) {
    HapticUtils.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to $address...')),
    );
    // In production, open maps for navigation
  }

  void _callClient(String phone) {
    HapticUtils.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phone...')),
    );
    // In production, use url_launcher
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Itinerary'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: _addVisit,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                if (_isCalendarMode) ...[
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () {
                      HapticUtils.lightImpact();
                      setState(() {
                        _isCalendarMode = false;
                        _selectedDate = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatSelectedDate(_selectedDate!),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ] else ...[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _FilterTab(
                            label: 'Tomorrow',
                            isSelected: _selectedFilter == 'tomorrow',
                            onTap: () {
                              HapticUtils.selectionClick();
                              setState(() => _selectedFilter = 'tomorrow');
                            },
                          ),
                          _FilterTab(
                            label: 'Today',
                            isSelected: _selectedFilter == 'today',
                            onTap: () {
                              HapticUtils.selectionClick();
                              setState(() => _selectedFilter = 'today');
                            },
                          ),
                          _FilterTab(
                            label: 'Yesterday',
                            isSelected: _selectedFilter == 'yesterday',
                            onTap: () {
                              HapticUtils.selectionClick();
                              setState(() => _selectedFilter = 'yesterday');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.calendar),
                  onPressed: () => _showCalendarPicker(),
                ),
              ],
            ),
          ),
          // Visits list with pull-to-refresh
          Expanded(
            child: _filteredVisits.isEmpty
                ? PullToRefresh(
                    onRefresh: _handleRefresh,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.calendar,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No scheduled visits',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pull down to refresh or tap + to add',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : PullToRefresh(
                    onRefresh: _handleRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredVisits.length,
                      itemBuilder: (context, index) {
                        final visit = _filteredVisits[index];
                        return SwipeableListTile(
                          leftActions: [
                            SwipeAction.call(() => _callClient('+63 912 345 6789')), // Mock phone
                            SwipeAction.navigate(() => _navigateToVisit(visit['address'])),
                          ],
                          rightActions: [
                            SwipeAction.edit(() => _editVisit(visit['id'])),
                            SwipeAction.delete(() => _deleteVisit(visit['id'])),
                          ],
                          onTap: () {
                            HapticUtils.lightImpact();
                            context.push('/clients/${visit['id']}');
                          },
                          child: _VisitCard(visit: visit),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCalendarPicker() {
    HapticUtils.lightImpact();
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    ).then((date) {
      if (date != null) {
        setState(() {
          _selectedDate = date;
          _isCalendarMode = true;
        });
      }
    });
  }

  String _formatSelectedDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Map<String, dynamic> visit;

  const _VisitCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(visit['date']),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(visit['dayStatus']),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${_getOrdinal(visit['touchpoint'])} ',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Icon(LucideIcons.mapPin, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Client info
          Row(
            children: [
              const Icon(LucideIcons.user, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                visit['clientName'],
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  visit['address'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                visit['productType'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                visit['pensionType'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildReasonBadge(visit['reason']),
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${visit['timeArrival']} - ${visit['timeDeparture']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    String label;

    switch (status) {
      case 'today':
        bgColor = Colors.blue[100]!;
        label = 'Today';
        break;
      case 'tomorrow':
        bgColor = Colors.green[100]!;
        label = 'Scheduled';
        break;
      case 'yesterday':
        bgColor = Colors.grey[100]!;
        label = 'Completed';
        break;
      default:
        bgColor = Colors.grey[100]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildReasonBadge(String reason) {
    Color bgColor;
    Color textColor;

    switch (reason) {
      case 'INTERESTED':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'NOT INTERESTED':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case 'UNDECIDED':
        bgColor = Colors.yellow[100]!;
        textColor = Colors.yellow[800]!;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatReason(reason),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatReason(String reason) {
    return reason
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _getOrdinal(int num) {
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th'];
    return ordinals[num - 1] ?? '${num}th';
  }
}

/// Visit form modal for adding/editing visits
class _VisitFormModal extends StatefulWidget {
  final Map<String, dynamic>? existingVisit;
  final Function(Map<String, dynamic>) onSave;

  const _VisitFormModal({
    this.existingVisit,
    required this.onSave,
  });

  @override
  State<_VisitFormModal> createState() => _VisitFormModalState();
}

class _VisitFormModalState extends State<_VisitFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _timeArrival = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _timeDeparture = const TimeOfDay(hour: 9, minute: 30);
  String _productType = 'SSS Pensioner';
  String _reason = 'INTERESTED';
  int _touchpoint = 1;

  final List<String> _productTypes = [
    'SSS Pensioner',
    'GSIS Pensioner',
    'Private',
  ];

  final List<String> _reasons = [
    'INTERESTED',
    'NOT INTERESTED',
    'UNDECIDED',
    'LOAN INQUIRY',
    'FOR UPDATE',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingVisit != null) {
      _clientNameController.text = widget.existingVisit!['clientName'] ?? '';
      _addressController.text = widget.existingVisit!['address'] ?? '';
      _productType = widget.existingVisit!['productType'] ?? _productType;
      _reason = widget.existingVisit!['reason'] ?? _reason;
      _touchpoint = widget.existingVisit!['touchpoint'] ?? _touchpoint;

      if (widget.existingVisit!['date'] != null) {
        _selectedDate = DateTime.parse(widget.existingVisit!['date']);
      }
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existingVisit != null ? 'Edit Visit' : 'Add Visit',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client Name
                      const Text(
                        'Client Name *',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter client name',
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
                      const Text(
                        'Address *',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
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

                      // Date
                      const Text(
                        'Visit Date *',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            suffixIcon: Icon(LucideIcons.calendar),
                          ),
                          child: Text(_formatDate(_selectedDate)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Time Arrival',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectTime(true),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      suffixIcon: Icon(LucideIcons.clock, size: 18),
                                    ),
                                    child: Text(_formatTime(_timeArrival)),
                                  ),
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
                                  'Time Departure',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectTime(false),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      suffixIcon: Icon(LucideIcons.clock, size: 18),
                                    ),
                                    child: Text(_formatTime(_timeDeparture)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Product Type
                      const Text(
                        'Product Type',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _productType,
                        items: _productTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _productType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Touchpoint
                      const Text(
                        'Touchpoint Number',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(7, (index) {
                          final num = index + 1;
                          final isSelected = _touchpoint == num;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticUtils.lightImpact();
                                setState(() => _touchpoint = num);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$num',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Reason
                      const Text(
                        'Reason',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _reason,
                        items: _reasons
                            .map((reason) => DropdownMenuItem(
                                  value: reason,
                                  child: Text(_formatReason(reason)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _reason = value);
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          child: Text(
                            widget.existingVisit != null
                                ? 'UPDATE VISIT'
                                : 'ADD VISIT',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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

  Future<void> _selectDate() async {
    HapticUtils.lightImpact();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime(bool isArrival) async {
    HapticUtils.lightImpact();
    final time = await showTimePicker(
      context: context,
      initialTime: isArrival ? _timeArrival : _timeDeparture,
    );
    if (time != null) {
      setState(() {
        if (isArrival) {
          _timeArrival = time;
        } else {
          _timeDeparture = time;
        }
      });
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      HapticUtils.success();

      widget.onSave({
        'clientName': _clientNameController.text,
        'address': _addressController.text,
        'date': _selectedDate.toIso8601String().split('T')[0],
        'timeArrival': _formatTime(_timeArrival),
        'timeDeparture': _formatTime(_timeDeparture),
        'productType': _productType,
        'pensionType': _productType.contains('SSS') ? 'SSS' : 'GSIS',
        'touchpoint': _touchpoint,
        'reason': _reason,
        'dayStatus': _getDayStatus(_selectedDate),
      });

      Navigator.pop(context);
    }
  }

  String _getDayStatus(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visitDate = DateTime(date.year, date.month, date.day);

    if (visitDate == today) return 'today';
    if (visitDate == today.add(const Duration(days: 1))) return 'tomorrow';
    if (visitDate == today.subtract(const Duration(days: 1))) return 'yesterday';
    return visitDate.isAfter(today) ? 'upcoming' : 'past';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatReason(String reason) {
    return reason
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

