import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Rich client card for Itinerary and My Day list views.
///
/// Shows the client name, status badges, address, latest touchpoint, and an
/// optional scheduled time row for My Day.
class ClientCard extends StatelessWidget {
  final String clientName;
  final String? address;
  final String? priority;
  final bool loanReleased;
  final bool isCompleted;
  final String? lastTouchpointType;
  final int? lastTouchpointNumber;
  final DateTime? lastTouchpointDate;
  final String? scheduledTime;
  final VoidCallback onTap;

  const ClientCard({
    super.key,
    required this.clientName,
    this.address,
    this.priority,
    required this.loanReleased,
    required this.isCompleted,
    this.lastTouchpointType,
    this.lastTouchpointNumber,
    this.lastTouchpointDate,
    this.scheduledTime,
    required this.onTap,
  });

  Color get _borderColor {
    if (loanReleased) return Colors.orange.shade400;
    if (priority?.toLowerCase() == 'high') return Colors.red.shade500;
    if (isCompleted) return Colors.green.shade500;
    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final addressText = address?.trim();
    final scheduledTimeText = scheduledTime?.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LeftBorder(color: _borderColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderRow(
                        clientName: clientName,
                        priority: priority,
                        loanReleased: loanReleased,
                        isCompleted: isCompleted,
                      ),
                      const Divider(height: 14, thickness: 0.5),
                      if (addressText != null && addressText.isNotEmpty) ...[
                        _IconRow(
                          icon: LucideIcons.mapPin,
                          text: addressText,
                        ),
                        const SizedBox(height: 5),
                      ],
                      _TouchpointRow(
                        type: lastTouchpointType,
                        number: lastTouchpointNumber,
                        date: lastTouchpointDate,
                      ),
                      if (scheduledTimeText != null &&
                          scheduledTimeText.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        _IconRow(
                          icon: LucideIcons.clock,
                          text: 'Scheduled: $scheduledTimeText',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftBorder extends StatelessWidget {
  final Color color;

  const _LeftBorder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String clientName;
  final String? priority;
  final bool loanReleased;
  final bool isCompleted;

  const _HeaderRow({
    required this.clientName,
    required this.priority,
    required this.loanReleased,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final badges = [
      if (priority?.toLowerCase() == 'high')
        _Badge(
          label: 'HIGH',
          textColor: Colors.red.shade700,
          bgColor: Colors.red.shade50,
        ),
      if (loanReleased)
        _Badge(
          label: 'LOAN RELEASED',
          textColor: Colors.orange.shade700,
          bgColor: Colors.orange.shade50,
        ),
      if (isCompleted)
        _Badge(
          label: 'DONE',
          textColor: Colors.green.shade700,
          bgColor: Colors.green.shade50,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: Text(
                clientName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.52,
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  runSpacing: 4,
                  children: badges,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _Badge({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TouchpointRow extends StatelessWidget {
  final String? type;
  final int? number;
  final DateTime? date;

  const _TouchpointRow({
    this.type,
    this.number,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final rawTypeText = type?.trim();
    final typeText = rawTypeText == null || rawTypeText.isEmpty
        ? null
        : '${rawTypeText[0].toUpperCase()}'
            '${rawTypeText.substring(1).toLowerCase()}';
    final String label;

    if (typeText != null && typeText.isNotEmpty && number != null) {
      final dateText =
          date != null ? ' · ${DateFormat('MMM d').format(date!)}' : '';
      label = 'Last: $typeText #$number$dateText';
    } else {
      label = 'No touchpoints yet';
    }

    return Row(
      children: [
        Icon(LucideIcons.clipboardList, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
