import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// PSGC (Philippine Standard Geographic Code) Selector
/// Cascading dropdown: Region → Province → City/Municipality → Barangay
class PSGCSelector extends HookWidget {
  final String? initialPsgcId;
  final Function(PsgcData) onPsgcSelected;
  final bool enabled;

  const PSGCSelector({
    super.key,
    this.initialPsgcId,
    required this.onPsgcSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selectedRegion = useState<String?>(null);
    final selectedProvince = useState<String?>(null);
    final selectedMunicipality = useState<String?>(null);
    final selectedBarangay = useState<String?>(null);
    final isLoading = useState(false);

    // TODO: Load PSGC data from database/PowerSync
    // For now, using mock data
    final regions = useMemoized(() => [
      'National Capital Region (NCR)',
      'Cordillera Administrative Region (CAR)',
      'Region I - Ilocos Region',
      'Region II - Cagayan Valley',
      'Region III - Central Luzon',
      'Region IV-A - CALABARZON',
      'Region IV-B - MIMAROPA',
      'Region V - Bicol Region',
      'Region VI - Western Visayas',
      'Region VII - Central Visayas',
      'Region VIII - Eastern Visayas',
      'Region IX - Zamboanga Peninsula',
      'Region X - Northern Mindanao',
      'Region XI - Davao Region',
      'Region XII - SOCCSKSARGEN',
      'Region XIII - Caraga',
      'Bangsamoro Autonomous Region in Muslim Mindanao (BARMM)',
    ]);

    final provinces = useMemoized(() => {
      if (selectedRegion.value == null) return <String>[];
      // Mock data - in production, load from database
      return {
        'National Capital Region (NCR)': [
          'Metro Manila',
          'Quezon City',
          'Manila',
          'Caloocan',
        ],
        'Region IV-A - CALABARZON': [
          'Cavite',
          'Laguna',
          'Batangas',
          'Rizal',
          'Quezon',
        ],
      }[selectedRegion.value] ?? <String>[];
    }, [selectedRegion.value]);

    final municipalities = useMemoized(() => {
      if (selectedProvince.value == null) return <String>[];
      // Mock data
      return {
        'Metro Manila': [
          'Manila',
          'Makati',
          'Pasig',
          'Taguig',
          'Pasay',
        ],
        'Cavite': [
          'Dasmariñas',
          'Bacoor',
          'Imus',
          'Dasmariñas City',
        ],
      }[selectedProvince.value] ?? <String>[];
    }, [selectedProvince.value]);

    final barangays = useMemoized(() => {
      if (selectedMunicipality.value == null) return <String>[];
      // Mock data
      return {
        'Dasmariñas': [
          'Barangay 1',
          'Barangay 2',
          'Barangay 3',
          'Barangay 123',
        ],
        'Makati': [
          'Poblacion',
          'Bel-Air',
          'San Lorenzo',
        ],
      }[selectedMunicipality.value] ?? <String>[];
    }, [selectedMunicipality.value]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Region Dropdown
        _buildDropdown(
          label: 'Region *',
          value: selectedRegion.value,
          items: regions,
          hint: 'Select Region',
          icon: LucideIcons.map,
          enabled: enabled,
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

        // Province Dropdown
        _buildDropdown(
          label: 'Province',
          value: selectedProvince.value,
          items: provinces,
          hint: selectedRegion.value == null ? 'Select region first' : 'Select Province',
          icon: LucideIcons.map,
          enabled: enabled && selectedRegion.value != null,
          onChanged: enabled && selectedRegion.value != null
              ? (value) {
                  selectedProvince.value = value;
                  selectedMunicipality.value = null;
                  selectedBarangay.value = null;
                }
              : null,
        ),

        const SizedBox(height: 12),

        // City/Municipality Dropdown
        _buildDropdown(
          label: 'City/Municipality',
          value: selectedMunicipality.value,
          items: municipalities,
          hint: selectedProvince.value == null ? 'Select province first' : 'Select City/Municipality',
          icon: LucideIcons.building,
          enabled: enabled && selectedProvince.value != null,
          onChanged: enabled && selectedProvince.value != null
              ? (value) {
                  selectedMunicipality.value = value;
                  selectedBarangay.value = null;
                }
              : null,
        ),

        const SizedBox(height: 12),

        // Barangay Dropdown
        _buildDropdown(
          label: 'Barangay',
          value: selectedBarangay.value,
          items: barangays,
          hint: selectedMunicipality.value == null ? 'Select city first' : 'Select Barangay',
          icon: LucideIcons.users,
          enabled: enabled && selectedMunicipality.value != null,
          onChanged: enabled && selectedMunicipality.value != null
              ? (value) {
                  selectedBarangay.value = value;
                  // Emit PSGC data
                  final psgcData = PsgcData(
                    region: selectedRegion.value!,
                    province: selectedProvince.value!,
                    municipality: selectedMunicipality.value!,
                    barangay: selectedBarangay.value!,
                  );
                  onPsgcSelected(psgcData);
                }
              : null,
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

  /// Generate a unique ID for PSGC data
  /// In production, this should match the actual PSGC ID from the database
  String get id {
    return '${region}_${province}_${municipality}_${barangay}'
        .replaceAll(' ', '_')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .toLowerCase();
  }

  /// Get full address string
  String get fullAddress {
    final parts = [
      barangay,
      municipality,
      province,
    ];
    return parts.join(', ');
  }

  @override
  String toString() {
    return 'PsgcData($fullAddress)';
  }
}
