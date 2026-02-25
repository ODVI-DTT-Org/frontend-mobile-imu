import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/services/test_data_generator.dart';
import '../../../../core/services/location_service.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../core/utils/haptic_utils.dart';
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
  final _hiveService = HiveService();
  late final TestDataGenerator _testDataGenerator;
  late final LocationService _locationService;

  // State
  Map<String, int> _dataStats = {};
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _testDataGenerator = TestDataGenerator(_hiveService);
    _locationService = LocationService();
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    if (!_hiveService.isInitialized) {
      await _hiveService.init();
    }
    setState(() {
      _dataStats = _testDataGenerator.getDataStats();
    });
  }

  void _setStatus(String message) {
    setState(() => _statusMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _statusMessage = null);
      }
    });
  }

  // Test Data Generation Methods
  Future<void> _generateSmallDataset() async {
    HapticUtils.mediumImpact();
    setState(() => _isLoading = true);
    try {
      final count = await _testDataGenerator.generateSmallDataset();
      await _loadStats();
      ref.invalidate(clientsProvider); // Refresh clients list
      _setStatus('Generated $count test clients');
      HapticUtils.success();
    } catch (e) {
      _setStatus('Error: $e');
      HapticUtils.error();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateLargeDataset() async {
    HapticUtils.mediumImpact();
    setState(() => _isLoading = true);
    try {
      final count = await _testDataGenerator.generateLargeDataset();
      await _loadStats();
      ref.invalidate(clientsProvider); // Refresh clients list
      _setStatus('Generated $count test clients');
      HapticUtils.success();
    } catch (e) {
      _setStatus('Error: $e');
      HapticUtils.error();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateLimitBreakerDataset() async {
    HapticUtils.mediumImpact();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate 1000 Clients?'),
        content: const Text(
            'This will generate 1000 test clients which may take a while and use significant storage. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final count = await _testDataGenerator.generateLimitBreakerDataset();
      await _loadStats();
      ref.invalidate(clientsProvider); // Refresh clients list
      _setStatus('Generated $count test clients');
      HapticUtils.success();
    } catch (e) {
      _setStatus('Error: $e');
      HapticUtils.error();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearTestData() async {
    HapticUtils.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Test Data?'),
        content: const Text('This will delete all clients with test IDs. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final count = await _testDataGenerator.clearTestData();
      await _loadStats();
      ref.invalidate(clientsProvider); // Refresh clients list
      _setStatus('Deleted $count test clients');
      HapticUtils.success();
    } catch (e) {
      _setStatus('Error: $e');
      HapticUtils.error();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllData() async {
    HapticUtils.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear ALL Data?'),
        content: const Text(
            'This will delete ALL client data including real clients. This cannot be undone!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final count = await _testDataGenerator.clearAllData();
      await _loadStats();
      ref.invalidate(clientsProvider); // Refresh clients list
      _setStatus('Deleted $count total clients');
      HapticUtils.success();
    } catch (e) {
      _setStatus('Error: $e');
      HapticUtils.error();
    } finally {
      setState(() => _isLoading = false);
    }
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
            Tab(icon: Icon(LucideIcons.database), text: 'Test Data'),
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
              _TestDataTab(
                dataStats: _dataStats,
                isLoading: _isLoading,
                onGenerateSmall: _generateSmallDataset,
                onGenerateLarge: _generateLargeDataset,
                onGenerateLimitBreaker: _generateLimitBreakerDataset,
                onClearTestData: _clearTestData,
                onClearAllData: _clearAllData,
              ),
              _GpsTrackerTab(locationService: _locationService),
              _SystemInfoTab(hiveService: _hiveService),
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

// Test Data Tab
class _TestDataTab extends StatelessWidget {
  final Map<String, int> dataStats;
  final bool isLoading;
  final VoidCallback onGenerateSmall;
  final VoidCallback onGenerateLarge;
  final VoidCallback onGenerateLimitBreaker;
  final VoidCallback onClearTestData;
  final VoidCallback onClearAllData;

  const _TestDataTab({
    required this.dataStats,
    required this.isLoading,
    required this.onGenerateSmall,
    required this.onGenerateLarge,
    required this.onGenerateLimitBreaker,
    required this.onClearTestData,
    required this.onClearAllData,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data Statistics Card
          _buildSectionCard(
            title: 'Data Statistics',
            child: Column(
              children: [
                _buildStatRow('Total Clients', dataStats['total'] ?? 0),
                _buildStatRow('Test Clients', dataStats['testClients'] ?? 0),
                _buildStatRow('Real Clients', dataStats['realClients'] ?? 0),
                _buildStatRow('Potential', dataStats['potentialClients'] ?? 0),
                _buildStatRow('Existing', dataStats['existingClients'] ?? 0),
                _buildStatRow('Total Touchpoints', dataStats['totalTouchpoints'] ?? 0),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Generate Test Data Card
          _buildSectionCard(
            title: 'Generate Test Data',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Generate realistic test client data for development and testing.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  label: 'Small Dataset (10 clients)',
                  icon: LucideIcons.package,
                  color: Colors.blue,
                  onPressed: isLoading ? null : onGenerateSmall,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  label: 'Large Dataset (100 clients)',
                  icon: LucideIcons.box,
                  color: Colors.orange,
                  onPressed: isLoading ? null : onGenerateLarge,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  label: 'Limit Breaker (1000 clients)',
                  icon: LucideIcons.database,
                  color: Colors.red,
                  onPressed: isLoading ? null : onGenerateLimitBreaker,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Clear Data Card
          _buildSectionCard(
            title: 'Clear Data',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildActionButton(
                  label: 'Clear Test Data Only',
                  icon: LucideIcons.trash2,
                  color: Colors.orange,
                  onPressed: isLoading ? null : onClearTestData,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  label: 'Clear ALL Data',
                  icon: LucideIcons.trash,
                  color: Colors.red,
                  onPressed: isLoading ? null : onClearAllData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
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
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coordinates copied!')),
                            );
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
class _SystemInfoTab extends StatelessWidget {
  final HiveService hiveService;

  const _SystemInfoTab({required this.hiveService});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              {'Database': 'Hive (NoSQL)'},
              {'Initialized': hiveService.isInitialized ? 'Yes' : 'No'},
              {'Encryption': 'Enabled'},
            ],
          ),
          const SizedBox(height: 16),

          // Sync Status
          _buildInfoCard(
            title: 'Sync Configuration',
            items: [
              {'Sync Endpoint': 'Not configured'},
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
