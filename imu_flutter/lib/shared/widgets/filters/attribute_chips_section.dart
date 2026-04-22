import 'package:flutter/material.dart';
import '../../../shared/models/client_attribute_filter.dart';
import '../../../shared/models/client_filter_options.dart';

const int _dropdownThreshold = 4;

class AttributeChipsSection extends StatelessWidget {
  final ClientAttributeFilter draftFilter;
  final ClientFilterOptions options;
  final void Function(ClientAttributeFilter) onChanged;

  const AttributeChipsSection({
    super.key,
    required this.draftFilter,
    required this.options,
    required this.onChanged,
  });

  List<String> _toggle(List<String>? current, String value) {
    final list = List<String>.from(current ?? []);
    list.contains(value) ? list.remove(value) : list.add(value);
    return list;
  }

  String _label(String raw) {
    return raw
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2. Status (renamed from "Visit Status" to "visit status")
        _FilterGroup(
          label: 'visit status',
          values: const ['INTERESTED', 'UNDECIDED', 'NOT_INTERESTED'],
          selected: draftFilter.touchpointStatuses?.toSet() ?? {},
          labelOf: (v) => v == 'NOT_INTERESTED' ? 'Not Interested' : _label(v.replaceAll('_', ' ')),
          onToggle: (v) {
            final updated = _toggle(draftFilter.touchpointStatuses, v);
            onChanged(draftFilter.copyWith(touchpointStatuses: updated.isEmpty ? null : updated));
          },
          onApply: (selected) {
            onChanged(draftFilter.copyWith(touchpointStatuses: selected.isEmpty ? null : selected.toList()));
          },
        ),
        const SizedBox(height: 12),
        // 4. Client Type
        _FilterGroup(
          label: 'Client Type',
          values: options.clientTypes,
          selected: draftFilter.clientTypes?.toSet() ?? {},
          labelOf: _label,
          onToggle: (v) {
            final updated = _toggle(draftFilter.clientTypes, v);
            onChanged(draftFilter.copyWith(clientTypes: updated.isEmpty ? null : updated));
          },
          onApply: (selected) {
            onChanged(draftFilter.copyWith(clientTypes: selected.isEmpty ? null : selected.toList()));
          },
        ),
        const SizedBox(height: 12),
        // 5. Market Type
        _FilterGroup(
          label: 'Market Type',
          values: options.marketTypes,
          selected: draftFilter.marketTypes?.toSet() ?? {},
          labelOf: _label,
          onToggle: (v) {
            final updated = _toggle(draftFilter.marketTypes, v);
            onChanged(draftFilter.copyWith(marketTypes: updated.isEmpty ? null : updated));
          },
          onApply: (selected) {
            onChanged(draftFilter.copyWith(marketTypes: selected.isEmpty ? null : selected.toList()));
          },
        ),
        const SizedBox(height: 12),
        // 6. Pension Type
        _FilterGroup(
          label: 'Pension Type',
          values: options.pensionTypes,
          selected: draftFilter.pensionTypes?.toSet() ?? {},
          labelOf: _label,
          onToggle: (v) {
            final updated = _toggle(draftFilter.pensionTypes, v);
            onChanged(draftFilter.copyWith(pensionTypes: updated.isEmpty ? null : updated));
          },
          onApply: (selected) {
            onChanged(draftFilter.copyWith(pensionTypes: selected.isEmpty ? null : selected.toList()));
          },
        ),
        const SizedBox(height: 12),
        // 7. Product Type
        _FilterGroup(
          label: 'Product Type',
          values: options.productTypes,
          selected: draftFilter.productTypes?.toSet() ?? {},
          labelOf: _label,
          onToggle: (v) {
            final updated = _toggle(draftFilter.productTypes, v);
            onChanged(draftFilter.copyWith(productTypes: updated.isEmpty ? null : updated));
          },
          onApply: (selected) {
            onChanged(draftFilter.copyWith(productTypes: selected.isEmpty ? null : selected.toList()));
          },
        ),
        const SizedBox(height: 12),
        // 8. Loan Type
        _FilterGroup(
          label: 'Loan Type',
          values: options.loanTypes.isNotEmpty
              ? options.loanTypes
              : const ['NEW', 'ADDITIONAL', 'RENEWAL', 'PRETERM'],
          selected: draftFilter.loanTypes?.toSet() ?? {},
          labelOf: _label,
          onToggle: (v) {
            final updated = _toggle(draftFilter.loanTypes, v);
            onChanged(draftFilter.copyWith(loanTypes: updated.isEmpty ? null : updated));
          },
          onApply: (selected) {
            onChanged(draftFilter.copyWith(loanTypes: selected.isEmpty ? null : selected.toList()));
          },
        ),
      ],
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String label;
  final List<String> values;
  final Set<String> selected;
  final String Function(String) labelOf;
  final void Function(String) onToggle;
  final void Function(Set<String>) onApply;

