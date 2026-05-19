import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/models/user_role.dart';
import '../../../../services/auth/auth_service.dart' show authNotifierProvider;
import '../../../../services/auth/jwt_auth_service.dart';
import '../../../../shared/providers/app_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFEF4444);
      case UserRole.areaManager:
      case UserRole.assistantAreaManager:
        return const Color(0xFF3B82F6);
      case UserRole.teamLeader:
        return const Color(0xFF8B5CF6);
      case UserRole.caravan:
        return const Color(0xFF22C55E);
      case UserRole.tele:
        return const Color(0xFFF59E0B);
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
      case UserRole.teamLeader:
        return 'Team Leader';
      case UserRole.caravan:
        return 'Caravan';
      case UserRole.tele:
        return 'Tele';
    }
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    HapticUtils.lightImpact();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool showCurrent = false;
        bool showNew = false;
        bool showConfirm = false;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (_, setState) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: !showCurrent,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showCurrent ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                      onPressed: () => setState(() => showCurrent = !showCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: !showNew,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'New Password (min. 8 characters)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showNew ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                      onPressed: () => setState(() => showNew = !showNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !showConfirm,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showConfirm ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                      onPressed: () => setState(() => showConfirm = !showConfirm),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final currentPassword = currentPasswordController.text.trim();
                        final newPassword = newPasswordController.text;
                        final confirmPassword = confirmPasswordController.text;

                        if (currentPassword.isEmpty) {
                          AppNotification.showError(context, 'Please enter your current password');
                          return;
                        }
                        if (newPassword.length < 8) {
                          AppNotification.showError(context, 'New password must be at least 8 characters');
                          return;
                        }
                        if (newPassword != confirmPassword) {
                          AppNotification.showError(context, 'New passwords do not match');
                          return;
                        }

                        setState(() => isSubmitting = true);
                        bool success = false;
                        try {
                          final token = ref.read(jwtAuthProvider).accessToken;
                          if (token == null) throw Exception('Not authenticated');

                          final dio = Dio(BaseOptions(
                            baseUrl: AppConfig.apiBaseUrl,
                            connectTimeout: const Duration(seconds: 15),
                            receiveTimeout: const Duration(seconds: 15),
                          ));
                          await dio.post(
                            '/auth/change-password',
                            data: {
                              'currentPassword': currentPassword,
                              'newPassword': newPassword,
                            },
                            options: Options(
                              headers: {'Authorization': 'Bearer $token'},
                            ),
                          );
                          success = true;
                        } on DioException catch (e) {
                          if (context.mounted) {
                            final message = e.response?.data?['message'] as String?
                                ?? 'Failed to change password';
                            AppNotification.showError(context, message);
                          }
                        } catch (_) {
                          if (context.mounted) {
                            AppNotification.showError(context, 'Failed to change password');
                          }
                        } finally {
                          if (dialogContext.mounted) {
                            setState(() => isSubmitting = false);
                          }
                        }

                        if (success) {
                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                          if (context.mounted) {
                            HapticUtils.success();
                            AppNotification.showSuccess(context, 'Password changed successfully');
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Change Password'),
              ),
            ],
          ),
        );
      },
    );
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your account settings',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
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
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    (userName?.isNotEmpty ?? false) ? userName! : 'User Name',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    (userEmail?.isNotEmpty ?? false) ? userEmail! : 'user@email.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getRoleColor(userRole),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Actions
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    icon: LucideIcons.keyRound,
                    label: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () => _showChangePasswordDialog(context, ref),
                    isFirst: true,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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

            const SizedBox(height: 100), // Bottom nav padding
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF0F172A), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }
}
