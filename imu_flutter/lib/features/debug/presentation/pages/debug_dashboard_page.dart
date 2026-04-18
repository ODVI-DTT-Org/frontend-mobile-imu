import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/services/location_service.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../shared/providers/app_providers.dart';

class DebugDashboardPage extends ConsumerStatefulWidget {
  const DebugDashboardPage({super.key});

  @override
  ConsumerState<DebugDashboardPage> createState() => _DebugDashboardPageState();
}

class _DebugDashboardPageState extends ConsumerState<DebugDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Services
  late final LocationService _locationService;

  // State
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _locationService = LocationService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setStatus(String message) {
    setState(() => _statusMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _statusMessage = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Debug Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.mapPin), text: 'GPS Tracker'),
            Tab(icon: Icon(LucideIcons.info), text: 'System Info'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _GpsTrackerTab(locationService: _locationService),
              const _SystemInfoTab(),
            ],
          ),
          if (_statusMessage != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// GPS Tracker Tab
class _GpsTrackerTab extends StatefulWidget {
  final LocationService locationService;

  const _GpsTrackerTab({required this.locationService});

  @override
  State<_GpsTrackerTab> createState() => _GpsTrackerTabState();
}

class _GpsTrackerTabState extends State<_GpsTrackerTab> {
  @override
  void initState() {
    super.initState();
    widget.locationService.addListener(_onLocationUpdate);
  }

  @override
  void dispose() {
    widget.locationService.removeListener(_onLocationUpdate);
    super.dispose();
  }

  void _onLocationUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locationService = widget.locationService;
    final stats = locationService.getDebugStats();
    final currentPos = locationService.currentPosition;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tracking Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GPS Tracking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: locationService.isTracking
                            ? Colors.green[100]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        locationService.isTracking ? 'TRACKING' : 'STOPPED',
                        style: TextStyle(
                          color: locationService.isTracking
                              ? Colors.green[700]
                              : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: locationService.isTracking
                            ? null
                            : () async {
                                HapticUtils.lightImpact();
                                await locationService.startTracking();
                              },
                        icon: const Icon(LucideIcons.play, size: 18),
                        label: const Text('Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: locationService.isTracking
                            ? () async {
                                HapticUtils.lightImpact();
                                await locationService.stopTracking();
                              }
                            : null,
                        icon: const Icon(LucideIcons.square, size: 18),
                        label: const Text('Stop'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    HapticUtils.lightImpact();
                    await locationService.getCurrentPosition();
                  },
                  icon: const Icon(LucideIcons.crosshair, size: 18),
                  label: const Text('Get Current Position'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Current Position Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Position',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (currentPos != null) ...[
                  _buildGpsRow('Latitude', currentPos.latitude.toStringAsFixed(6)),
                  _buildGpsRow('Longitude', currentPos.longitude.toStringAsFixed(6)),
                  _buildGpsRow('Altitude', '${currentPos.altitude.toStringAsFixed(1)} m'),
                  _buildGpsRow('Accuracy', '±${currentPos.accuracy.toStringAsFixed(1)} m'),
                  _buildGpsRow('Speed', '${(currentPos.speed * 3.6).toStringAsFixed(1)} km/h'),
                  _buildGpsRow('Heading', '${currentPos.heading.toStringAsFixed(0)}°'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                              text: '${currentPos.latitude}, ${currentPos.longitude}',
                            ));
                            AppNotification.showSuccess(context, 'Coordinates copied!');
                          },
                          icon: const Icon(LucideIcons.copy, size: 16),
                          label: const Text('Copy Coordinates'),
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No position data yet.\nTap "Start" or "Get Current Position"',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Statistics Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracking Statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGpsRow('Session Count', stats['trackingSessionCount'].toString()),
                _buildGpsRow('Location Updates', stats['locationCount'].toString()),
                _buildGpsRow('Distance Traveled', '${(stats['totalDistanceKm'] as num?)?.toStringAsFixed(2) ?? '0'} km'),
                _buildGpsRow('Duration', '${_formatDuration(stats['trackingDuration'] as int? ?? 0)}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Location History Preview
          if (locationService.locationHistory.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Location History (Last 10)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          locationService.clearHistory();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...locationService.locationHistory.reversed.take(10).map((record) => ListTile(
                        dense: true,
                        leading: const Icon(LucideIcons.mapPin, size: 16),
                        title: Text(
                          '${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        subtitle: Text(
                          '${record.timestamp.hour}:${record.timestamp.minute.toString().padLeft(2, '0')} • ±${record.accuracy.toStringAsFixed(0)}m',
                          style: const TextStyle(fontSize: 10),
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGpsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
  }
}

// System Info Tab
class _SystemInfoTab extends ConsumerStatefulWidget {
  const _SystemInfoTab();

  @override
  ConsumerState<_SystemInfoTab> createState() => _SystemInfoTabState();
}

class _SystemInfoTabState extends ConsumerState<_SystemInfoTab> {
  Map<String, int> _tableCounts = {};
  bool _isLoadingCounts = false;

  @override
  void initState() {
    super.initState();
    _loadTableCounts();
  }

  Future<void> _loadTableCounts() async {
    if (!PowerSyncService.isConnected) {
      return;
    }

    setState(() => _isLoadingCounts = true);

    try {
      final tables = ['clients', 'addresses', 'phone_numbers', 'touchpoints', 'user_locations', 'approvals', 'attendance', 'calls', 'visits'];
      final counts = <String, int>{};

      for (final table in tables) {
        try {
          final result = await PowerSyncService.query('SELECT COUNT(*) as count FROM $table');
          counts[table] = result.first['count'] as int? ?? 0;
        } catch (e) {
          counts[table] = -1; // Error indicator
        }
      }

      setState(() {
        _tableCounts = counts;
        _isLoadingCounts = false;
      });
    } catch (e) {
      setState(() => _isLoadingCounts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = PowerSyncService.isConnected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PowerSync Status Card
          _buildPowerSyncStatusCard(isConnected),
          const SizedBox(height: 16),

          // PowerSync Table Counts
          if (isConnected) ...[
            _buildTableCountsCard(),
            const SizedBox(height: 16),
          ],

          // App Info
          _buildInfoCard(
            title: 'App Information',
            items: [
              {'App Name': 'IMU - Field Agent'},
              {'Version': '1.0.0 (Build 1)'},
              {'Environment': 'Development'},
              {'Platform': 'Flutter'},
            ],
          ),
          const SizedBox(height: 16),

          // Storage Info
          _buildInfoCard(
            title: 'Storage',
            items: [
              {'Database': 'PowerSync SQLite'},
              {'Offline Mode': 'Enabled'},
              {'Settings': 'Hive (encrypted)'},
            ],
          ),
          const SizedBox(height: 16),

          // Sync Status
          _buildInfoCard(
            title: 'Sync Configuration',
            items: [
              {'Sync Endpoint': isConnected ? 'PowerSync Cloud' : 'Not connected'},
              {'Offline Mode': 'Enabled'},
              {'Auto Sync': 'On network restore'},
              {'Conflict Resolution': 'Last-write-wins'},
            ],
          ),
          const SizedBox(height: 16),

          // Session Config
          _buildInfoCard(
            title: 'Session Configuration',
            items: [
              {'Auto Lock': '15 minutes'},
              {'Biometric Auth': 'Available'},
              {'PIN Required': 'Yes'},
            ],
          ),
          const SizedBox(height: 16),

          // Touchpoint Pattern
          _buildInfoCard(
            title: 'Touchpoint Pattern',
            items: [
              {'Pattern': 'V-C-C-V-C-C-V'},
              {'Total Touchpoints': '7'},
              {'Visit Count': '3'},
              {'Call Count': '4'},
            ],
          ),
          const SizedBox(height: 16),

          // Developer Options
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.code, color: Colors.orange[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Developer Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Debug dashboard is enabled. This page is only available in development builds.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerSyncStatusCard(bool isConnected) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isConnected ? LucideIcons.cloud : LucideIcons.cloudOff,
                color: isConnected ? Colors.green[700] : Colors.red[700],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'PowerSync Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isConnected ? Colors.green[700] : Colors.red[700],
                ),
              ),
              const Spacer(),
              if (_isLoadingCounts)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton.icon(
                  onPressed: _loadTableCounts,
                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Connection', isConnected ? 'Connected' : 'Not Connected'),
          _buildInfoRow('Database', 'imu_powersync.db'),
          if (isConnected)
            _buildInfoRow('Sync Status', 'Active'),
        ],
      ),
    );
  }

  Widget _buildTableCountsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PowerSync Table Counts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._tableCounts.entries.map((entry) => _buildInfoRow(
                entry.key,
                entry.value == -1 ? 'Error' : '${entry.value} rows',
                valueColor: entry.value == -1 ? Colors.red : null,
              )),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.grey[900],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Map<String, String>> items}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.keys.first, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    Text(item.values.first, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
