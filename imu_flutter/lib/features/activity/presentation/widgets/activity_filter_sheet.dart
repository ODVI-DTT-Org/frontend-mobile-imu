import 'package:flutter/material.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';

class ActivityFilterSheet extends StatefulWidget {
  final ActivityType? selectedType;
  final DateTimeRange selectedDateRange;
  final void Function(ActivityType? type, DateTimeRange dateRange) onApply;
  final VoidCallback onClear;

  const ActivityFilterSheet({
    super.key,
    required this.selectedType,
    required this.selectedDateRange,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<ActivityFilterSheet> {
  ActivityType? _type;
  _DatePreset _datePreset = _DatePreset.last7Days;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _type = widget.selectedType;
    final diff = widget.selectedDateRange.end
        .difference(widget.selectedDateRange.start)
        .inDays;
    if (diff <= 1) {
      _datePreset = _DatePreset.today;
    } else if (diff <= 7) {
      _datePreset = _DatePreset.last7Days;
    } else if (diff <= 30) {
      _datePreset = _DatePreset.last30Days;
    } else {
      _datePreset = _DatePreset.custom;
      _customRange = widget.selectedDateRange;
    }
  }

  DateTimeRange get _resolvedRange {
    final now = DateTime.now();
    switch (_datePreset) {
      case _DatePreset.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
      case _DatePreset.last7Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case _DatePreset.last30Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case _DatePreset.custom:
        return _customRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity Type section
                    const Text(
                      'Activity Type',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _typeOption(null, 'All'),
                    _typeOption(ActivityType.approval, 'Approvals'),
                    _typeOption(ActivityType.touchpoint, 'Touchpoints'),
                    _typeOption(ActivityType.visit, 'Visits'),
                    _typeOption(ActivityType.call, 'Calls'),

                    const SizedBox(height: 24),

                    // Date Range section
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _dateOption(_DatePreset.last7Days, 'Last 7 days'),
                    _dateOption(_DatePreset.today, 'Today only'),
                    _dateOption(_DatePreset.last30Days, 'Last 30 days'),
                    _dateOption(_DatePreset.custom, 'Custom range'),

                    if (_datePreset == _DatePreset.custom) ...[
                      const SizedBox(height: 12),
                      _buildCustomRangePicker(),
                    ],
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onClear();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(_type, _resolvedRange);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Apply'),
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

  Widget _typeOption(ActivityType? value, String label) {
    return RadioListTile<ActivityType?>(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      groupValue: _type,
      dense: true,
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() => _type = v),
    );
  }

  Widget _dateOption(_DatePreset preset, String label) {
    return RadioListTile<_DatePreset>(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: preset,
      groupValue: _datePreset,
      dense: true,
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() => _datePreset = v!),
    );
  }

  Widget _buildCustomRangePicker() {
    return Row(
      children: [
        Expanded(
          child: _datePicker(
            label: 'From',
            date: _customRange?.start,
            onPick: (d) => setState(() {
              _customRange = DateTimeRange(
                start: d,
                end: _customRange?.end ?? DateTime.now(),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _datePicker(
            label: 'To',
            date: _customRange?.end,
            onPick: (d) => setState(() {
              _customRange = DateTimeRange(
                start: _customRange?.start ??
                    DateTime.now().subtract(const Duration(days: 7)),
                end: d,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? date,
    required void Function(DateTime) onPick,
  }) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: Text(
        date != null
            ? '${date.month}/${date.day}/${date.year}'
            : label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

enum _DatePreset { today, last7Days, last30Days, custom }
