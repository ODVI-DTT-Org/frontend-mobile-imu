import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../features/clients/data/models/client_model.dart';
import '../../services/api/client_api_service.dart';

/// Show touchpoint details in a modal bottom sheet
void showTouchpointDetails(BuildContext context, Touchpoint touchpoint) {
  final isVisit = touchpoint.type == TouchpointType.visit;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  isVisit ? LucideIcons.mapPin : LucideIcons.phone,
                  color: isVisit ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Touchpoint #${touchpoint.touchpointNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${isVisit ? 'Visit' : 'Call'} • ${DateFormat('MMM d, yyyy').format(touchpoint.date)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  _buildDetailRow(
                    'Status',
                    touchpoint.status.apiValue,
                    LucideIcons.badgeCheck,
                    _getStatusColor(touchpoint.status),
                  ),
                  const SizedBox(height: 16),

                  // Reason
                  if (touchpoint.reason != null)
                    _buildDetailRow(
                      'Reason',
                      touchpoint.reason!.apiValue,
                      LucideIcons.messageCircle,
                      Colors.grey[700]!,
                    ),
                  if (touchpoint.reason != null) const SizedBox(height: 16),

                  // Location (simplified - address only)
                  _buildLocationSection(touchpoint),
                  const SizedBox(height: 16),

                  // Remarks
                  if (touchpoint.remarks != null &&
                      touchpoint.remarks!.isNotEmpty)
                    _buildDetailRow(
                      'Remarks',
                      touchpoint.remarks!,
                      LucideIcons.alignLeft,
                      Colors.grey[700]!,
                    ),
                  if (touchpoint.remarks != null &&
                      touchpoint.remarks!.isNotEmpty)
                    const SizedBox(height: 16),

                  // Photo section (at bottom)
                  _buildPhotoSection(touchpoint),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildLocationSection(Touchpoint touchpoint) {
  // Priority: timeInGpsAddress > address field
  final address = touchpoint.timeInGpsAddress ?? touchpoint.address;

  if (address == null || address.isEmpty) {
    return const SizedBox.shrink();
  }

  return _buildDetailRow(
    'Location',
    address,
    LucideIcons.mapPin,
    Colors.grey[700]!,
  );
}

Widget _buildPhotoSection(Touchpoint touchpoint) {
  final hasPhoto =
      touchpoint.photoPath != null && touchpoint.photoPath!.isNotEmpty;

  if (!hasPhoto) {
    // Show placeholder
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.camera, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No photo',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Show photo
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(
      File(touchpoint.photoPath!),
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.image, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Unable to load photo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Color _getStatusColor(TouchpointStatus status) {
  switch (status) {
    case TouchpointStatus.interested:
      return Colors.green;
    case TouchpointStatus.undecided:
      return Colors.orange;
    case TouchpointStatus.notInterested:
      return Colors.red;
    case TouchpointStatus.completed:
      return Colors.blue;
    case TouchpointStatus.followUpNeeded:
      return Colors.purple;
    case TouchpointStatus.incomplete:
      return Colors.grey;
  }
}

Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Bottom sheet showing touchpoint history for a client
class TouchpointHistoryDialog extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;

  const TouchpointHistoryDialog({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  static Future<void> show(
    BuildContext context, {
    required String clientId,
    required String clientName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TouchpointHistoryBottomSheet(
        clientId: clientId,
        clientName: clientName,
      ),
    );
  }

  @override
  ConsumerState<TouchpointHistoryDialog> createState() =>
      _TouchpointHistoryDialogState();
}

class _TouchpointHistoryDialogState
    extends ConsumerState<TouchpointHistoryDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.history, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Touchpoint History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.clientName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: FutureBuilder(
                future: _loadClientTouchpoints(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.alertCircle,
                              size: 48, color: Colors.red[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load history',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    );
                  }

                  final touchpoints = snapshot.data ?? [];

                  if (touchpoints.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.calendarX,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No touchpoints yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Record your first visit to start tracking',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: touchpoints.length,
                    itemBuilder: (context, index) {
                      return _TouchpointHistoryItem(
                          touchpoint: touchpoints[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Touchpoint>> _loadClientTouchpoints() async {
    try {
      final clientApi = ref.read(clientApiServiceProvider);
      final client = await clientApi.fetchClient(widget.clientId);
      // Use touchpointSummary directly (contains full touchpoint data with call/visit details)
      return client?.touchpointSummary ?? [];
    } catch (e) {
      debugPrint('Error loading touchpoints: $e');
      return [];
    }
  }
}

/// Bottom sheet for showing touchpoint history
class TouchpointHistoryBottomSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;

  const TouchpointHistoryBottomSheet({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  ConsumerState<TouchpointHistoryBottomSheet> createState() =>
      _TouchpointHistoryBottomSheetState();
}

class _TouchpointHistoryBottomSheetState
    extends ConsumerState<TouchpointHistoryBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.history, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Touchpoint History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.clientName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: FutureBuilder(
              future: _loadClientTouchpoints(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.alertCircle,
                            size: 48, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load history',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  );
                }

                final touchpoints = snapshot.data ?? [];

                if (touchpoints.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.calendarX,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No touchpoints yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Record your first visit to start tracking',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: touchpoints.length,
                  itemBuilder: (context, index) {
                    return _TouchpointHistoryItem(
                        touchpoint: touchpoints[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Touchpoint>> _loadClientTouchpoints() async {
    try {
      final clientApi = ref.read(clientApiServiceProvider);
      final client = await clientApi.fetchClient(widget.clientId);
      // Use touchpointSummary directly (contains full touchpoint data with call/visit details)
      return client?.touchpointSummary ?? [];
    } catch (e) {
      debugPrint('Error loading touchpoints: $e');
      return [];
    }
  }
}

class _TouchpointHistoryItem extends StatelessWidget {
  final Touchpoint touchpoint;

  const _TouchpointHistoryItem({required this.touchpoint});

  @override
  Widget build(BuildContext context) {
    final isVisit = touchpoint.type == TouchpointType.visit;
    final statusColor = _getStatusColor(touchpoint.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVisit ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVisit ? Colors.blue[200]! : Colors.green[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isVisit ? Colors.blue[100] : Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVisit ? LucideIcons.mapPin : LucideIcons.phone,
                  color: isVisit ? Colors.blue : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Touchpoint number and type
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                isVisit ? Colors.blue[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${touchpoint.touchpointNumber}${isVisit ? 'st' : 'nd'}${_getOrdinalSuffix(touchpoint.touchpointNumber)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isVisit
                                  ? Colors.blue[700]
                                  : Colors.green[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isVisit ? 'Visit' : 'Call',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            touchpoint.status.apiValue,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('MMM d, yyyy').format(touchpoint.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Reason
                    if (touchpoint.reason != null)
                      Text(
                        touchpoint.reason!.apiValue,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // View Details button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showTouchpointDetails(context, touchpoint),
              icon: const Icon(LucideIcons.eye, size: 14),
              label: const Text('View Details'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                foregroundColor: isVisit ? Colors.blue[700] : Colors.green[700],
                side: BorderSide(
                  color: isVisit ? Colors.blue[200]! : Colors.green[200]!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TouchpointStatus status) {
    switch (status) {
      case TouchpointStatus.interested:
        return Colors.green;
      case TouchpointStatus.undecided:
        return Colors.orange;
      case TouchpointStatus.notInterested:
        return Colors.red;
      case TouchpointStatus.completed:
        return Colors.blue;
      case TouchpointStatus.followUpNeeded:
        return Colors.purple;
      case TouchpointStatus.incomplete:
        return Colors.grey;
    }
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
