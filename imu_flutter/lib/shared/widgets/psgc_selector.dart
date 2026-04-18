import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import '../providers/app_providers.dart' show powerSyncDatabaseProvider, jwtAuthProvider;

/// Cascading location selector: Province → City/Municipality → Barangay (text)
/// Province and municipality are loaded from user_locations (already synced).
/// Barangay is a free-text field — too granular for a dropdown.
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
    final selectedProvince = useState<String?>(null);
    final selectedMunicipality = useState<String?>(null);
    final barangayController = useTextEditingController(text: initialBarangay ?? '');
    final provinces = useState<List<String>>([]);
    final municipalities = useState<List<String>>([]);
    final isLoading = useState(true);

    final db = ref.watch(powerSyncDatabaseProvider).value;
    final currentUser = ref.read(jwtAuthProvider).currentUser;

    // Load provinces from user_locations for this user
    useEffect(() {
      if (db == null || currentUser == null) {
        isLoading.value = false;
        return null;
      }
      Future(() async {
        try {
          final rows = await db.getAll(
            'SELECT DISTINCT province FROM user_locations WHERE user_id = ? AND deleted_at IS NULL ORDER BY province',
            [currentUser.id],
          );
          final loaded = rows.map((r) => r['province'] as String).toList();
          provinces.value = loaded;
          if (initialProvince != null && loaded.contains(initialProvince)) {
            selectedProvince.value = initialProvince;
          }
        } catch (_) {
          provinces.value = [];
        } finally {
          isLoading.value = false;
        }
      });
      return null;
    }, [db, currentUser?.id]);

    // Load municipalities when province changes
    useEffect(() {
      if (db == null || currentUser == null || selectedProvince.value == null) {
        municipalities.value = [];
        return null;
      }
      Future(() async {
        try {
          final rows = await db.getAll(
            'SELECT DISTINCT municipality FROM user_locations WHERE user_id = ? AND province = ? AND deleted_at IS NULL ORDER BY municipality',
            [currentUser.id, selectedProvince.value],
          );
          final loaded = rows.map((r) => r['municipality'] as String).toList();
          municipalities.value = loaded;
          if (initialMunicipality != null && loaded.contains(initialMunicipality)) {
            selectedMunicipality.value = initialMunicipality;
          }
        } catch (_) {
          municipalities.value = [];
        }
      });
      return null;
    }, [db, currentUser?.id, selectedProvince.value]);

    void _notifyIfComplete() {
      if (selectedProvince.value != null &&
          selectedMunicipality.value != null &&
          barangayController.text.trim().isNotEmpty) {
        onPsgcSelected(PsgcData(
          region: '',
          province: selectedProvince.value!,
          municipality: selectedMunicipality.value!,
          barangay: barangayController.text.trim(),
        ));
      }
    }

    // Fire initial notification once all pre-populated values are set
    useEffect(() {
      if (selectedMunicipality.value != null &&
          initialBarangay != null &&
          initialBarangay!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _notifyIfComplete());
      }
      return null;
    }, [selectedMunicipality.value]);

    if (isLoading.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Province dropdown
        _buildDropdown(
          label: 'Province *',
          value: selectedProvince.value,
          items: provinces.value,
          hint: provinces.value.isEmpty ? 'No locations assigned' : 'Select Province',
          icon: LucideIcons.map,
          enabled: enabled && provinces.value.isNotEmpty,
          onChanged: enabled
              ? (value) {
                  selectedProvince.value = value;
                  selectedMunicipality.value = null;
                  barangayController.clear();
                }
              : null,
        ),

        const SizedBox(height: 12),

        // Municipality dropdown
        _buildDropdown(
          label: 'City/Municipality *',
          value: selectedMunicipality.value,
          items: municipalities.value,
          hint: selectedProvince.value == null ? 'Select province first' : 'Select City/Municipality',
          icon: LucideIcons.building,
          enabled: enabled && selectedProvince.value != null && municipalities.value.isNotEmpty,
          onChanged: enabled && selectedProvince.value != null
              ? (value) {
                  selectedMunicipality.value = value;
                  barangayController.clear();
                }
              : null,
        ),

        const SizedBox(height: 12),

        // Barangay text field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Barangay *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: barangayController,
              enabled: enabled && selectedMunicipality.value != null,
              decoration: InputDecoration(
                hintText: selectedMunicipality.value == null
                    ? 'Select city/municipality first'
                    : 'Enter barangay name',
                prefixIcon: const Icon(LucideIcons.users, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: !(enabled && selectedMunicipality.value != null),
                fillColor: Colors.grey.shade100,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _notifyIfComplete(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required bool enabled,
    required void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
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
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// PSGC data model
class PsgcData {
  final String region;
  final String province;
  final String municipality;
  final String barangay;

  PsgcData({
    required this.region,
    required this.province,
    required this.municipality,
    required this.barangay,
  });

  String get id {
    return '${region}_${province}_${municipality}_${barangay}'
        .replaceAll(' ', '_')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .toLowerCase();
  }

  String get fullAddress {
    final parts = [barangay, municipality, province];
    return parts.join(', ');
  }

  @override
  String toString() => 'PsgcData($fullAddress)';
}
