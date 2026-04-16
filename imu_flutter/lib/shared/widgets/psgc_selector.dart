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

    final provinces = useMemoized(() {
      if (selectedRegion.value == null) return <String>[];
      // Mock data - in production, load from database
      final provinceMap = {
        'National Capital Region (NCR)': [
          'Metro Manila',
          'Quezon City',
          'Manila',
          'Caloocan',
        ],
        'Cordillera Administrative Region (CAR)': [
          'Abra',
          'Apayao',
          'Benguet',
          'Ifugao',
          'Kalinga',
          'Mountain Province',
        ],
        'Region I - Ilocos Region': [
          'Ilocos Norte',
          'Ilocos Sur',
          'La Union',
          'Pangasinan',
        ],
        'Region II - Cagayan Valley': [
          'Batanes',
          'Cagayan',
          'Isabela',
          'Nueva Vizcaya',
          'Quirino',
        ],
        'Region III - Central Luzon': [
          'Aurora',
          'Bataan',
          'Bulacan',
          'Nueva Ecija',
          'Pampanga',
          'Tarlac',
          'Zambales',
        ],
        'Region IV-A - CALABARZON': [
          'Cavite',
          'Laguna',
          'Batangas',
          'Rizal',
          'Quezon',
        ],
        'Region IV-B - MIMAROPA': [
          'Marinduque',
          'Occidental Mindoro',
          'Oriental Mindoro',
          'Palawan',
          'Romblon',
        ],
        'Region V - Bicol Region': [
          'Albay',
          'Camarines Norte',
          'Camarines Sur',
          'Catanduanes',
          'Masbate',
          'Sorsogon',
        ],
        'Region VI - Western Visayas': [
          'Aklan',
          'Antique',
          'Capiz',
          'Guimaras',
          'Iloilo',
          'Negros Occidental',
        ],
        'Region VII - Central Visayas': [
          'Bohol',
          'Cebu',
          'Negros Oriental',
          'Siquijor',
        ],
        'Region VIII - Eastern Visayas': [
          'Biliran',
          'Eastern Samar',
          'Leyte',
          'Northern Samar',
          'Samar',
          'Southern Leyte',
        ],
        'Region IX - Zamboanga Peninsula': [
          'Zamboanga del Norte',
          'Zamboanga del Sur',
          'Zamboanga Sibugay',
        ],
        'Region X - Northern Mindanao': [
          'Bukidnon',
          'Camiguin',
          'Lanao del Norte',
          'Misamis Occidental',
          'Misamis Oriental',
        ],
        'Region XI - Davao Region': [
          'Compostela Valley',
          'Davao del Norte',
          'Davao del Sur',
          'Davao Occidental',
        ],
        'Region XII - SOCCSKSARGEN': [
          'North Cotabato',
          'Sarangani',
          'South Cotabato',
          'Sultan Kudarat',
        ],
        'Region XIII - Caraga': [
          'Agusan del Norte',
          'Agusan del Sur',
          'Dinagat Islands',
          'Surigao del Norte',
          'Surigao del Sur',
        ],
        'Bangsamoro Autonomous Region in Muslim Mindanao (BARMM)': [
          'Basilan',
          'Lanao del Sur',
          'Maguindanao',
          'Sulu',
          'Tawi-Tawi',
        ],
      };
      return provinceMap[selectedRegion.value] ?? <String>[];
    }, [selectedRegion.value]);

    final municipalities = useMemoized(() {
      if (selectedProvince.value == null) return <String>[];
      // Mock data - in production, load from database
      final municipalityMap = {
        'Metro Manila': [
          'Manila',
          'Makati',
          'Pasig',
          'Taguig',
          'Pasay',
        ],
        'Quezon City': [
          'Quezon City',
        ],
        'Manila': [
          'Manila',
        ],
        'Caloocan': [
          'Caloocan',
        ],
        'Abra': [
          'Bangued',
          'Boliney',
          'Bucay',
        ],
        'Apayao': [
          'Calanasan',
          'Conner',
          'Kabugao',
        ],
        'Benguet': [
          'Baguio',
          'La Trinidad',
          'Itogon',
        ],
        'Ifugao': [
          'Lagawe',
          'Lamut',
          'Kiangan',
        ],
        'Kalinga': [
          'Tabuk',
          'Rizal',
          'Tanudan',
        ],
        'Mountain Province': [
          'Bontoc',
          'Sadanga',
          'Barlig',
        ],
        'Ilocos Norte': [
          'Laoag',
          'Batac',
          'San Nicolas',
        ],
        'Ilocos Sur': [
          'Vigan',
          'Candon',
          'Bantay',
        ],
        'La Union': [
          'San Fernando',
          'Agoo',
          'Bauang',
        ],
        'Pangasinan': [
          'Lingayen',
          'Dagupan',
          'San Carlos',
        ],
        'Batanes': [
          'Basco',
          'Itbayat',
          'Sabtang',
        ],
        'Cagayan': [
          'Tuguegarao',
          'Aparri',
          'Gonzaga',
        ],
        'Isabela': [
          'Ilagan',
          'Cauayan',
          'Santiago',
        ],
        'Nueva Vizcaya': [
          'Bayombong',
          'Solano',
          'Bambang',
        ],
        'Quirino': [
          'Cabarroguis',
          'Diffun',
          'Maddela',
        ],
        'Aurora': [
          'Baler',
          'Maria Aurora',
          'San Luis',
        ],
        'Bataan': [
          'Balanga',
          'Dinalupihan',
          'Mariveles',
        ],
        'Bulacan': [
          'Malolos',
          'Meycauayan',
          'San Jose del Monte',
        ],
        'Nueva Ecija': [
          'Palayan',
          'Cabanatuan',
          'Gapan',
        ],
        'Pampanga': [
          'San Fernando',
          'Angeles',
          'Mabalacat',
        ],
        'Tarlac': [
          'Tarlac',
          'Concepcion',
          'Capas',
        ],
        'Zambales': [
          'Olongapo',
          'Iba',
          'Subic',
        ],
        'Cavite': [
          'Dasmariñas',
          'Bacoor',
          'Imus',
          'Dasmariñas City',
        ],
        'Laguna': [
          'Santa Cruz',
          'San Pedro',
          'Biñan',
        ],
        'Batangas': [
          'Batangas',
          'Lipa',
          'Tanauan',
        ],
        'Rizal': [
          'Antipolo',
          'Taytay',
          'Cainta',
        ],
        'Quezon': [
          'Lucena',
          'Tayabas',
          'Sariaya',
        ],
        'Marinduque': [
          'Boac',
          'Gasan',
          'Santa Cruz',
        ],
        'Occidental Mindoro': [
          'Mamburao',
          'San Jose',
          'Sablayan',
        ],
        'Oriental Mindoro': [
          'Calapan',
          'Puerto Galera',
          'Baco',
        ],
        'Palawan': [
          'Puerto Princesa',
          'Coron',
          'El Nido',
        ],
        'Romblon': [
          'Romblon',
          'Odiongan',
          'San Agustin',
        ],
        'Albay': [
          'Legazpi',
          'Tabaco',
          'Ligao',
        ],
        'Camarines Norte': [
          'Daet',
          'Vinzons',
          'Basud',
        ],
        'Camarines Sur': [
          'Naga',
          'Iriga',
          'Pili',
        ],
        'Catanduanes': [
          'Virac',
          'Bato',
          'San Miguel',
        ],
        'Masbate': [
          'Masbate',
          'Cataingan',
          'Milagros',
        ],
        'Sorsogon': [
          'Sorsogon',
          'Bulan',
          'Gubat',
        ],
        'Aklan': [
          'Kalibo',
          'Boracay',
          'New Washington',
        ],
        'Antique': [
          'San Jose',
          'Sibalom',
          'Belison',
        ],
        'Capiz': [
          'Roxas',
          'Panay',
          'Tapaz',
        ],
        'Guimaras': [
          'Jordan',
          'Buenavista',
          'Nueva Valencia',
        ],
        'Iloilo': [
          'Iloilo',
          'Passi',
          'Oton',
        ],
        'Negros Occidental': [
          'Bacolod',
          'Silay',
          'Bago',
        ],
        'Bohol': [
          'Tagbilaran',
          'Carmen',
          'Jagna',
        ],
        'Cebu': [
          'Cebu',
          'Mandaue',
          'Lapu-Lapu',
        ],
        'Negros Oriental': [
          'Dumaguete',
          'Bais',
          'Canlaon',
        ],
        'Siquijor': [
          'Siquijor',
          'Lazi',
          'San Juan',
        ],
        'Biliran': [
          'Naval',
          'Caibiran',
          'Culaba',
        ],
        'Eastern Samar': [
          'Borongan',
          'Guiuan',
          'Salcedo',
        ],
        'Leyte': [
          'Tacloban',
          'Ormoc',
          'Baybay',
        ],
        'Northern Samar': [
          'Catarman',
          'Allen',
          'Laoang',
        ],
        'Samar': [
          'Catbalogan',
          'Calbayog',
          'Gandara',
        ],
        'Southern Leyte': [
          'Maasin',
          'Sogod',
          'Bontoc',
        ],
        'Zamboanga del Norte': [
          'Dipolog',
          'Dapitan',
          'Sindangan',
        ],
        'Zamboanga del Sur': [
          'Zamboanga',
          'Pagadian',
          'Ipil',
        ],
        'Zamboanga Sibugay': [
          'Ipil',
          'Kabasalan',
          'Naga',
        ],
        'Bukidnon': [
          'Malaybalay',
          'Valencia',
          'Maramag',
        ],
        'Camiguin': [
          'Mambajao',
          'Catarman',
          'Mahinog',
        ],
        'Lanao del Norte': [
          'Iligan',
          'Tubod',
          'Lala',
        ],
        'Misamis Occidental': [
          'Oroquieta',
          'Ozamiz',
          'Tangub',
        ],
        'Misamis Oriental': [
          'Cagayan de Oro',
          'Gingoog',
          'El Salvador',
        ],
        'Compostela Valley': [
          'Nabunturan',
          'Monkayo',
          'Compostela',
        ],
        'Davao del Norte': [
          'Tagum',
          'Panabo',
          'Samal',
        ],
        'Davao del Sur': [
          'Davao',
          'Digos',
          'Mati',
        ],
        'Davao Occidental': [
          'Malita',
          'Jose Abad Santos',
          'Santa Maria',
        ],
        'North Cotabato': [
          'Kidapawan',
          'Midsayap',
          'Kabacan',
        ],
        'Sarangani': [
          'Alabel',
          'Glan',
          'Kiamba',
        ],
        'South Cotabato': [
          'Koronadal',
          'General Santos',
          'Polomolok',
        ],
        'Sultan Kudarat': [
          'Isulan',
          'Tacurong',
          'President Quirino',
        ],
        'Agusan del Norte': [
          'Cabadbaran',
          'Butuan',
          'Carmen',
        ],
        'Agusan del Sur': [
          'Prosperidad',
          'Bayugan',
          'San Francisco',
        ],
        'Dinagat Islands': [
          'Dinagat',
          'Libjo',
          'Tubajon',
        ],
        'Surigao del Norte': [
          'Surigao',
          'Siargao',
          'Claver',
        ],
        'Surigao del Sur': [
          'Tandag',
          'Bislig',
          'Carrascal',
        ],
        'Basilan': [
          'Lamitan',
          'Isabela',
          'Tipo-Tipo',
        ],
        'Lanao del Sur': [
          'Marawi',
          'Lumba-Bayabao',
          'Butig',
        ],
        'Maguindanao': [
          'Shariff Aguak',
          'Buldon',
          'Datu Odin Sinsuat',
        ],
        'Sulu': [
          'Jolo',
          'Talipao',
          'Pata',
        ],
        'Tawi-Tawi': [
          'Bongao',
          'Mapun',
          'Sitangkai',
        ],
      };
      return municipalityMap[selectedProvince.value] ?? <String>[];
    }, [selectedProvince.value]);

    final barangays = useMemoized(() {
      if (selectedMunicipality.value == null) return <String>[];
      // Mock data - generate default barangays for any municipality
      final municipalityName = selectedMunicipality.value!;
      final defaultBarangays = List.generate(10, (index) => 'Barangay ${index + 1}');
      return defaultBarangays;
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
