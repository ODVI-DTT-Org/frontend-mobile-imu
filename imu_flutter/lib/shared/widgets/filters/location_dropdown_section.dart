import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/location_filter.dart';
import '../../../shared/providers/location_filter_providers.dart';
import '../../../features/psgc/data/models/psgc_models.dart';
import 'searchable_picker_sheet.dart';

class LocationDropdownSection extends ConsumerWidget {
  final LocationFilter draftFilter;
  final bool showAllPsgc;
  final void Function(LocationFilter) onChanged;

  const LocationDropdownSection({
    super.key,
    required this.draftFilter,
    required this.showAllPsgc,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provincesAsync = showAllPsgc
        ? ref.watch(provincesProvider)
        : ref.watch(assignedAreasProvider).whenData((areas) =>
            areas.provinces
                .map((p) => PsgcProvince(name: p, code: p, region: ''))
                .toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Location',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        provincesAsync.when(
          data: (provinces) => _DropdownButton(
            label: draftFilter.province ?? 'Select Province',
            hint: draftFilter.province == null,
            enabled: true,
            onTap: () async {
              final result = await SearchablePickerSheet.show(
                context: context,
                title: 'Province',
                items: provinces.map((p) => p.name).toList(),
                selectedItems: draftFilter.province != null ? {draftFilter.province!} : {},
                multiSelect: false,
              );
              if (result != null) {
                final newProvince = result.isEmpty ? null : result.first;
                onChanged(LocationFilter(province: newProvince, municipalities: null));
              }
            },
          ),
          loading: () => const _DropdownButton(
            label: 'Loading...',
            enabled: false,
            onTap: null,
          ),
          error: (_, __) => const _DropdownButton(
            label: 'Failed to load',
            enabled: false,
            onTap: null,
          ),
        ),
        const SizedBox(height: 8),
        _MunicipalityDropdownButton(
          province: draftFilter.province,
          selectedMunicipalities: draftFilter.municipalities?.toSet() ?? {},
          onTap: draftFilter.province == null
              ? null
              : () async {
                  final munsAsync =
                      ref.read(municipalitiesByProvinceProvider(draftFilter.province!));
                  final muns = munsAsync.value?.map((m) => m.name).toList() ?? [];
                  final result = await SearchablePickerSheet.show(
                    context: context,
                    title: 'Municipality',
                    items: muns,
                    selectedItems: draftFilter.municipalities?.toSet() ?? {},
                    multiSelect: true,
                    showAllOption: true,
                  );
                  if (result != null) {
                    onChanged(LocationFilter(
                      province: draftFilter.province,
                      municipalities: result.isEmpty ? null : result.toList(),
                    ));
                  }
                },
        ),
      ],
    );
  }
}

class _MunicipalityDropdownButton extends StatelessWidget {
  final String? province;
  final Set<String> selectedMunicipalities;
  final VoidCallback? onTap;

  const _MunicipalityDropdownButton({
    required this.province,
    required this.selectedMunicipalities,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    if (province == null) {
      label = 'Select Municipality';
    } else if (selectedMunicipalities.isEmpty) {
      label = 'All Municipalities';
    } else if (selectedMunicipalities.length == 1) {
      label = selectedMunicipalities.first;
    } else {
      label = '${selectedMunicipalities.length} municipalities';
    }

    return _DropdownButton(
      label: label,
      hint: province == null || selectedMunicipalities.isEmpty,
      enabled: province != null,
      onTap: onTap,
    );
  }
}

class _DropdownButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool hint;
  final VoidCallback? onTap;

  const _DropdownButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.hint = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? theme.colorScheme.outline : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
          color: enabled ? null : Colors.grey[100],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: hint || !enabled ? Colors.grey[500] : null,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: enabled ? null : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
