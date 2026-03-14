import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/widgets/swipeable_list_tile.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/api/itinerary_api_service.dart';
import '../../../../services/connectivity_service.dart';

class ItineraryPage extends ConsumerStatefulWidget {
  const ItineraryPage({super.key});

  @override
  ConsumerState<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends ConsumerState<ItineraryPage> {
  String _selectedTab = 'Today'; // 'Tomorrow', 'Today', 'Yesterday'
  DateTime? _selectedCalendarDate;
  ItineraryItem? _recentlyDeletedVisit;
  int? _recentlyDeletedIndex;

  @override
  void initState() {
    super.initState();
  }

  DateTime get _selectedDate {
    switch (_selectedTab) {
      case 'Tomorrow':
        return DateTime.now().add(const Duration(days: 1));
      case 'Yesterday':
        return DateTime.now().subtract(const Duration(days: 1));
      default: // Today
        return DateTime.now();
    }
  }

  List<ItineraryItem> get _filteredVisits {
    final itineraryAsync = ref.watch(todayItineraryProvider);
    final targetDate = _selectedCalendarDate ?? _selectedDate;

    return itineraryAsync.when(
      data: (items) {
        return items.where((item) {
          final itemDate = item.scheduledDate;
          return itemDate.year == targetDate.year &&
                 itemDate.month == targetDate.month &&
                 itemDate.day == targetDate.day;
        }).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  Future<void> _handleRefresh() async {
    HapticUtils.pullToRefresh();
    ref.invalidate(todayItineraryProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _addVisit() {
    HapticUtils.lightImpact();
    _showVisitForm();
  }

  void _editVisit(String visitId) {
    HapticUtils.lightImpact();
    final visit = _filteredVisits.firstWhere((v) => v.id == visitId, orElse: null);
    if (visit != null) {
      _showVisitForm(existingVisit: visit);
    }
  }

  void _deleteVisit(String visitId) {
    final visits = _filteredVisits;
    final index = visits.indexWhere((v) => v.id == visitId);
    if (index != -1) {
      setState(() {
        _recentlyDeletedVisit = visits[index];
        _recentlyDeletedIndex = index;
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
        _recentlyDeletedVisit = null;
        _recentlyDeletedIndex = null;
      });

      HapticUtils.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit restored')),
      );
      ref.invalidate(todayItineraryProvider);
    }
  }

  void _showVisitForm({ItineraryItem? existingVisit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VisitFormModal(
        existingVisit: existingVisit?.toJson(),
        selectedDate: _selectedDate,
        onSave: (visitData) {
          HapticUtils.success();
          ref.invalidate(todayItineraryProvider);
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

  void _showCalendarPicker() {
    HapticUtils.lightImpact();
    showDatePicker(
      context: context,
      initialDate: _selectedCalendarDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        setState(() {
          _selectedCalendarDate = date;
          _selectedTab = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addVisit,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: const Text(
          'Add New Visit',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            // Header - centered title (per Figma)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
              child: Row(
                children: [
                  const Spacer(),
                  const Text(
                    'Itinerary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Tab filter (Tomorrow / Today / Yesterday) with calendar button (per Figma)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 17),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // gray-100
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabPill('Tomorrow', 'Tomorrow'),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabPill('Today', 'Today'),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabPill('Yesterday', 'Yesterday'),
                  ),
                  const SizedBox(width: 8),
                  // Calendar button
                  GestureDetector(
                    onTap: _showCalendarPicker,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedCalendarDate != null
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.calendar,
                        size: 20,
                        color: _selectedCalendarDate != null
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Selected date indicator (when using calendar)
            if (_selectedCalendarDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedCalendarDate!),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCalendarDate = null;
                          _selectedTab = 'Today';
                        });
                      },
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Visits list
            Expanded(
              child: _filteredVisits.isEmpty
                  ? PullToRefresh(
                      onRefresh: _handleRefresh,
                      child: ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.calendar,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No scheduled visits',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pull down to refresh',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade400,
                                    ),
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredVisits.length,
                        itemBuilder: (context, index) {
                          final visit = _filteredVisits[index];
                          return SwipeableListTile(
                            leftActions: [
                              SwipeAction.call(() => _callClient('+63 912 345 6789')),
                              SwipeAction.navigate(() => _navigateToVisit(visit.address ?? '')),
                            ],
                            rightActions: [
                              SwipeAction.edit(() => _editVisit(visit.id)),
                              SwipeAction.delete(() => _deleteVisit(visit.id)),
                            ],
                            onTap: () {
                              HapticUtils.lightImpact();
                              context.push('/clients/${visit.clientId}');
                            },
                            child: _VisitCard(visit: visit),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(String tabValue, String label) {
    final isSelected = _selectedTab == tabValue && _selectedCalendarDate == null;
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        setState(() {
          _selectedTab = tabValue;
          _selectedCalendarDate = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final ItineraryItem visit;

  const _VisitCard({required this.visit});

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1: return '${number}st';
      case 2: return '${number}nd';
      case 3: return '${number}rd';
      default: return '${number}th';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'INTERESTED':
        return const Color(0xFF10B981); // Green
      case 'NOT INTERESTED':
        return const Color(0xFFEF4444); // Red
      case 'UNDECIDED':
        return const Color(0xFFF59E0B); // Yellow/Orange
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Touchpoint + Client info
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Touchpoint icon and number
                SizedBox(
                  width: 30,
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 20,
                        color: const Color(0xFF0F172A),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getOrdinal(visit.touchpointNumber),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Client name and agency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.clientName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        visit.address ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right side: Status and notes
          SizedBox(
            width: 133,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(visit.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatStatus(visit.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(visit.status),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    visit.notes!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

/// Visit form modal for adding/editing visits
class _VisitFormModal extends StatefulWidget {
  final Map<String, dynamic>? existingVisit;
  final DateTime? selectedDate;
  final Function(Map<String, dynamic>) onSave;

  const _VisitFormModal({
    this.existingVisit,
    this.selectedDate,
    required this.onSave,
  });

  @override
  State<_VisitFormModal> createState() => _VisitFormModalState();
}

class _VisitFormModalState extends State<_VisitFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
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
    if (widget.selectedDate != null) {
      _selectedDate = widget.selectedDate!;
    }
    if (widget.existingVisit != null) {
      _clientNameController.text = widget.existingVisit!['clientName'] ?? '';
      _addressController.text = widget.existingVisit!['address'] ?? '';
      _notesController.text = widget.existingVisit!['notes'] ?? '';
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
    _notesController.dispose();
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
                                  color: isSelected ? const Color(0xFF0F172A) : Colors.grey[100],
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
                      const SizedBox(height: 16),

                      // Notes
                      const Text(
                        'Notes',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          hintText: 'Enter notes (optional)',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

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
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
        'notes': _notesController.text,
        'date': _selectedDate.toIso8601String().split('T')[0],
        'timeArrival': _formatTime(_timeArrival),
        'timeDeparture': _formatTime(_timeDeparture),
        'productType': _productType,
        'pensionType': _productType.contains('SSS') ? 'SSS' : 'GSIS',
        'touchpoint': _touchpoint,
        'reason': _reason,
      });

      Navigator.pop(context);
    }
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
