import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/haptic_utils.dart';

/// Action option for bottom sheet
class ActionOption {
  final IconData icon;
  final String title;
  final String? description;
  final String value;
  final bool isDestructive;
  final Color? iconColor;

  const ActionOption({
    required this.icon,
    required this.title,
    this.description,
    required this.value,
    this.isDestructive = false,
    this.iconColor,
  });
}

/// Reusable bottom sheet for action menus
///
/// Usage:
/// ```dart
/// final action = await ActionBottomSheet.show(
///   context,
///   title: 'Juan Dela Cruz',
///   subtitle: 'Barangay Masilo, Guiguinto',
///   options: [
///     ActionOption(
///       icon: LucideIcons.edit,
///       title: 'Edit Client',
///       description: 'View and update client information',
///       value: 'edit',
///     ),
///     ActionOption(
///       icon: LucideIcons.dollarSign,
///       title: 'Release Loan',
///       description: 'Mark loan as released',
///       value: 'release',
///     ),
///     ActionOption(
///       icon: LucideIcons.mapPin,
///       title: 'Record Visit',
///       description: 'Create a new touchpoint',
///       value: 'visit',
///     ),
///     ActionOption(
///       icon: LucideIcons.x,
///       title: 'Cancel',
///       value: 'cancel',
///       isDestructive: true,
///     ),
///   ],
/// );
/// ```
class ActionBottomSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<ActionOption> options;

  const ActionBottomSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.options,
  });

  /// Show bottom sheet and return selected value
  static Future<String?> show(
    BuildContext context, {
    String? title,
    String? subtitle,
    required List<ActionOption> options,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    HapticUtils.lightImpact();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (context) => ActionBottomSheet(
        title: title,
        subtitle: subtitle,
        options: options,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          _buildDragHandle(),
          // Title section
          if (title != null) _buildTitle(context, title!, subtitle),
          // Options
          ...options.map((option) => _buildOption(context, option)),
          // Bottom padding for keyboard/home indicator
          SizedBox(height: bottomPadding > 0 ? 0 : bottomSafeArea),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTitle(BuildContext context, String title, String? subtitle) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(height: 1),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildOption(BuildContext context, ActionOption option) {
    final iconColor = option.iconColor ??
        (option.isDestructive ? Colors.red.shade600 : const Color(0xFF0F172A));

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          leading: Icon(option.icon, color: iconColor, size: 22),
          title: Text(
            option.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: option.isDestructive ? Colors.red.shade700 : null,
            ),
          ),
          subtitle: option.description != null
              ? Text(
                  option.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                )
              : null,
          onTap: () {
            HapticUtils.lightImpact();
            Navigator.of(context).pop(option.value);
          },
        ),
        if (option != options.last)
          Padding(
            padding: const EdgeInsets.only(left: 64, right: 24),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
      ],
    );
  }
}

/// Predefined action options for common actions
class CommonActions {
  static ActionOption edit({String value = 'edit'}) => ActionOption(
        icon: LucideIcons.edit,
        title: 'Edit',
        description: 'View and update information',
        value: value,
      );

  static ActionOption delete({String value = 'delete'}) => ActionOption(
        icon: LucideIcons.trash2,
        title: 'Delete',
        description: 'Remove permanently',
        value: value,
        isDestructive: true,
      );

  static ActionOption cancel({String value = 'cancel'}) => ActionOption(
        icon: LucideIcons.x,
        title: 'Cancel',
        value: value,
        isDestructive: true,
      );

  static ActionOption call({String? phoneNumber, String value = 'call'}) =>
      ActionOption(
        icon: LucideIcons.phone,
        title: 'Call',
        description: phoneNumber ?? 'Make a phone call',
        value: value,
        iconColor: Colors.green.shade600,
      );

  static ActionOption navigate({String value = 'navigate'}) => ActionOption(
        icon: LucideIcons.navigation,
        title: 'Navigate',
        description: 'Open in maps app',
        value: value,
        iconColor: Colors.blue.shade600,
      );

  static ActionOption recordVisit({String value = 'visit'}) => ActionOption(
        icon: LucideIcons.mapPin,
        title: 'Record Visit',
        description: 'Create a new touchpoint',
        value: value,
      );

  static ActionOption share({String value = 'share'}) => ActionOption(
        icon: LucideIcons.share2,
        title: 'Share',
        description: 'Share with others',
        value: value,
      );
}
