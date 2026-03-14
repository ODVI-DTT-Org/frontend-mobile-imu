import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:collection/collection.dart';
import 'package:imu_flutter/services/api/pocketbase_client.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Client API service for PocketBase backend
class ClientApiService {
  final PocketBase _pb;

  ClientApiService({required PocketBase pb}) : _pb = pb;

  /// Fetch clients with pagination
  Future<List<Client>> fetchClients({
    int page = 1,
    int perPage = 50,
    String? filter,
    String? sort,
    String? expand,
  }) async {
    try {
      debugPrint('ClientApiService: Fetching clients (page: $page, perPage: $perPage)');

    final result = await _pb.collection('clients').getList(
      page: page,
      perPage: perPage,
      filter: filter,
      sort: sort,
      expand: expand ?? 'addresses,phone_numbers',
    );

    debugPrint('ClientApiService: Fetched ${result.items.length} clients');

    return result.items.map((item) => _mapToClient(item)).toList();
    } on ClientException catch (e) {
      debugPrint('ClientApiService: Error fetching clients - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch clients',
        originalError: e,
      );
    }
  }

  /// Fetch single client by ID
  Future<Client> fetchClient(String id) async {
    try {
      debugPrint('ClientApiService: Fetching client $id');

      final record = await _pb.collection('clients').getOne(
        id,
        expand: 'addresses,phone_numbers,touchpoints',
      );

      return _mapToClient(record);
    } on ClientException catch (e) {
      debugPrint('ClientApiService: Error fetching client - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch client',
        originalError: e,
      );
    }
  }

  /// Create a new client
  Future<Client> createClient(Client client) async {
    try {
      debugPrint('ClientApiService: Creating client ${client.fullName}');

      final body = {
        'first_name': client.firstName,
        'last_name': client.lastName,
        'middle_name': client.middleName,
        'client_type': client.clientType.name.toUpperCase(),
        'product_type': client.productType.name,
        'pension_type': client.pensionType.name,
        'market_type': client.marketType?.name,
        'agency_name': client.agencyName,
        'department': client.department,
        'position': client.position,
        'email': client.email,
        'pan': client.pan,
        'remarks': client.remarks,
      };

      final record = await _pb.collection('clients').create(body: body);

      // Create addresses and phone numbers if provided
      for (final address in client.addresses) {
        await _pb.collection('addresses').create(body: {
          'client': record.id,
          'street': address.street,
          'barangay': address.barangay,
          'city': address.city,
          'province': address.province,
          'zip_code': address.zipCode,
          'is_primary': address.isPrimary,
        });
      }

      for (final phone in client.phoneNumbers) {
        await _pb.collection('phone_numbers').create(body: {
          'client': record.id,
          'number': phone.number,
          'label': phone.label,
          'is_primary': phone.isPrimary,
        });
      }

      return _mapToClient(record);
    } on ClientException catch (e) {
      debugPrint('ClientApiService: Error creating client - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to create client',
        originalError: e,
      );
    }
  }

  /// Update an existing client
  Future<Client> updateClient(Client client) async {
    try {
      debugPrint('ClientApiService: Updating client ${client.id}');

      final body = {
        'first_name': client.firstName,
        'last_name': client.lastName,
        'middle_name': client.middleName,
        'client_type': client.clientType.name.toUpperCase(),
        'product_type': client.productType.name,
        'pension_type': client.pensionType.name,
        'market_type': client.marketType?.name,
        'agency_name': client.agencyName,
        'department': client.department,
        'position': client.position,
        'email': client.email,
        'pan': client.pan,
        'remarks': client.remarks,
      };

      final record = await _pb.collection('clients').update(client.id, body: body);

      return _mapToClient(record);
    } on ClientException catch (e) {
      debugPrint('ClientApiService: Error updating client - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update client',
        originalError: e,
      );
    }
  }

  /// Delete a client
  Future<void> deleteClient(String id) async {
    try {
      debugPrint('ClientApiService: Deleting client $id');

      await _pb.collection('clients').delete(id);

      debugPrint('ClientApiService: Client deleted');
    } on ClientException catch (e) {
      debugPrint('ClientApiService: Error deleting client - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('ClientApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to delete client',
        originalError: e,
      );
    }
  }

  /// Map PocketBase record to Client model
  Client _mapToClient(RecordModel record) {
    final data = record.data;

    // Parse addresses from expanded data
    final addresses = <Address>[];
    if (data['expand']?['addresses'] != null) {
      for (final addr in data['expand']['addresses']) {
        addresses.add(Address(
          id: addr['id'] ?? '',
          street: addr['street'] ?? '',
          barangay: addr['barangay'],
          city: addr['city'] ?? '',
          province: addr['province'],
          zipCode: addr['zip_code'],
          isPrimary: addr['is_primary'] ?? false,
          latitude: addr['latitude']?.toDouble(),
          longitude: addr['longitude']?.toDouble(),
        ));
      }
    }

    // Parse phone numbers from expanded data
    final phoneNumbers = <PhoneNumber>[];
    if (data['expand']?['phone_numbers'] != null) {
      for (final phone in data['expand']['phone_numbers']) {
        phoneNumbers.add(PhoneNumber(
          id: phone['id'] ?? '',
          number: phone['number'] ?? '',
          label: phone['label'],
          isPrimary: phone['is_primary'] ?? false,
        ));
      }
    }

    return Client(
      id: record.id,
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      middleName: data['middle_name'],
      clientType: _parseClientType(data['client_type']),
      productType: _parseProductType(data['product_type']) ?? ProductType.sssPensioner,
      pensionType: _parsePensionType(data['pension_type']) ?? PensionType.sss,
      marketType: _parseMarketType(data['market_type']),
      addresses: addresses,
      phoneNumbers: phoneNumbers,
      touchpoints: [], // Will be fetched separately
      createdAt: DateTime.parse(data['created'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updated'] != null ? DateTime.parse(data['updated']) : null,
    );
  }

  ClientType _parseClientType(String? value) {
    if (value == null) return ClientType.potential;
    return ClientType.values.firstWhere(
      (type) => type.name.toUpperCase() == value.toUpperCase(),
      orElse: () => ClientType.potential,
    );
  }

  ProductType? _parseProductType(String? value) {
    if (value == null) return null;
    return ProductType.values.firstWhereOrNull(
      (type) => type.name.toLowerCase() == value.toString().toLowerCase().replaceAll('_', ' ').replaceAll(' ', '_'),
    );
  }

  MarketType? _parseMarketType(String? value) {
    if (value == null) return null;
    try {
      return MarketType.values.firstWhere(
        (type) => type.name.toLowerCase() == value.toString().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  PensionType? _parsePensionType(String? value) {
    if (value == null) return null;
    try {
      return PensionType.values.firstWhere(
        (type) => type.name.toLowerCase() == value.toString().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Provider for ClientApiService
final clientApiServiceProvider = Provider<ClientApiService>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return ClientApiService(pb: pb);
  });
