import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import '../../features/psgc/data/models/psgc_models.dart';
import '../../features/psgc/data/repositories/psgc_repository.dart';

/// Cascading location selector: Region → Province → Municipality → Barangay
/// Loads all levels from the PSGC API. Barangay is a searchable dropdown.
class PSGCSelector extends HookConsumerWidget {
  final String? initialPsgcId;
  final String? initialProvince;
  final String? initialMunicipality;
  final String? initialBarangay;
  final Function(PsgcData) onPsgcSelected;
  final bool enabled;

  const PSGCSelector({
    super.key,
    this.initialPsgcId,
    this.initialProvince,
    this.initialMunicipality,
    this.initialBarangay,
    required this.onPsgcSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(psgcRepositoryProvider);

    final selectedRegion = useState<PsgcRegion?>(null);
    final selectedProvince = useState<PsgcProvince?>(null);
    final selectedMunicipality = useState<PsgcMunicipality?>(null);
    final selectedBarangay = useState<PsgcBarangay?>(null);

    final regions = useState<List<PsgcRegion>>([]);
    final provinces = useState<List<PsgcProvince>>([]);
    final municipalities = useState<List<PsgcMunicipality>>([]);
    final barangays = useState<List<PsgcBarangay>>([]);

    final isLoadingRegions = useState(true);
    final isLoadingProvinces = useState(false);
    final isLoadingMunicipalities = useState(false);
    final isLoadingBarangays = useState(false);

    // Load regions once
    useEffect(() {
      Future(() async {
        try {
          final loaded = await repo.getRegions();
          regions.value = loaded;
        } catch (_) {
          regions.value = [];
        } finally {
          isLoadingRegions.value = false;
        }
      });
      return null;
    }, const []);

    // Load provinces when region changes
    useEffect(() {
      if (selectedRegion.value == null) {
        provinces.value = [];
        return null;
      }
      isLoadingProvinces.value = true;
      Future(() async {
        try {
          final loaded = await repo.getProvincesByRegion(selectedRegion.value!.name);
          provinces.value = loaded;
        } catch (_) {
          provinces.value = [];
        } finally {
          isLoadingProvinces.value = false;
        }
      });
      return null;
    }, [selectedRegion.value]);

    // Load municipalities when province changes
    useEffect(() {
      if (selectedProvince.value == null) {
        municipalities.value = [];
        return null;
      }
      isLoadingMunicipalities.value = true;
      Future(() async {
        try {
          final loaded = await repo.getMunicipalitiesByProvince(selectedProvince.value!.name);
          municipalities.value = loaded;
        } catch (_) {
          municipalities.value = [];
        } finally {
          isLoadingMunicipalities.value = false;
        }
      });
      return null;
    }, [selectedProvince.value]);

    // Load barangays when municipality changes
    useEffect(() {
      if (selectedMunicipality.value == null) {
        barangays.value = [];
        return null;
      }
      isLoadingBarangays.value = true;
      Future(() async {
        try {
          final loaded = await repo.getBarangaysByMunicipality(selectedMunicipality.value!.name);
          barangays.value = loaded;
        } catch (_) {
          barangays.value = [];
        } finally {
          isLoadingBarangays.value = false;
        }
      });
      return null;
    }, [selectedMunicipality.value]);

    void notifySelection(PsgcBarangay barangay) {
      onPsgcSelected(PsgcData(
        psgcId: barangay.id,
        region: selectedRegion.value?.name ?? '',
        province: selectedProvince.value?.name ?? '',
        municipality: selectedMunicipality.value?.name ?? '',
        barangay: barangay.barangay ?? '',
      ));
    }

    Future<void> showBarangayPicker() async {
      if (barangays.value.isEmpty) return;
      final result = await showModalBottomSheet<PsgcBarangay>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _BarangayPickerSheet(barangays: barangays.value),
      );
      if (result != null) {
        selectedBarangay.value = result;
        notifySelection(result);
      }
    }

    if (isLoadingRegions.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Region
        _buildDropdown<PsgcRegion>(
          label: 'Region *',
          value: selectedRegion.value,
          items: regions.value,
          itemLabel: (r) => r.name,
          hint: 'Select Region',
          icon: LucideIcons.globe,
          enabled: enabled && regions.value.isNotEmpty,
          onChanged: enabled
              ? (value) {
                  selectedRegion.value = value;
                  selectedProvince.value = null;
                  selectedMunicipality.value = null;
                  selectedBarangay.value = null;
                }
              : null,
        ),

        const SizedBox(height: 12),

        // Province
        if (isLoadingProvinces.value)
          const _LoadingField(label: 'Province')
        else
          _buildDropdown<PsgcProvince>(
            label: 'Province *',
            value: selectedProvince.value,
            items: provinces.value,
            itemLabel: (p) => p.name,
            hint: selectedRegion.value == null ? 'Select region first' : 'Select Province',
            icon: LucideIcons.map,
            enabled: enabled && selectedRegion.value != null && provinces.value.isNotEmpty,
            onChanged: enabled && selectedRegion.value != null
                ? (value) {
                    selectedProvince.value = value;
                    selectedMunicipality.value = null;
                    selectedBarangay.value = null;
                  }
                : null,
          ),

        const SizedBox(height: 12),

        // Municipality
        if (isLoadingMunicipalities.value)
          const _LoadingField(label: 'City/Municipality')
        else
          _buildDropdown<PsgcMunicipality>(
            label: 'City/Municipality *',
            value: selectedMunicipality.value,
            items: municipalities.value,
            itemLabel: (m) => m.displayName,
            hint: selectedProvince.value == null ? 'Select province first' : 'Select City/Municipality',
            icon: LucideIcons.building,
            enabled: enabled && selectedProvince.value != null && municipalities.value.isNotEmpty,
            onChanged: enabled && selectedProvince.value != null
                ? (value) {
                    selectedMunicipality.value = value;
                    selectedBarangay.value = null;
                  }
                : null,
          ),

        const SizedBox(height: 12),

        // Barangay — searchable picker
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Barangay *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            if (isLoadingBarangays.value)
              const _LoadingField(label: '')
            else
              GestureDetector(
                onTap: (enabled && selectedMunicipality.value != null && barangays.value.isNotEmpty)
                    ? showBarangayPicker
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedBarangay.value != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: (enabled && selectedMunicipality.value != null) ? null : Colors.grey.shade100,
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.users, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedBarangay.value?.barangay ??
                              (selectedMunicipality.value == null
                                  ? 'Select city/municipality first'
                                  : 'Select Barangay'),
                          style: TextStyle(
                            color: selectedBarangay.value != null ? null : Colors.grey,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required String hint,
    required IconData icon,
    required bool enabled,
    required void Function(T?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          hint: Text(hint),
          icon: Icon(icon, size: 18),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey.shade100,
          ),
          items: items.map((item) => DropdownMenuItem<T>(
            value: item,
            child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Searchable barangay picker sheet
class _BarangayPickerSheet extends HookWidget {
  final List<PsgcBarangay> barangays;
  const _BarangayPickerSheet({required this.barangays});

  @override
  Widget build(BuildContext context) {
    final search = useTextEditingController();
    final filtered = useState(barangays);

    useEffect(() {
      void listener() {
        final q = search.text.toLowerCase();
        filtered.value = q.isEmpty
            ? barangays
            : barangays.where((b) => (b.barangay ?? '').toLowerCase().contains(q)).toList();
      }
      search.addListener(listener);
      return () => search.removeListener(listener);
    }, [barangays]);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: search,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search barangay...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filtered.value.length,
              itemBuilder: (ctx, i) {
                final b = filtered.value[i];
                return ListTile(
                  title: Text(b.barangay ?? ''),
                  onTap: () => Navigator.of(ctx).pop(b),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingField extends StatelessWidget {
  final String label;
  const _LoadingField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade100,
          ),
          child: const Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Loading...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}

/// PSGC data model
class PsgcData {
  final String? psgcId;
  final String region;
  final String province;
  final String municipality;
  final String barangay;

  PsgcData({
    this.psgcId,
    required this.region,
    required this.province,
    required this.municipality,
    required this.barangay,
  });

  String get fullAddress {
    final parts = [barangay, municipality, province, region]
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  @override
  String toString() => 'PsgcData($fullAddress)';
}
