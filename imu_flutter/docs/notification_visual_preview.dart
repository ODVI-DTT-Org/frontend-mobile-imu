import 'package:flutter/material.dart';

/// Visual preview of the unified notification system
/// This file demonstrates how notifications will appear in the app
///
/// To view: Run this file as a standalone Flutter app or use in DevTools
class NotificationVisualPreview extends StatelessWidget {
  const NotificationVisualPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Notification System Preview'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // Status bar area
            Container(
              height: 24,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Icon(Icons.wifi, color: Colors.white, size: 14),
                    ],
                  ),
                  const Text('9:41', style: TextStyle(color: Colors.white, fontSize: 12)),
                  const Icon(Icons.battery_full, color: Colors.white, size: 14),
                ],
              ),
            ),

            // Notification examples
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'TOP-POSITIONED NOTIFICATIONS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Success Notification
                  _buildNotificationPreview(
                    title: 'SUCCESS (Green)',
                    child: _buildMockNotification(
                      icon: Icons.check_circle,
                      iconColor: Colors.white,
                      backgroundColor: const Color(0xFF10B981),
                      message: 'Client created successfully!',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error Notification
                  _buildNotificationPreview(
                    title: 'ERROR (Red)',
                    child: _buildMockNotification(
                      icon: Icons.error,
                      iconColor: Colors.white,
                      backgroundColor: const Color(0xFFEF4444),
                      message: 'Failed to save changes. Please try again.',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Warning Notification
                  _buildNotificationPreview(
                    title: 'WARNING (Orange)',
                    child: _buildMockNotification(
                      icon: Icons.warning,
                      iconColor: Colors.white,
                      backgroundColor: const Color(0xFFF59E0B),
                      message: 'Unsaved changes detected.',
                      actionLabel: 'Save',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Neutral Notification
                  _buildNotificationPreview(
                    title: 'NEUTRAL (Gray)',
                    child: _buildMockNotification(
                      icon: Icons.info,
                      iconColor: Colors.white,
                      backgroundColor: const Color(0xFF6B7280),
                      message: 'Syncing data...',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Success with Action
                  _buildNotificationPreview(
                    title: 'SUCCESS WITH ACTION',
                    child: _buildMockNotification(
                      icon: Icons.check_circle,
                      iconColor: Colors.white,
                      backgroundColor: const Color(0xFF10B981),
                      message: 'Changes saved successfully!',
                      actionLabel: 'View',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error with Retry
                  _buildNotificationPreview(
                    title: 'ERROR WITH RETRY',
                    child: _buildMockNotification(
                      icon: Icons.error,
                      iconColor: Colors.white,
                      backgroundColor: const Color(0xFFEF4444),
                      message: 'Connection failed.',
                      actionLabel: 'Retry',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Neutral with Undo
                  _buildNotificationPreview(
                    title: 'NEUTRAL WITH UNDO',
                    child: _buildMockNotification(
                      icon: Icons.info,
                      iconColor: Colors.white,
                      backgroundColor: const Color(0xFF6B7280),
                      message: 'Item deleted.',
                      actionLabel: 'Undo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPreview({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        // Phone frame mockup
        Container(
          width: 320,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Status bar mock
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 24,
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Icon(Icons.wifi, color: Colors.white, size: 12),
                        ],
                      ),
                      const Text('9:41', style: TextStyle(color: Colors.white, fontSize: 10)),
                      const Icon(Icons.battery_full, color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ),
              // Notification positioned at top
              Positioned(
                top: 32, // Below status bar + padding
                left: 12,
                right: 12,
                child: child,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMockNotification({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String message,
    String? actionLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionLabel != null) ...[
            TextButton(
              onPressed: null,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            Icons.close,
            color: iconColor,
            size: 18,
          ),
        ],
      ),
    );
  }
}
