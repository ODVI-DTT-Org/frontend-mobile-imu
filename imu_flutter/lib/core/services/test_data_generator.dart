import 'dart:math';
import '../../services/local_storage/hive_service.dart';
import '../../features/clients/data/models/client_model.dart';

/// Generates test data for development and testing purposes
class TestDataGenerator {
  final HiveService _hiveService;
  final Random _random = Random();

  TestDataGenerator(this._hiveService);

  // Filipino names for test data
  static const _firstNames = [
    'Juan', 'Maria', 'Jose', 'Ana', 'Pedro', 'Rosa', 'Miguel', 'Lourdes',
    'Antonio', 'Teresa', 'Francisco', 'Elena', 'Manuel', 'Carmen', 'Fernando',
    'Rosalinda', 'Ricardo', 'Virginia', 'Eduardo', 'Gloria', 'Roberto', 'Lilia',
    'Benjamin', 'Norma', 'Alejandro', 'Fe', 'Ramon', 'Mercedes', 'Carlos', 'Natividad',
    'Danilo', 'Herminia', 'Ernesto', 'Rizalina', 'Felix', 'Salvacion', 'Rodolfo', 'Concepcion',
    'Wilfredo', 'Guadalupe', 'Jesus', 'Amalia', 'Rogelio', 'Esperanza', 'Cesar', 'Soledad',
    'Gilbert', 'Erlinda', 'Armando', 'Aurora',
  ];

  static const _lastNames = [
    'Santos', 'Reyes', 'Cruz', 'Bautista', 'Garcia', 'Mendoza', 'Torres', 'Castillo',
    'Santiago', 'Vargas', 'Rivera', 'Aquino', 'Gonzales', 'Navarro', 'Flores', 'Villanueva',
    'Ramos', 'De la Cruz', 'Diaz', 'Ferrer', 'Gomez', 'Hernandez', 'Jimenez', 'Lopez',
    'Martinez', 'Moreno', 'Nieto', 'Ortiz', 'Perez', 'Quintos', 'Rodriguez', 'Sanchez',
    'Tiwala', 'Umali', 'Valdez', 'Wong', 'Xerex', 'Yabut', 'Zapanta', 'Agbayani',
    'Baltazar', 'Cayetano', 'Dimalanta', 'Estanislao', 'Fernando', 'Galang', 'Hidalgo', 'Ignacio',
  ];

  static const _agencies = [
    'Philippine National Police (PNP)',
    'Bureau of Fire Protection (BFP)',
    'Bureau of Jail Management and Penology (BJMP)',
    'Armed Forces of the Philippines (AFP)',
    'Philippine Coast Guard (PCG)',
  ];

  static const _departments = [
    'Operations', 'Administration', 'Finance', 'Human Resources',
    'Logistics', 'Communications', 'Training', 'Security',
  ];

  static const _positions = [
    'Director', 'Chief', 'Supervisor', 'Officer', 'Inspector',
    'Commander', 'Captain', 'Lieutenant', 'Sergeant', 'Patrolman',
  ];

  static const _barangays = [
    'Barangay 1', 'Barangay 2', 'Barangay 3', 'Barangay 4', 'Barangay 5',
    'San Isidro', 'San Jose', 'San Pedro', 'Santa Cruz', 'Santa Rosa',
    'Poblacion', 'Central', 'East', 'West', 'North', 'South',
  ];

  static const _cities = [
    'Manila', 'Quezon City', 'Makati', 'Pasig', 'Taguig',
    'Mandaluyong', 'San Juan', 'Pasay', 'Parañaque', 'Las Piñas',
    'Muntinlupa', 'Caloocan', 'Malabon', 'Navotas', 'Valenzuela',
    'Marikina', 'Antipolo', 'Cainta', 'Taytay', 'Angono',
  ];

  static const _provinces = [
    'Metro Manila', 'Rizal', 'Cavite', 'Laguna', 'Bulacan',
    'Pampanga', 'Batangas', 'Quezon', 'Bataan', 'Zambales',
  ];

