import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/auth/session_service.dart';
import '../../../../shared/providers/app_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final SessionService _sessionService = SessionService();

  // Settings state
  bool _notificationsEnabled = true;
  bool _biometricEnabled = true;
  bool _autoSyncEnabled = true;
  bool _locationTrackingEnabled = true;
  String _syncFrequency = 'Real-time';
  String _themeMode = 'System';
  int _sessionTimeout = 15;

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
                subtitle: 'Version 1.0.0',
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
    required VoidCallback onTap,
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
            Icon(LucideIcons.chevronRight, color: Colors.grey[400], size: 18),
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
            onPressed: () {
              if (newPinController.text == confirmPinController.text &&
                  newPinController.text.length == 6) {
                HapticUtils.success();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN changed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
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
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text &&
                  newPasswordController.text.length >= 8) {
                HapticUtils.success();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
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
            _buildStorageItem('Cache', '45 MB', () {
              HapticUtils.mediumImpact();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
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
            onPressed: () {
              HapticUtils.mediumImpact();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All cache cleared')),
              );
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Itinerary Manager - Uniformed',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Build: 2024.03.12'),
            SizedBox(height: 16),
            Text(
              'A mobile application for field agents managing client visits for retired police personnel (PNP retirees).',
              style: TextStyle(color: Colors.grey),
            ),
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
}
