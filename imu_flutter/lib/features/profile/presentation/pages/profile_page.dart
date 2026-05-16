import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/models/user_role.dart';
import '../../../../services/auth/auth_service.dart' show authNotifierProvider;
import '../../../../services/geofencing/geofencing_service.dart';
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

  void _showGeofencingTestDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        String status = '';
        bool isFiring = false;
        bool isClearing = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Row(
              children: [
                Icon(LucideIcons.mapPin, color: Color(0xFF0F172A)),
                SizedBox(width: 12),
                Text('Geofencing Debug'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Test proximity notifications without being near a real client.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: isFiring
                      ? null
                      : () async {
                          setDialogState(() {
                            isFiring = true;
                            status = '';
                          });
                          try {
                            final service = ref.read(geofencingServiceProvider);
                            await service.init();
                            await service.processNearbyClients(
                              agentLat: 14.5995,
                              agentLng: 120.9842,
                              clientRows: [
                                {
                                  'id': 'debug-test-client',
                                  'first_name': 'Test',
                                  'middle_name': '',
                                  'last_name': 'Client',
                                  'full_address': 'Debug Address, Manila',
                                  'latitude': 14.6015,
                                  'longitude': 120.9842,
                                }
                              ],
                            );
                            setDialogState(() {
                              isFiring = false;
                              status =
                                  '✅ Notification fired — check your notification shade';
                            });
                          } catch (e) {
                            setDialogState(() {
                              isFiring = false;
                              status = '❌ Error: $e';
                            });
                          }
                        },
                  icon: isFiring
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(LucideIcons.bell),
                  label: const Text('Fire Test Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isClearing
                      ? null
                      : () async {
                          setDialogState(() {
                            isClearing = true;
                            status = '';
                          });
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final keys = prefs
                                .getKeys()
                                .where(
                                    (k) => k.startsWith('geofence_cooldown_'))
                                .toList();
                            for (final k in keys) {
                              await prefs.remove(k);
                            }
                            setDialogState(() {
                              isClearing = false;
                              status =
                                  '✅ Cleared ${keys.length} cooldown${keys.length == 1 ? '' : 's'}';
                            });
                          } catch (e) {
                            setDialogState(() {
                              isClearing = false;
                              status = '❌ Clear failed: $e';
                            });
                          }
                        },
                  icon: isClearing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.trash2),
                  label: const Text('Clear All Cooldowns'),
                ),
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: status.startsWith('✅')
                          ? const Color(0xFF22C55E).withOpacity(0.1)
                          : const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: status.startsWith('✅')
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
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

            // Developer Tools
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
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticUtils.lightImpact();
                  _showGeofencingTestDialog(context, ref);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.mapPin,
                            color: Color(0xFF0F172A), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Test Geofencing',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Fire a test proximity notification',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight,
                          color: Colors.grey[400], size: 18),
                    ],
                  ),
                ),
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
}
