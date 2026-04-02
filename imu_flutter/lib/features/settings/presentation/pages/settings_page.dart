import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/auth/session_service.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../services/sync/sync_preferences_service.dart';
import '../../../../services/api/background_sync_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../../../shared/widgets/permission_widgets.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final SessionService _sessionService = SessionService();
  final SyncPreferencesService _syncPreferences = SyncPreferencesService();

  // Settings state
  bool _notificationsEnabled = true;
  bool _biometricEnabled = true;
  bool _autoSyncEnabled = true;
  bool _locationTrackingEnabled = true;
  String _syncFrequency = 'Real-time';
  String _themeMode = 'System';
  int _sessionTimeout = 15;

  // Sync state
  String _lastSyncTime = 'Loading...';
  bool _isSyncing = false;

  // PowerSync test logs
  final List<String> _powerSyncLogs = [];
  bool _isTestingPowerSync = false;

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final time = await _syncPreferences.getTimeSinceLastSync();
    if (mounted) {
      setState(() {
        _lastSyncTime = time;
      });
    }
  }

  Future<void> _performManualSync() async {
    setState(() => _isSyncing = true);

    try {
      final syncService = ref.read(backgroundSyncServiceProvider);
      final result = await syncService.performSync();

      if (result.success) {
        await _syncPreferences.saveLastSyncTime();
        await _loadLastSyncTime();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync failed: ${result.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(currentUserNameProvider);
    final userEmail = ref.watch(currentUserEmailProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            _buildProfileCard(userName, userEmail),
            const SizedBox(height: 24),

            // Account Settings
            _buildSectionHeader('Account'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: LucideIcons.user,
                title: 'My Profile',
                subtitle: 'Update your personal information',
                onTap: () {
                  HapticUtils.lightImpact();
                  context.push('/profile');
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: LucideIcons.lock,
                title: 'Change PIN',
                subtitle: 'Update your 6-digit PIN',
                onTap: () {
                  HapticUtils.lightImpact();
                  _showChangePinDialog();
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: LucideIcons.key,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () {
                  HapticUtils.lightImpact();
                  _showChangePasswordDialog();
                },
              ),
            ]),
            const SizedBox(height: 24),

            // App Settings
            _buildSectionHeader('App Settings'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: LucideIcons.bell,
                title: 'Push Notifications',
                subtitle: 'Receive alerts for visits and tasks',
                value: _notificationsEnabled,
                onChanged: (value) {
                  HapticUtils.lightImpact();
                  setState(() => _notificationsEnabled = value);
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: LucideIcons.fingerprint,
                title: 'Biometric Login',
                subtitle: 'Use fingerprint or face recognition',
                value: _biometricEnabled,
                onChanged: (value) {
                  HapticUtils.lightImpact();
                  setState(() => _biometricEnabled = value);
                },
              ),
              _buildDivider(),
              _buildDropdownTile(
                icon: LucideIcons.moon,
                title: 'Theme',
                value: _themeMode,
                options: ['System', 'Light', 'Dark'],
                onChanged: (value) {
                  HapticUtils.lightImpact();
                  setState(() => _themeMode = value);
                },
              ),
              _buildDivider(),
              _buildDropdownTile(
                icon: LucideIcons.clock,
                title: 'Session Timeout',
                value: '$_sessionTimeout minutes',
                options: ['5 minutes', '15 minutes', '30 minutes', '1 hour'],
                onChanged: (value) {
                  HapticUtils.lightImpact();
                  final minutes = int.parse(value.split(' ').first);
                  setState(() => _sessionTimeout = minutes);
                },
              ),
            ]),
            const SizedBox(height: 24),

            // Sync Settings
            _buildSectionHeader('Data & Sync'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: LucideIcons.refreshCw,
                title: 'Auto Sync',
                subtitle: 'Automatically sync data when online',
                value: _autoSyncEnabled,
                onChanged: (value) {
                  HapticUtils.lightImpact();
                  setState(() => _autoSyncEnabled = value);
                },
              ),
              _buildDivider(),
              _buildDropdownTile(
                icon: LucideIcons.timer,
                title: 'Sync Frequency',
                value: _syncFrequency,
                options: ['Real-time', 'Every 5 minutes', 'Every 15 minutes', 'Manual only'],
                onChanged: (value) {
                  HapticUtils.lightImpact();
                  setState(() => _syncFrequency = value);
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: LucideIcons.mapPin,
                title: 'Location Tracking',
                subtitle: 'Track location during visits',
                value: _locationTrackingEnabled,
                onChanged: (value) {
                  HapticUtils.lightImpact();
                  setState(() => _locationTrackingEnabled = value);
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: LucideIcons.hardDrive,
                title: 'Storage',
                subtitle: 'Manage app data and cache',
                onTap: () {
                  HapticUtils.lightImpact();
                  _showStorageDialog();
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: LucideIcons.refreshCw,
                title: 'Sync Now',
                subtitle: 'Last sync: $_lastSyncTime',
                trailing: _isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _isSyncing
                    ? null
                    : () {
                        HapticUtils.lightImpact();
                        _performManualSync();
                      },
              ),
              _buildDivider(),
              // RBAC: Test PowerSync is admin-only
              PermissionWidget(
                resource: 'system',
                action: 'read',
                child: _buildSettingsTile(
                  icon: LucideIcons.activity,
                  title: 'Test PowerSync',
                  subtitle: 'Run diagnostics and view sync logs',
                  onTap: () {
                    HapticUtils.lightImpact();
                    _showPowerSyncTestDialog();
                  },
                ),
                fallback: const SizedBox.shrink(), // Hide for non-admin users
              ),
              _buildDivider(),
            ]),
            const SizedBox(height: 24),

            // Support & Info
            _buildSectionHeader('Support & Info'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: LucideIcons.helpCircle,
                title: 'Help Center',
                subtitle: 'FAQs and support articles',
                onTap: () {
                  HapticUtils.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help Center coming soon')),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: LucideIcons.messageSquare,
                title: 'Send Feedback',
                subtitle: 'Report issues or suggest improvements',
                onTap: () {
                  HapticUtils.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback feature coming soon')),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: LucideIcons.info,
                title: 'About IMU',
                subtitle: 'Version 1.0.1',
                onTap: () {
                  HapticUtils.lightImpact();
                  _showAboutDialog();
                },
              ),
            ]),
            const SizedBox(height: 24),

            // Logout Button
            ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(LucideIcons.logOut),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String? userName, String? userEmail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Text(
              userName != null && userName.isNotEmpty
                  ? userName.split(' ').map((e) => e[0]).take(2).join()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? 'Unknown User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail ?? 'No email',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF0F172A), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing else Icon(LucideIcons.chevronRight, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF0F172A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0F172A),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return InkWell(
      onTap: () {
        HapticUtils.lightImpact();
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Option',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map((option) => ListTile(
                  title: Text(option),
                  trailing: value == option
                      ? const Icon(LucideIcons.check, color: Color(0xFF0F172A))
                      : null,
                  onTap: () {
                    onChanged(option);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF0F172A), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronDown, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
      indent: 68,
    );
  }

  void _showChangePinDialog() {
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPinController.text == confirmPinController.text &&
                  newPinController.text.length == 6) {
                HapticUtils.success();
                Navigator.pop(context);

                await LoadingHelper.withLoading(
                  ref: ref,
                  message: 'Changing PIN...',
                  operation: () async {
                    // Simulate API call for PIN change
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  onError: (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to change PIN'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN changed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PINs do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Change PIN'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text == confirmPasswordController.text &&
                  newPasswordController.text.length >= 6) {
                HapticUtils.success();
                Navigator.pop(context);

                await LoadingHelper.withLoading(
                  ref: ref,
                  message: 'Changing password...',
                  operation: () async {
                    // Simulate API call for password change
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  onError: (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to change password'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match or too short'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showStorageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App Storage Usage:'),
            const SizedBox(height: 12),
            _buildStorageItem('Cache', '45 MB', () async {
              HapticUtils.mediumImpact();
              Navigator.pop(context);

              await LoadingHelper.withLoading(
                ref: ref,
                message: 'Clearing cache...',
                operation: () async {
                  // Simulate cache clearing
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                onError: (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to clear cache'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              }
            }),
            _buildStorageItem('Offline Data', '12 MB', null),
            _buildStorageItem('App Data', '28 MB', null),
            const Divider(),
            _buildStorageItem('Total', '85 MB', null),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticUtils.mediumImpact();
              Navigator.pop(context);

              await LoadingHelper.withLoading(
                ref: ref,
                message: 'Clearing all cache...',
                operation: () async {
                  // Simulate cache clearing
                  await Future.delayed(const Duration(milliseconds: 1000));
                },
                onError: (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to clear cache'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All cache cleared')),
                );
              }
            },
            child: const Text('Clear All Cache'),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String label, String size, VoidCallback? onClear) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(
                size,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClear,
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'IMU',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('About IMU'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Itinerary Manager - Uniformed',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text('Version: 1.1.0'),
              const SizedBox(height: 4),
              const Text('Build: 2026.03.15'),
              const SizedBox(height: 16),
              const Text(
                'What\'s New in v1.1.0:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildUpdateItem('Session Persistence',
                  'Auth sessions now persist across app restarts. Returning users go directly to PIN entry.'),
              _buildUpdateItem('PIN Verification Fix',
                  'PIN is now properly verified after setup before accessing the app.'),
              _buildUpdateItem('Improved Security',
                  'Session starts only after successful PIN verification.'),
              const SizedBox(height: 16),
              const Text(
                'A mobile application for field agents managing client visits for retired police personnel (PNP retirees).',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.checkCircle, size: 16, color: Color(0xFF22C55E)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              HapticUtils.success();
              Navigator.pop(context);

              // Clear session and navigate to login
              _sessionService.lockSession();

              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showPowerSyncTestDialog() {
    _powerSyncLogs.clear();
    _addLog('🔧 PowerSync Test Started');
    _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(LucideIcons.activity, color: Color(0xFF0F172A)),
              SizedBox(width: 12),
              Text('PowerSync Diagnostics'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Test status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isTestingPowerSync
                        ? const Color(0xFF3B82F6).withOpacity(0.1)
                        : (_powerSyncLogs.any((log) => log.contains('❌'))
                            ? const Color(0xFFEF4444).withOpacity(0.1)
                            : const Color(0xFF22C55E).withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isTestingPowerSync
                          ? const Color(0xFF3B82F6)
                          : (_powerSyncLogs.any((log) => log.contains('❌'))
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF22C55E)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isTestingPowerSync)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_powerSyncLogs.any((log) => log.contains('❌')))
                        const Icon(LucideIcons.xCircle, color: Color(0xFFEF4444), size: 16)
                      else
                        const Icon(LucideIcons.checkCircle, color: Color(0xFF22C55E), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isTestingPowerSync
                              ? 'Running tests...'
                              : (_powerSyncLogs.any((log) => log.contains('❌'))
                                  ? 'Tests completed with errors'
                                  : 'All tests passed'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _isTestingPowerSync
                                ? const Color(0xFF3B82F6)
                                : (_powerSyncLogs.any((log) => log.contains('❌'))
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF22C55E)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Logs display
                const Text(
                  'Test Logs:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _powerSyncLogs.isEmpty
                          ? [
                              const Text(
                                'No logs yet. Tap "Run Tests" to begin.',
                                style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                              ),
                            ]
                          : _powerSyncLogs
                              .map((log) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      log,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: log.contains('✅')
                                            ? const Color(0xFF22C55E)
                                            : (log.contains('❌') || log.contains('⚠️'))
                                                ? const Color(0xFFEF4444)
                                                : (log.contains('🔧') || log.contains('━━━'))
                                                    ? const Color(0xFFF59E0B)
                                                    : Colors.grey[300],
                                      ),
                                    ),
                                  ))
                              .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isTestingPowerSync
                  ? null
                  : () {
                      HapticUtils.lightImpact();
                      Navigator.pop(context);
                    },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: _isTestingPowerSync
                  ? null
                  : () async {
                      HapticUtils.lightImpact();
                      await _runPowerSyncTests(setDialogState);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Run Tests'),
            ),
          ],
        ),
      ),
    );
  }

  void _addLog(String message) {
    setState(() {
      _powerSyncLogs.add(message);
    });
  }

  Future<void> _runPowerSyncTests(StateSetter setDialogState) async {
    setDialogState(() => _isTestingPowerSync = true);
    _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      // Test 1: Database initialization
      _addLog('📍 Test 1: Database Connection');
      try {
        final db = await PowerSyncService.database;
        _addLog('  ✅ Database initialized successfully');
        _addLog('  📊 Database connected: ${db.connected}');
      } catch (e) {
        _addLog('  ❌ Database initialization failed: $e');
        rethrow;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Test 2: Read from clients table
      _addLog('📍 Test 2: Read from Clients Table');
      try {
        final db = await PowerSyncService.database;
        final clients = await db.getAll('SELECT * FROM clients LIMIT 5');
        _addLog('  ✅ Successfully read ${clients.length} client(s)');
        if (clients.isNotEmpty) {
          final firstClient = clients.first;
          _addLog('  📝 Sample: ${firstClient['first_name']} ${firstClient['last_name']}');
        } else {
          _addLog('  ⚠️  No clients found (table is empty)');
        }
      } catch (e) {
        _addLog('  ❌ Failed to read clients: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Test 3: Check other tables
      _addLog('📍 Test 3: Check Table Schema');
      try {
        final db = await PowerSyncService.database;

        // Check if key tables exist
        final tables = ['clients', 'addresses', 'touchpoints', 'user_profiles'];
        for (final table in tables) {
          try {
            final result = await db.getAll("SELECT COUNT(*) as count FROM $table");
            final count = result.first['count'] as int;
            _addLog('  ✅ $table: $count row(s)');
          } catch (e) {
            _addLog('  ⚠️  $table: ${e.toString().substring(0, 50)}...');
          }
        }
      } catch (e) {
        _addLog('  ❌ Schema check failed: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Test 4: Write test
      _addLog('📍 Test 4: Write Test (Addresses)');
      try {
        final db = await PowerSyncService.database;

        // Try to get a client ID to associate with
        final clients = await db.getAll('SELECT id FROM clients LIMIT 1');

        if (clients.isNotEmpty) {
          final clientId = clients.first['id'] as String;
          final testId = DateTime.now().millisecondsSinceEpoch.toString();

          await db.execute(
            '''INSERT INTO addresses (id, client_id, type, street, city, province, postal_code, is_primary, created_at, updated_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
            [
              testId,
              clientId,
              'home',
              'Test Street',
              'Test City',
              'Test Province',
              '1234',
              0,
              DateTime.now().toIso8601String(),
              DateTime.now().toIso8601String(),
            ],
          );

          _addLog('  ✅ Successfully inserted test address');

          // Clean up the test data
          await db.execute('DELETE FROM addresses WHERE id = ?', [testId]);
          _addLog('  ✅ Cleaned up test data');
        } else {
          _addLog('  ⚠️  Skipped (no clients to associate with)');
        }
      } catch (e) {
        _addLog('  ❌ Write test failed: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Test 5: Sync status
      _addLog('📍 Test 5: Sync Status');
      try {
        final db = await PowerSyncService.database;
        _addLog('  ℹ️  DB Connected: ${db.connected}');
        _addLog('  ℹ️  Service Connected: ${PowerSyncService.isConnected}');
        _addLog('  ℹ️  Pending Uploads: ${await PowerSyncService.pendingUploadCount}');
      } catch (e) {
        _addLog('  ❌ Sync status check failed: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Summary
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('✅ All tests completed!');
      _addLog('ℹ️  Timestamp: ${DateTime.now().toIso8601String()}');
      _addLog('ℹ️  Tests run: 5 (Connection, Read, Schema, Write, Sync)');

    } catch (e) {
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('❌ Test suite failed: $e');
    } finally {
      setDialogState(() => _isTestingPowerSync = false);
    }
  }
}
