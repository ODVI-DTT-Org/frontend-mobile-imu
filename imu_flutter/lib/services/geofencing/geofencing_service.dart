import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:imu_flutter/core/utils/logger.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/services/api/my_day_api_service.dart';

const double _kGeofenceRadius = 400.0;
const Duration _kCooldown = Duration(hours: 16);

// Bounding box half-width: ±0.005° ≈ ~550m — wider than 400m radius
const double _kBboxDelta = 0.005;

const String _kNotificationChannelId = 'geofencing_proximity';
const String _kNotificationChannelName = 'Nearby Clients';

const String _kActionNavigate = 'action_navigate';
const String _kActionAddItinerary = 'action_add_itinerary';
const String _kActionDismiss = 'action_dismiss';

/// Proximity notification data passed to action handlers.
class _ProximityPayload {
  final String clientId;
  final double clientLat;
  final double clientLng;
  final String clientFullName;
  final String clientFullAddress;

  _ProximityPayload({
    required this.clientId,
    required this.clientLat,
    required this.clientLng,
    required this.clientFullName,
    required this.clientFullAddress,
  });

  String encode() =>
      '$clientId|$clientLat|$clientLng|${Uri.encodeComponent(clientFullName)}|${Uri.encodeComponent(clientFullAddress)}';

  static _ProximityPayload decode(String raw) {
    final parts = raw.split('|');
    return _ProximityPayload(
      clientId: parts[0],
      clientLat: double.parse(parts[1]),
      clientLng: double.parse(parts[2]),
      clientFullName: Uri.decodeComponent(parts[3]),
      clientFullAddress: Uri.decodeComponent(parts[4]),
    );
  }
}

/// GeofencingService
///
/// Owns its own Geolocator position stream (distanceFilter: 10m).
/// On each update, queries local SQLite for clients within a bounding box,
/// computes precise haversine distance, and fires a local notification
/// for any client within 400m whose 16-hour cooldown has expired.
class GeofencingService {
  final PowerSyncDatabase _db;
  final MyDayApiService _myDayApi;
  StreamSubscription<Position>? _positionSub;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  GeofencingService({
    required PowerSyncDatabase db,
    required MyDayApiService myDayApi,
  })  : _db = db,
        _myDayApi = myDayApi;

  Future<void> init() async {
    if (_initialized) return;

    await _initNotifications();
    await _startPositionStream();
    _initialized = true;
    logDebug('GeofencingService: initialized');
  }

  void dispose() {
    _positionSub?.cancel();
    _positionSub = null;
    logDebug('GeofencingService: disposed');
  }

  // ── Initialization ──────────────────────────────────────────────────────

