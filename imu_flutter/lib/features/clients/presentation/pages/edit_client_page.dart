import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../data/models/client_model.dart';
import '../widgets/edit_client_form.dart';

/// Edit Client Page - Wrapper for EditClientForm component
///
/// This page uses the reusable EditClientForm widget and provides:
/// - AppBar with title and delete action
/// - Navigation handling
/// - Delete client functionality
class EditClientPage extends ConsumerStatefulWidget {
  final String clientId;

  const EditClientPage({super.key, required this.clientId});

  @override
  ConsumerState<EditClientPage> createState() => _EditClientPageState();
}

class _EditClientPageState extends ConsumerState<EditClientPage> {
  final _hiveService = HiveService();
  Client? _client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Client'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            tooltip: 'Delete Client',
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: EditClientForm(
        clientId: widget.clientId,
        initialClient: _client,
        onSave: (savedClient) {
          // Update local reference after save
          setState(() {
            _client = savedClient;
          });
          // Return success to trigger navigation
          return true;
        },
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
          'Are you sure you want to delete ${_client?.firstName ?? ''} ${_client?.lastName ?? ''}?',
        ),
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

    if (confirmed == true && mounted) {
      HapticUtils.delete();

      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Deleting client...',
        operation: () async {
          await _hiveService.deleteClient(widget.clientId);
          // PowerSync handles sync automatically
        },
        onError: (e) {
          HapticUtils.error();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete client: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client deleted')),
        );
        context.pop(true);
      }
    }
  }
}
