import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../location/enhanced_location_service.dart' show LocationAddress;

/// Mapbox Geocoding Service for reverse geocoding
/// Converts GPS coordinates to structured addresses using Mapbox API
class MapboxGeocodingService {
  static final MapboxGeocodingService _instance = MapboxGeocodingService._internal();
  factory MapboxGeocodingService() => _instance;
  MapboxGeocodingService._internal();

  String _accessToken = '';

  /// Set Mapbox access token
  void setAccessToken(String token) {
    _accessToken = token;
  }

  /// Check if service is configured
  bool get isConfigured => _accessToken.isNotEmpty;

  /// Reverse geocode coordinates to address using Mapbox API
  ///
  /// Returns [LocationAddress] with structured components or null if failed
  Future<LocationAddress?> reverseGeocode(
    double latitude,
    double longitude, {
    bool includeStreetDetails = true,
  }) async {
    if (_accessToken.isEmpty) {
      debugPrint('MapboxGeocodingService: No access token configured');
      return null;
    }

    try {
      // Mapbox requires longitude,latitude order
      final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json'
        '?access_token=$_accessToken'
        '&types=${includeStreetDetails ? 'address,place,region,postcode,country' : 'place,region,country'}'
      );

      debugPrint('MapboxGeocodingService: Requesting $url');

      final dio = Dio();
      final response = await dio.get(
        url.toString(),
        options: Options(headers: {'Accept': 'application/json'}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('MapboxGeocodingService: Request timeout');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['features'] != null && data['features'].isNotEmpty) {
          return _parseMapboxResponse(data['features'] as List<dynamic>, latitude, longitude);
        } else {
          debugPrint('MapboxGeocodingService: No features found in response');
          return null;
        }
      } else if (response.statusCode == 401) {
        debugPrint('MapboxGeocodingService: Invalid access token');
        return null;
      } else if (response.statusCode == 429) {
        debugPrint('MapboxGeocodingService: Rate limit exceeded');
        return null;
      } else {
        debugPrint('MapboxGeocodingService: HTTP ${response.statusCode}');
        debugPrint('MapboxGeocodingService: ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('MapboxGeocodingService: Error - $e');
      return null;
    }
  }

  /// Parse Mapbox response with all features into LocationAddress
  LocationAddress _parseMapboxResponse(
    List<dynamic> features,
    double latitude,
    double longitude,
  ) {
    String? street;
    String? barangay;
    String? municipality;
    String? province;
    String? region;
    String? postcode;
    String? country;
    String? fullAddress;

    debugPrint('MapboxGeocodingService: Parsing ${features.length} features');

    // Iterate through all features and extract data based on place_type
    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;

      final placeType = feature['place_type'] as List<dynamic>?;
      final text = feature['text'] as String?;
      final placeName = feature['place_name'] as String?;

      debugPrint('MapboxGeocodingService: Feature - placeType: $placeType, text: $text');

      // Store the most detailed full address (from the first/most relevant feature)
      if (fullAddress == null && placeName != null) {
        fullAddress = placeName;
      }

      if (placeType == null || text == null) continue;

      // Extract based on place_type
      if (placeType.contains('address') || placeType.contains('street')) {
        // Street level address
        if (street == null) street = text;
      } else if (placeType.contains('locality')) {
        // Locality is barangay level in Philippines
        barangay ??= text;
        debugPrint('MapboxGeocodingService: Set barangay to: $text');
      } else if (placeType.contains('place')) {
        // Place is municipality/city level (this is what we were missing!)
        if (municipality == null) {
          municipality = text;
          debugPrint('MapboxGeocodingService: Set municipality to: $text');
        }
      } else if (placeType.contains('region')) {
        // Region could be either region or province
        if (text.contains('Luzon') ||
            text.contains('Visayas') ||
            text.contains('Mindanao') ||
            text.contains('Region') ||
            text.contains('NCR') ||
            text.contains('CAR')) {
          // This is a region (e.g., "Central Luzon")
          region ??= text;
          debugPrint('MapboxGeocodingService: Set region to: $text');

          // Extract region code if available
          final shortCode = feature['short_code'] as String?;
          if (shortCode != null && region != null) {
            region = '$region ($shortCode)';
          }
        } else {
          // This is a province (e.g., "Bulacan")
          province ??= text;
          debugPrint('MapboxGeocodingService: Set province to: $text');
        }
      } else if (placeType.contains('postcode')) {
        postcode ??= text;
        debugPrint('MapboxGeocodingService: Set postcode to: $text');
      } else if (placeType.contains('country')) {
        country ??= text;
        debugPrint('MapboxGeocodingService: Set country to: $text');
      }
    }

    // Build full address if not yet set
    fullAddress ??= [
      if (street != null) street,
      if (barangay != null) barangay,
      if (municipality != null) municipality,
      if (province != null) province,
      if (region != null) region,
      if (postcode != null) postcode,
      if (country != null) country,
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    final address = LocationAddress(
      fullAddress: fullAddress,
      street: street,
      barangay: barangay,
      municipality: municipality,
      province: province,
      region: region,
      country: country ?? 'Philippines',
      source: 'Mapbox',
    );

    debugPrint('MapboxGeocodingService: Parsed address - $fullAddress');
    debugPrint('  Street: $street');
    debugPrint('  Barangay: $barangay');
    debugPrint('  Municipality: $municipality');
    debugPrint('  Province: $province');
    debugPrint('  Region: $region');

    return address;
  }
}