  Future<void> _initNotifications() async {
    // Android 13+ requires runtime permission for POST_NOTIFICATIONS.
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kNotificationChannelId,
        _kNotificationChannelName,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _startPositionStream() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      logDebug('GeofencingService: location services disabled, not starting');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      logDebug('GeofencingService: location permission denied, not starting');
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_onPositionUpdate, onError: (Object e) {
      logError('GeofencingService: position stream error', e);
    });
  }

  // ── Core logic ──────────────────────────────────────────────────────────

  Future<void> _onPositionUpdate(Position position) async {
    final agentLat = position.latitude;
    final agentLng = position.longitude;

    final latMin = agentLat - _kBboxDelta;
    final latMax = agentLat + _kBboxDelta;
    final lngMin = agentLng - _kBboxDelta;
    final lngMax = agentLng + _kBboxDelta;

    // Bounding-box pre-filter eliminates >99% of clients before the precise check.
    // fullname/full_address are not in the sync config — compose display strings
    // from first_name, last_name, middle_name, barangay, municipality, province
    // which ARE synced (present in both clients_territory and clients_favorited).
    final rows = await _db.getAll(
      '''SELECT id, first_name, last_name, middle_name,
                barangay, municipality, province,
                latitude, longitude
         FROM clients
         WHERE latitude IS NOT NULL
           AND loan_released = 0
           AND deleted_at IS NULL
           AND latitude  BETWEEN ? AND ?
           AND longitude BETWEEN ? AND ?''',
      [latMin, latMax, lngMin, lngMax],
    );

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final row in rows) {
      final clientId = row['id'] as String;
      final clientLat = (row['latitude'] as num).toDouble();
      final clientLng = (row['longitude'] as num).toDouble();

      final distance = Geolocator.distanceBetween(
          agentLat, agentLng, clientLat, clientLng);
      if (distance > _kGeofenceRadius) continue;

      // Check cooldown
      final cooldownKey = 'geofence_cooldown_$clientId';
      final lastFiredMs = prefs.getInt(cooldownKey);
      if (lastFiredMs != null &&
          (now - lastFiredMs) < _kCooldown.inMilliseconds) continue;

      // Write cooldown timestamp BEFORE firing so lingering doesn't re-trigger
      await prefs.setInt(cooldownKey, now);

      // Compose display strings from synced fields
      final firstName = row['first_name'] as String? ?? '';
      final lastName = row['last_name'] as String? ?? '';
      final middleName = row['middle_name'] as String?;
      final nameParts = [
        firstName,
        if (middleName != null && middleName.isNotEmpty) middleName,
        lastName,
      ].where((s) => s.isNotEmpty).toList();
      final clientName =
          nameParts.isNotEmpty ? nameParts.join(' ') : 'Unknown client';

      final addressParts = [
        row['barangay'] as String?,
        row['municipality'] as String?,
        row['province'] as String?,
      ].whereType<String>().where((s) => s.isNotEmpty).toList();
      final clientAddress = addressParts.join(', ');

      await _fireNotification(
        clientId: clientId,
        clientFullName: clientName,
        clientFullAddress: clientAddress,
        clientLat: clientLat,
        clientLng: clientLng,
        distanceMeters: distance.round(),
      );
    }
  }

  Future<void> _fireNotification({
    required String clientId,
    required String clientFullName,
    required String clientFullAddress,
    required double clientLat,
    required double clientLng,
    required int distanceMeters,
  }) async {
    final hasPermission = await Permission.notification.isGranted;
    if (!hasPermission) return;

    final payload = _ProximityPayload(
      clientId: clientId,
      clientLat: clientLat,
      clientLng: clientLng,
      clientFullName: clientFullName,
      clientFullAddress: clientFullAddress,
    ).encode();

    final androidDetails = AndroidNotificationDetails(
      _kNotificationChannelId,
      _kNotificationChannelName,
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        const AndroidNotificationAction(
          _kActionNavigate,
          'Navigate Now',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          _kActionAddItinerary,
          'Add to Itinerary',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          _kActionDismiss,
          'Dismiss',
          cancelNotification: true,
        ),
      ],
    );

    await _notifications.show(
      clientId.hashCode,
      'You are near $clientFullName',
      '$clientFullAddress · ${distanceMeters}m away',
      NotificationDetails(android: androidDetails),
      payload: payload,
    );

    logDebug(
        'GeofencingService: fired notification for $clientFullName (${distanceMeters}m)');
  }

  // ── Action handlers ─────────────────────────────────────────────────────

  void _onNotificationResponse(NotificationResponse response) {
    final rawPayload = response.payload;
    if (rawPayload == null) return;

    final payload = _ProximityPayload.decode(rawPayload);

    switch (response.actionId) {
      case _kActionNavigate:
        _handleNavigate(payload);
      case _kActionAddItinerary:
        _handleAddToItinerary(payload.clientId);
      case _kActionDismiss:
        // Cooldown already set at fire time — nothing else to do.
        break;
      default:
        // Tapped the notification body itself — treat as Navigate.
        _handleNavigate(payload);
    }
  }

  void _handleNavigate(_ProximityPayload payload) {
    final uri = Uri.parse(
        'geo:${payload.clientLat},${payload.clientLng}?q=${payload.clientLat},${payload.clientLng}');
    launchUrl(uri, mode: LaunchMode.externalApplication).catchError((Object e) {
      logError('GeofencingService: failed to launch map URI', e);
    });
    _handleAddToItinerary(payload.clientId);
  }

  void _handleAddToItinerary(String clientId) {
    // Fire and forget — network failure is non-critical here.
    // MyDayApiService.addToMyDay handles loan_released guard on the server.
    _myDayApi.addToMyDay(clientId).catchError((Object e) {
      logError('GeofencingService: failed to add client to itinerary', e);
    });
  }
}

// ── Riverpod provider ───────────────────────────────────────────────────────

final geofencingServiceProvider = FutureProvider<GeofencingService>((ref) async {
  final db = await PowerSyncService.database;
  final myDayApi = ref.read(myDayApiServiceProvider);
  final service = GeofencingService(db: db, myDayApi: myDayApi);
  await service.init();
  ref.onDispose(service.dispose);
  return service;
});
