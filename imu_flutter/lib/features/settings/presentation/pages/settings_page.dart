import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometricEnabled = false;
  bool _pushNotifications = true;
  bool _taskReminders = true;
  bool _syncAlerts = true;
  String _themeMode = 'Light';
  String _textSize = 'Medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Account Section
            _buildSection(
              title: 'Account',
              children: [
                _buildNavigationTile(
                  icon: LucideIcons.key,
                  title: 'Change PIN',
                  onTap: () => _showChangePinDialog(),
                ),
                _buildNavigationTile(
                  icon: LucideIcons.lock,
                  title: 'Change Password',
                  onTap: () => _showChangePasswordDialog(),
                ),
                _buildSwitchTile(
                  icon: LucideIcons.fingerprint,
                  title: 'Biometric Login',
                  subtitle: 'Use fingerprint or face to unlock',
                  value: _biometricEnabled,
                  onChanged: (value) => setState(() => _biometricEnabled = value),
                ),
                _buildNavigationTile(
                  icon: LucideIcons.smartphone,
                  title: 'Logged-in Devices',
                  trailing: const Text('1 device'),
                  onTap: () {},
                ),
              ],
            ),

            // Appearance Section
            _buildSection(
              title: 'Appearance',
              children: [
                _buildDropdownTile(
                  icon: LucideIcons.sun,
                  title: 'Theme',
                  value: _themeMode,
                  options: ['Light', 'Dark', 'System'],
                  onChanged: (value) => setState(() => _themeMode = value!),
                ),
                _buildDropdownTile(
                  icon: LucideIcons.type,
                  title: 'Text Size',
                  value: _textSize,
                  options: ['Small', 'Medium', 'Large'],
                  onChanged: (value) => setState(() => _textSize = value!),
                ),
              ],
            ),

            // Notifications Section
            _buildSection(
              title: 'Notifications',
              children: [
                _buildSwitchTile(
                  icon: LucideIcons.bell,
                  title: 'Push Notifications',
                  subtitle: 'Master toggle for all notifications',
                  value: _pushNotifications,
                  onChanged: (value) => setState(() => _pushNotifications = value),
                ),
                _buildSwitchTile(
                  icon: LucideIcons.clock,
                  title: 'Task Reminders',
                  value: _taskReminders,
                  onChanged: (value) => setState(() => _taskReminders = value),
                ),
                _buildSwitchTile(
                  icon: LucideIcons.refreshCw,
                  title: 'Sync Status Alerts',
                  value: _syncAlerts,
                  onChanged: (value) => setState(() => _syncAlerts = value),
                ),
              ],
            ),

            // Data & Storage Section
            _buildSection(
              title: 'Data & Storage',
              children: [
                _buildNavigationTile(
                  icon: LucideIcons.refreshCw,
                  title: 'Sync Now',
                  trailing: const Text('Last: 5 min ago'),
                  onTap: () => _syncNow(),
                ),
                _buildNavigationTile(
                  icon: LucideIcons.trash2,
                  title: 'Clear Cache',
                  trailing: const Text('12.5 MB'),
                  onTap: () => _clearCache(),
                ),
                _buildInfoTile(
                  icon: LucideIcons.hardDrive,
                  title: 'Storage Used',
                  value: '45.2 MB',
                ),
              ],
            ),

            // Privacy & Security Section
            _buildSection(
              title: 'Privacy & Security',
              children: [
                _buildInfoTile(
                  icon: LucideIcons.timer,
                  title: 'Auto-lock',
                  value: '15 minutes',
                ),
                _buildSwitchTile(
                  icon: LucideIcons.lock,
                  title: 'Require PIN on Resume',
                  value: true,
                  onChanged: null, // Fixed setting
                ),
                _buildSwitchTile(
                  icon: LucideIcons.eyeOff,
                  title: 'Hide Sensitive Info',
                  subtitle: 'Blur app when in background',
                  value: true,
                  onChanged: null, // Fixed setting
                ),
              ],
            ),

            // About Section
            _buildSection(
              title: 'About',
              children: [
                _buildInfoTile(
                  icon: LucideIcons.info,
                  title: 'App Version',
                  value: '1.0.0',
                ),
                _buildNavigationTile(
                  icon: LucideIcons.fileText,
                  title: 'Terms of Service',
                  onTap: () {},
                ),
                _buildNavigationTile(
                  icon: LucideIcons.shield,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
              ],
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(),
                  icon: const Icon(LucideIcons.logOut, color: Colors.red),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: trailing ?? const Icon(LucideIcons.chevronRight, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options
            .map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  void _showChangePinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: const Text('This will navigate to PIN change flow.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to PIN change flow
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('This will initiate password reset via admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset request sent')),
              );
            },
            child: const Text('Request Reset'),
          ),
        ],
      ),
    );
  }

  void _syncNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing data...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear temporary files. Your data will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
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
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
