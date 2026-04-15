import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/map_config.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../../../shared/widgets/map_widgets/client_map_view.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../data/models/client_model.dart';

/// Full-screen map page for viewing all clients
class ClientsMapPage extends ConsumerStatefulWidget {
  const ClientsMapPage({super.key});

  @override
  ConsumerState<ClientsMapPage> createState() => _ClientsMapPageState();
}

class _ClientsMapPageState extends ConsumerState<ClientsMapPage> {
  final HiveService _hiveService = HiveService();
  List<Client> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Loading client locations...',
      operation: () async {
        if (!_hiveService.isInitialized) {
          await _hiveService.init();
        }

        final clientsData = _hiveService.getAllClients();
        final clients = clientsData.map((data) => Client.fromJson(data)).toList();

        // Filter clients with valid coordinates
        final clientsWithLocations = clients.where((client) {
          return client.addresses.any((addr) =>
              addr.latitude != null &&
              addr.longitude != null &&
              addr.latitude != 0.0 &&
              addr.longitude != 0.0);
        }).toList();

        setState(() {
          _clients = clientsWithLocations;
          _isLoading = false;
        });
      },
      onError: (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppNotification.showError(context, 'Failed to load clients: $e');
        }
      },
    );
  }

  void _handleClientTap(String clientId) {
    HapticUtils.lightImpact();
    context.push('/clients/$clientId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClients,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? _buildEmptyState()
              : ClientMapView(
                  clients: _clients,
                  onClientTap: _handleClientTap,
                  showControls: true,
                  showSearch: true,
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Client Locations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Clients without location coordinates will not appear on the map.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