  const _FilterGroup({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        if (values.length <= _dropdownThreshold)
          _ChipsRow(
            values: values,
            selected: selected,
            labelOf: labelOf,
            onToggle: onToggle,
          )
        else
          _MultiSelectDropdown(
            values: values,
            selected: selected,
            labelOf: labelOf,
            onToggle: onToggle,
            onApply: onApply,
          ),
      ],
    );
  }
}

class _ChipsRow extends StatelessWidget {
  final List<String> values;
  final Set<String> selected;
  final String Function(String) labelOf;
  final void Function(String) onToggle;

  const _ChipsRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: values.map((value) {
        final isSelected = selected.contains(value);
        return FilterChip(
          label: Text(labelOf(value)),
          selected: isSelected,
          onSelected: (_) => onToggle(value),
          visualDensity: VisualDensity.compact,
          labelStyle: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : null,
          ),
          selectedColor: theme.colorScheme.primary,
          checkmarkColor: Colors.white,
          showCheckmark: false,
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary : Colors.grey[350]!,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }
}

class _MultiSelectDropdown extends StatelessWidget {
  final List<String> values;
  final Set<String> selected;
  final String Function(String) labelOf;
  final void Function(String) onToggle;
  final void Function(Set<String>) onApply;

  const _MultiSelectDropdown({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
    required this.onApply,
  });

  String get _buttonLabel {
    if (selected.isEmpty) return 'All';
    if (selected.length == 1) return labelOf(selected.first);
    return '${selected.length} selected';
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        values: values,
        selected: selected,
        labelOf: labelOf,
        onApply: onApply,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = selected.isNotEmpty;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasSelection ? theme.colorScheme.primary : Colors.grey[350]!,
            width: hasSelection ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: hasSelection ? theme.colorScheme.primary.withOpacity(0.06) : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                _buttonLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: hasSelection ? theme.colorScheme.primary : Colors.black87,
                  fontWeight: hasSelection ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: hasSelection ? theme.colorScheme.primary : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet extends StatefulWidget {
  final List<String> values;
  final Set<String> selected;
  final String Function(String) labelOf;
  final void Function(Set<String>) onApply;

  const _PickerSheet({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onApply,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late Set<String> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = Set.from(widget.selected);
  }

  void _toggle(String value) {
    setState(() {
      _localSelected.contains(value)
          ? _localSelected.remove(value)
          : _localSelected.add(value);
    });
  }

  void _apply() {
    widget.onApply(_localSelected);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.values.length,
              itemBuilder: (_, i) {
                final value = widget.values[i];
                final isSelected = _localSelected.contains(value);
                return CheckboxListTile(
                  value: isSelected,
                  title: Text(widget.labelOf(value), style: const TextStyle(fontSize: 14)),
                  onChanged: (_) => _toggle(value),
                  controlAffinity: ListTileControlAffinity.trailing,
                  dense: true,
                  activeColor: theme.colorScheme.primary,
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _localSelected.clear());
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _apply,
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

