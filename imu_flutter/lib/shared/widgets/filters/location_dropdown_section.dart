import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/location_filter.dart';
import '../../../shared/providers/location_filter_providers.dart';
import '../../../features/psgc/data/repositories/psgc_repository.dart';
import 'searchable_picker_sheet.dart';

class LocationDropdownSection extends ConsumerWidget {
  final LocationFilter draftFilter;
  final void Function(LocationFilter) onChanged;

  /// When true, the province/municipality lists come from the user's assigned
  /// areas (Assigned Clients tab). When false, they come from PSGC — every
  /// province in the country, with municipalities cascading from the picked
  /// province (All Clients / Favorites tabs).
  final bool restrictToAssignedAreas;

  const LocationDropdownSection({
    super.key,
    required this.draftFilter,
    required this.onChanged,
    this.restrictToAssignedAreas = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        if (restrictToAssignedAreas)
          _AssignedAreasDropdowns(
            draftFilter: draftFilter,
            onChanged: onChanged,
          )
        else
          _PsgcDropdowns(
            draftFilter: draftFilter,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

/// Province + municipality pickers sourced from the user's assigned areas.
/// Both lists come from `assignedAreasProvider`, so province strings always
/// match the keys used to look up municipalities (no cross-source mismatch).
class _AssignedAreasDropdowns extends ConsumerWidget {
  final LocationFilter draftFilter;
  final void Function(LocationFilter) onChanged;

  const _AssignedAreasDropdowns({
    required this.draftFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(assignedAreasProvider);

    return areasAsync.when(
      data: (areas) {
        final provinces = areas.provinces.toList()..sort();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DropdownButton(
              label: draftFilter.province ?? 'Select Province',
              hint: draftFilter.province == null,
              enabled: provinces.isNotEmpty,
              onTap: provinces.isEmpty
                  ? null
                  : () async {
                      final result = await SearchablePickerSheet.show(
                        context: context,
                        title: 'Province',
                        items: provinces,
                        selectedItems: draftFilter.province != null
                            ? {draftFilter.province!}
                            : {},
                        multiSelect: false,
                      );
                      if (result != null) {
                        final newProvince = result.isEmpty ? null : result.first;
                        onChanged(LocationFilter(
                          province: newProvince,
                          municipalities: null,
                        ));
                      }
                    },
            ),
            const SizedBox(height: 8),
            _MunicipalityDropdownButton(
              province: draftFilter.province,
              selectedMunicipalities: draftFilter.municipalities?.toSet() ?? {},
              onTap: draftFilter.province == null
                  ? null
                  : () async {
                      final muns = areas.getMunicipalities(draftFilter.province!)
                        ..sort();
                      if (muns.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No municipalities assigned for this province'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        return;
                      }
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
      },
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
    );
  }
}

/// Province + municipality pickers sourced from PSGC (every province in PH,
/// with municipalities cascading from the chosen province).
class _PsgcDropdowns extends ConsumerWidget {
  final LocationFilter draftFilter;
  final void Function(LocationFilter) onChanged;

  const _PsgcDropdowns({
    required this.draftFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provincesAsync = ref.watch(provincesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                selectedItems: draftFilter.province != null
                    ? {draftFilter.province!}
                    : {},
                multiSelect: false,
              );
              if (result != null) {
                final newProvince = result.isEmpty ? null : result.first;
                onChanged(LocationFilter(
                  province: newProvince,
                  municipalities: null,
                ));
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
                  try {
                    final munsAsync = await ref.read(
                      municipalitiesByProvinceProvider(draftFilter.province!).future,
                    );
                    final muns = munsAsync.map((m) => m.name).toList();
                    if (muns.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No municipalities found for this province'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                      return;
                    }
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
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to load municipalities: ${e.toString()}'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
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
