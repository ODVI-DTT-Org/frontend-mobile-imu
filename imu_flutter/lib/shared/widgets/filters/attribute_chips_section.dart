import 'package:flutter/material.dart';
import '../../../features/clients/data/models/client_model.dart';
import '../../../shared/models/client_attribute_filter.dart';
import '../filters/client_attribute_filter_helpers.dart';

class AttributeChipsSection extends StatelessWidget {
  final ClientAttributeFilter draftFilter;
  final void Function(ClientAttributeFilter) onChanged;

  const AttributeChipsSection({
    super.key,
    required this.draftFilter,
    required this.onChanged,
  });

  List<T> _toggle<T>(List<T>? current, T value) {
    final list = List<T>.from(current ?? []);
    list.contains(value) ? list.remove(value) : list.add(value);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipGroup<ClientType>(
          label: 'Client Type',
          values: ClientType.values,
          selected: draftFilter.clientTypes?.toSet() ?? {},
          labelOf: formatClientType,
          onToggle: (t) {
            final updated = _toggle(draftFilter.clientTypes, t);
            onChanged(draftFilter.copyWith(clientTypes: updated.isEmpty ? null : updated));
          },
        ),
        const SizedBox(height: 12),
        _ChipGroup<MarketType>(
          label: 'Market Type',
          values: MarketType.values,
          selected: draftFilter.marketTypes?.toSet() ?? {},
          labelOf: formatMarketType,
          onToggle: (t) {
            final updated = _toggle(draftFilter.marketTypes, t);
            onChanged(draftFilter.copyWith(marketTypes: updated.isEmpty ? null : updated));
          },
        ),
        const SizedBox(height: 12),
        _ChipGroup<PensionType>(
          label: 'Pension Type',
          values: PensionType.values,
          selected: draftFilter.pensionTypes?.toSet() ?? {},
          labelOf: formatPensionType,
          onToggle: (t) {
            final updated = _toggle(draftFilter.pensionTypes, t);
            onChanged(draftFilter.copyWith(pensionTypes: updated.isEmpty ? null : updated));
          },
        ),
        const SizedBox(height: 12),
        _ChipGroup<ProductType>(
          label: 'Product Type',
          values: ProductType.values,
          selected: draftFilter.productTypes?.toSet() ?? {},
          labelOf: formatProductType,
          onToggle: (t) {
            final updated = _toggle(draftFilter.productTypes, t);
            onChanged(draftFilter.copyWith(productTypes: updated.isEmpty ? null : updated));
          },
        ),
        const SizedBox(height: 12),
        _ChipGroup<LoanType>(
          label: 'Loan Type',
          values: LoanType.values,
          selected: draftFilter.loanTypes?.toSet() ?? {},
          labelOf: formatLoanType,
          onToggle: (t) {
            final updated = _toggle(draftFilter.loanTypes, t);
            onChanged(draftFilter.copyWith(loanTypes: updated.isEmpty ? null : updated));
          },
        ),
      ],
    );
  }
}

class _ChipGroup<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final Set<T> selected;
  final String Function(T) labelOf;
  final void Function(T) onToggle;

  const _ChipGroup({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        Wrap(
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
        ),
      ],
    );
  }
}