  /// Generate a small dataset (~10 clients)
  Future<int> generateSmallDataset() async {
    return await _generateClients(10);
  }

  /// Generate a large dataset (~100 clients)
  Future<int> generateLargeDataset() async {
    return await _generateClients(100);
  }

  /// Generate a limit breaker dataset (~1000 clients)
  Future<int> generateLimitBreakerDataset() async {
    return await _generateClients(1000);
  }

  /// Generate custom number of clients
  Future<int> generateCustomDataset(int count) async {
    return await _generateClients(count);
  }

  /// Generate clients with random data
  Future<int> _generateClients(int count) async {
    if (!_hiveService.isInitialized) {
      await _hiveService.init();
    }

    final batch = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final clientId = 'test_${now.millisecondsSinceEpoch}_$i';
      final firstName = _firstNames[_random.nextInt(_firstNames.length)];
      final lastName = _lastNames[_random.nextInt(_lastNames.length)];
      final middleName = _random.nextBool()
          ? _firstNames[_random.nextInt(_firstNames.length)]
          : null;

      // Random birth date (50-80 years ago for retirees)
      final age = 50 + _random.nextInt(31);
      final birthDate = DateTime.now().subtract(Duration(days: age * 365 + _random.nextInt(365)));

      // Random touchpoints (0-7)
      final touchpoints = _generateRandomTouchpoints(clientId, _random.nextInt(8));

      // Determine client type based on touchpoints
      final clientType = touchpoints.length >= 7 ? ClientType.existing : ClientType.potential;

      // Random product type
      final productTypes = ProductType.values;
      final productType = productTypes[_random.nextInt(productTypes.length)];

      // Random market type
      final marketTypes = MarketType.values;
      final marketType = marketTypes[_random.nextInt(marketTypes.length)];

      // Random pension type based on product type
      PensionType pensionType;
      switch (productType) {
        case ProductType.sssPensioner:
          pensionType = PensionType.sss;
          break;
        case ProductType.gsisPensioner:
          pensionType = PensionType.gsis;
          break;
        case ProductType.private:
          pensionType = PensionType.private;
          break;
      }

      final clientData = {
        'id': clientId,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'birthDate': birthDate.toIso8601String(),
        'agencyName': _agencies[_random.nextInt(_agencies.length)],
        'department': _departments[_random.nextInt(_departments.length)],
        'position': _positions[_random.nextInt(_positions.length)],
        'employmentStatus': ['Permanent', 'Casual', 'JO (Job Order)'][_random.nextInt(3)],
        'payrollDate': ['30 / 15', '30 / 10', '25'][_random.nextInt(3)],
        'tenure': 10 + _random.nextInt(30),
        'contactNumber': _generatePhoneNumber(),
        'email': _random.nextBool()
            ? '${firstName.toLowerCase()}.${lastName.toLowerCase()}@email.com'
            : null,
        'facebookLink': _random.nextBool()
            ? 'https://facebook.com/${firstName.toLowerCase()}.${lastName.toLowerCase()}'
            : null,
        'clientType': clientType.name,
        'productType': productType.name,
        'pensionType': pensionType.name,
        'marketType': marketType.name,
        'addresses': [
          {
            'id': '${clientId}_addr_1',
            'street': '${_random.nextInt(500) + 1} ${_lastNames[_random.nextInt(_lastNames.length)]} Street',
            'barangay': _barangays[_random.nextInt(_barangays.length)],
            'city': _cities[_random.nextInt(_cities.length)],
            'province': _provinces[_random.nextInt(_provinces.length)],
            'isPrimary': true,
          }
        ],
        'phoneNumbers': [
          {
            'id': '${clientId}_phone_1',
            'number': _generatePhoneNumber(),
            'label': 'Mobile',
            'isPrimary': true,
          }
        ],
        'touchpoints': touchpoints.map((t) => {
          'id': t['id'],
          'clientId': t['clientId'],
          'touchpointNumber': t['touchpointNumber'],
          'type': t['type'],
          'date': t['date'],
          'reason': t['reason'],
          'remarks': t['remarks'],
          'createdAt': t['createdAt'],
        }).toList(),
        'remarks': _random.nextBool()
            ? 'Test client generated for development purposes.'
            : null,
        'createdAt': now.subtract(Duration(days: _random.nextInt(365))).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      batch.add({'id': clientId, 'data': clientData});
    }

    // Save all clients
    for (final item in batch) {
      await _hiveService.saveClient(item['id'], item['data']);
    }

    return count;
  }

