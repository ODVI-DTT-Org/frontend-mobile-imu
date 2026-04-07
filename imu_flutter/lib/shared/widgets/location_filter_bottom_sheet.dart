import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/shared/models/location_filter.dart';
import 'package:imu_flutter/shared/providers/location_filter_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LocationFilterBottomSheet extends ConsumerStatefulWidget {
  final Function(LocationFilter) onApply;

  const LocationFilterBottomSheet({
    super.key,
    required this.onApply,
  });

  @override
  ConsumerState<LocationFilterBottomSheet> createState() => _LocationFilterBottomSheetState();
}

class _LocationFilterBottomSheetState extends ConsumerState<LocationFilterBottomSheet> {
  String? _selectedProvince;
  Set<String> _selectedMunicipalities = {};
  bool _selectAllMunicipalities = false;

  @override
  Widget build(BuildContext context) {
    final assignedAreasAsync = ref.watch(assignedAreasProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filter by Location',
                    style: TextStyle(
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
          // Content
          Expanded(
            child: assignedAreasAsync.when(
              data: (areas) {
                if (!areas.hasAreas) {
                  return const Center(
                    child: Text('No assigned areas available'),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _ProvinceSection(
                      provinces: areas.provinces.toList(),
                      selectedProvince: _selectedProvince,
                      onProvinceSelected: (province) {
                        setState(() {
                          _selectedProvince = province;
                          _selectedMunicipalities.clear();
                          _selectAllMunicipalities = false;
                        });
                      },
                    ),
                    if (_selectedProvince != null)
                      _MunicipalitySection(
                        province: _selectedProvince!,
                        municipalities: areas.getMunicipalities(_selectedProvince!),
                        selectedMunicipalities: _selectedMunicipalities,
                        selectAll: _selectAllMunicipalities,
                        onMunicipalityToggle: (municipality) {
                          setState(() {
                            if (_selectAllMunicipalities) {
                              _selectAllMunicipalities = false;
                            }
                            if (_selectedMunicipalities.contains(municipality)) {
                              _selectedMunicipalities.remove(municipality);
                            } else {
                              _selectedMunicipalities.add(municipality);
                            }
                          });
                        },
                        onSelectAllToggle: () {
                          setState(() {
                            _selectAllMunicipalities = !_selectAllMunicipalities;
                            _selectedMunicipalities.clear();
                          });
                        },
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Failed to load areas')),
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedProvince != null
                    ? () {
                        final filter = LocationFilter(
                          province: _selectedProvince,
                          municipalities: _selectAllMunicipalities
                              ? null
                              : _selectedMunicipalities.toList(),
                        );
                        widget.onApply(filter);
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text('Apply'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvinceSection extends StatelessWidget {
  final List<String> provinces;
  final String? selectedProvince;
  final Function(String) onProvinceSelected;

  const _ProvinceSection({
    required this.provinces,
    required this.selectedProvince,
    required this.onProvinceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Province'),
      initiallyExpanded: true,
      children: provinces.map((province) {
        return RadioListTile<String>(
          title: Text(province),
          value: province,
          groupValue: selectedProvince,
          onChanged: (value) {
            if (value != null) {
              onProvinceSelected(value);
            }
          },
        );
      }).toList(),
    );
  }
}

class _MunicipalitySection extends StatelessWidget {
  final String province;
  final List<String> municipalities;
  final Set<String> selectedMunicipalities;
  final bool selectAll;
  final Function(String) onMunicipalityToggle;
  final Function onSelectAllToggle;

  const _MunicipalitySection({
    required this.province,
    required this.municipalities,
    required this.selectedMunicipalities,
    required this.selectAll,
    required this.onMunicipalityToggle,
    required this.onSelectAllToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Municipality'),
      initiallyExpanded: true,
      children: [
        CheckboxListTile(
          title: const Text('All Municipalities'),
          value: selectAll,
          onChanged: (_) => onSelectAllToggle(),
        ),
        ...municipalities.map((municipality) {
          return CheckboxListTile(
            title: Text(municipality),
            value: selectedMunicipalities.contains(municipality) && !selectAll,
            onChanged: (_) => onMunicipalityToggle(municipality),
          );
        }).toList(),
      ],
    );
  }
}
