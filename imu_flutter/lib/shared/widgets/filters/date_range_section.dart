import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/models/client_attribute_filter.dart';
import '../../../shared/providers/client_attribute_filter_provider.dart';

class DateRangeSection extends ConsumerWidget {
  final ClientAttributeFilter draftFilter;
  final void Function(ClientAttributeFilter) onChanged;

  const DateRangeSection({
    super.key,
    required this.draftFilter,
    required this.onChanged,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _displayLabel() {
    final fromDate = draftFilter.touchpointDateFrom;
    final toDate = draftFilter.touchpointDateTo;

    if (fromDate == null && toDate == null) {
      return 'Any Time';
    }
    if (fromDate != null && toDate != null) {
      return '${_formatDate(fromDate)} - ${_formatDate(toDate)}';
    }
    if (fromDate != null) {
      return 'From ${_formatDate(fromDate)}';
    }
    return 'Until ${_formatDate(toDate)}';
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = draftFilter.touchpointDateFrom ?? now;
    final firstDate = DateTime(now.year - 5);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && context.mounted) {
      final toDate = draftFilter.touchpointDateTo;
      onChanged(draftFilter.copyWith(
        touchpointDateFrom: DateTime(picked.year, picked.month, picked.day),
        touchpointDateTo: toDate,
      ),);
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = draftFilter.touchpointDateTo ?? now;
    final firstDate = DateTime(now.year - 5);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && context.mounted) {
      final fromDate = draftFilter.touchpointDateFrom;
      onChanged(draftFilter.copyWith(
        touchpointDateFrom: fromDate,
        touchpointDateTo: DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
      ),);
    }
  }

  void _setQuickRange(WidgetRef ref, int days) {
    final notifier = ref.read(clientAttributeFilterProvider.notifier);
    notifier.setQuickDateRange(days);
  }

  void _clearRange(WidgetRef ref) {
    final notifier = ref.read(clientAttributeFilterProvider.notifier);
    notifier.clearDateRange();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRange = draftFilter.touchpointDateFrom != null || draftFilter.touchpointDateTo != null;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),

        // Date range display and select buttons
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // From date button
              Expanded(
                child: InkWell(
                  onTap: () => _selectFromDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: hasRange && draftFilter.touchpointDateFrom != null
                            ? theme.colorScheme.primary
                            : Colors.grey[350]!,
                        width: hasRange && draftFilter.touchpointDateFrom != null ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: hasRange && draftFilter.touchpointDateFrom != null
                          ? theme.colorScheme.primary.withOpacity(0.06)
                          : Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          draftFilter.touchpointDateFrom != null
                              ? _formatDate(draftFilter.touchpointDateFrom)
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 13,
                            color: draftFilter.touchpointDateFrom != null
                                ? theme.colorScheme.primary
                                : Colors.black87,
                            fontWeight: draftFilter.touchpointDateFrom != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // To date button
              Expanded(
                child: InkWell(
                  onTap: () => _selectToDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: hasRange && draftFilter.touchpointDateTo != null
                            ? theme.colorScheme.primary
                            : Colors.grey[350]!,
                        width: hasRange && draftFilter.touchpointDateTo != null ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: hasRange && draftFilter.touchpointDateTo != null
                          ? theme.colorScheme.primary.withOpacity(0.06)
                          : Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          draftFilter.touchpointDateTo != null
                              ? _formatDate(draftFilter.touchpointDateTo)
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 13,
                            color: draftFilter.touchpointDateTo != null
                                ? theme.colorScheme.primary
                                : Colors.black87,
                            fontWeight: draftFilter.touchpointDateTo != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Clear button
              if (hasRange)
                InkWell(
                  onTap: () => _clearRange(ref),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[350]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.x,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Quick select buttons
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _QuickSelectButton(
              label: 'Last 7 days',
              onTap: () => _setQuickRange(ref, 7),
            ),
            _QuickSelectButton(
              label: 'Last 30 days',
              onTap: () => _setQuickRange(ref, 30),
            ),
            _QuickSelectButton(
              label: 'Last 90 days',
              onTap: () => _setQuickRange(ref, 90),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickSelectButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickSelectButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[350]!),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
