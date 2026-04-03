import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/models/user_role.dart';
import '../../../../services/auth/auth_service.dart' show authNotifierProvider;
import '../../../../shared/providers/app_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFEF4444); // Red
      case UserRole.areaManager:
      case UserRole.assistantAreaManager:
        return const Color(0xFF3B82F6); // Blue
      case UserRole.caravan:
        return const Color(0xFF22C55E); // Green
      case UserRole.tele:
        return const Color(0xFFF59E0B); // Orange
    }
  }

  String _formatRole(UserRole role) {
    switch (role) {
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

  void _handleLogout(BuildContext context, WidgetRef ref) {
    HapticUtils.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(currentUserNameProvider);
    final userEmail = ref.watch(currentUserEmailProvider);
    final userRole = ref.watch(currentUserRoleProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (userName?.isNotEmpty ?? false) ? userName![0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Name
                Text(
                  (userName?.isNotEmpty ?? false) ? userName! : 'User Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Email
                Text(
                  (userEmail?.isNotEmpty ?? false) ? userEmail! : 'user@email.com',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getRoleColor(userRole).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getRoleColor(userRole).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Role: ${_formatRole(userRole)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(userRole),
                    ),
                  ),
                ),
                const Spacer(),
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleLogout(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
