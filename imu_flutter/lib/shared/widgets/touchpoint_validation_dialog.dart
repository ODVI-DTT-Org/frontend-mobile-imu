import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_role.dart';
import '../../features/clients/data/models/client_model.dart';
import '../providers/app_providers.dart' show currentUserRoleProvider;

/// Dialog widget that shows an error when user tries to create an invalid touchpoint
/// Now gets user role from Riverpod providers instead of requiring it as parameter
class TouchpointValidationDialog extends ConsumerWidget {
  const TouchpointValidationDialog({
    super.key,
    required this.attemptedNumber,
    required this.attemptedType,
    required this.onConfirm,
  });

  final int attemptedNumber;
  final TouchpointType attemptedType;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(currentUserRoleProvider);

    String getRoleDisplayName() {
      switch (userRole) {
        case UserRole.admin:
          return 'Admin';
        case UserRole.areaManager:
          return 'Area Manager';
        case UserRole.assistantAreaManager:
          return 'Assistant Area Manager';
        case UserRole.caravan:
          return 'Caravan';
        case UserRole.tele:
          return 'Tele';
      }
    }

    String getAllowedTypes() {
      switch (userRole) {
        case UserRole.caravan:
          return 'Visit (numbers 1, 4, 7)';
        case UserRole.tele:
          return 'Call (numbers 2, 3, 5, 6)';
        case UserRole.admin:
        case UserRole.areaManager:
        case UserRole.assistantAreaManager:
          return 'any type';
      }
    }

    return AlertDialog(
      title: const Text('Invalid Touchpoint'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$getRoleDisplayName() can only create $getAllowedTypes() touchpoints.',
          ),
          const SizedBox(height: 8),
          Text(
            'Touchpoint $attemptedNumber requires ${attemptedType.name} type.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (userRole.isManager) ...[
            const SizedBox(height: 8),
            Text(
              'As a manager, you can create any touchpoint type. Please select a different touchpoint number or contact your administrator if you need this restriction changed.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onConfirm,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