  /// Generate random touchpoints following the 7-touchpoint pattern
  List<Map<String, dynamic>> _generateRandomTouchpoints(String clientId, int count) {
    if (count == 0) return [];

    // Pattern: Visit-Call-Call-Visit-Call-Call-Visit
    final pattern = [
      TouchpointType.visit,
      TouchpointType.call,
      TouchpointType.call,
      TouchpointType.visit,
      TouchpointType.call,
      TouchpointType.call,
      TouchpointType.visit,
    ];

    final reasons = TouchpointReason.values;
    final now = DateTime.now();
    final touchpoints = <Map<String, dynamic>>[];

    for (int i = 0; i < count && i < 7; i++) {
      final daysAgo = (count - i) * 7 + _random.nextInt(7);
      final date = now.subtract(Duration(days: daysAgo));

      touchpoints.add({
        'id': '${clientId}_tp_$i',
        'clientId': clientId,
        'touchpointNumber': i + 1,
        'type': pattern[i].name,
        'date': date.toIso8601String(),
        'reason': reasons[_random.nextInt(reasons.length)].name,
        'remarks': _random.nextBool() ? 'Touchpoint ${i + 1} completed.' : null,
        'createdAt': date.toIso8601String(),
      });
    }

    return touchpoints;
  }

  /// Generate a random Philippine phone number
  String _generatePhoneNumber() {
    final prefixes = ['917', '918', '919', '920', '921', '922', '923', '927', '928', '929',
        '930', '935', '936', '938', '939', '945', '946', '947', '948', '949',
        '950', '951', '953', '954', '955', '956', '961', '963', '965', '966',
        '967', '968', '969', '970', '971', '975', '976', '977', '978', '979'];
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final number = _random.nextInt(10000000).toString().padLeft(7, '0');
    return '+63 $prefix $number';
  }

  /// Clear all test data (clients with IDs starting with 'test_')
  Future<int> clearTestData() async {
    if (!_hiveService.isInitialized) {
      await _hiveService.init();
    }

    final allClients = _hiveService.getAllClients();
    int deleted = 0;

    for (final client in allClients) {
      if (client['id'].toString().startsWith('test_')) {
        await _hiveService.deleteClient(client['id']);
        deleted++;
      }
    }

    return deleted;
  }

  /// Clear all client data
  Future<int> clearAllData() async {
    if (!_hiveService.isInitialized) {
      await _hiveService.init();
    }

    final allClients = _hiveService.getAllClients();
    int deleted = 0;

    for (final client in allClients) {
      await _hiveService.deleteClient(client['id']);
      deleted++;
    }

    return deleted;
  }

  /// Get current data statistics
  Map<String, int> getDataStats() {
    if (!_hiveService.isInitialized) return {};

    final allClients = _hiveService.getAllClients();

    int testClients = 0;
    int realClients = 0;
    int potentialClients = 0;
    int existingClients = 0;
    int totalTouchpoints = 0;

    for (final client in allClients) {
      if (client['id'].toString().startsWith('test_')) {
        testClients++;
      } else {
        realClients++;
      }

      final clientType = client['clientType']?.toString().toLowerCase();
      if (clientType == 'potential') {
        potentialClients++;
      } else if (clientType == 'existing') {
        existingClients++;
      }

      final touchpoints = client['touchpoints'] as List?;
      if (touchpoints != null) {
        totalTouchpoints += touchpoints.length;
      }
    }

    return {
      'total': allClients.length,
      'testClients': testClients,
      'realClients': realClients,
      'potentialClients': potentialClients,
      'existingClients': existingClients,
      'totalTouchpoints': totalTouchpoints,
    };
  }
}
