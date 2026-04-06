import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/utils/haptic_utils.dart';
import '../models/bulk_delete_models.dart';
import '../../app.dart' show showToast;

/// Bulk Delete Bottom Sheet
/// Shows progress during bulk delete operations with undo option
class BulkDeleteBottomSheet extends StatefulWidget {
  final List<String> itemIds;
  final String itemType;
  final Future<BulkDeleteResult> Function(List<String>) onDelete;
  final VoidCallback? onComplete;

  const BulkDeleteBottomSheet({
    super.key,
    required this.itemIds,
    required this.itemType,
    required this.onDelete,
    this.onComplete,
  });

  @override
  State<BulkDeleteBottomSheet> createState() => _BulkDeleteBottomSheetState();

  static Future<void> show({
    required BuildContext context,
    required List<String> itemIds,
    required String itemType,
    required Future<BulkDeleteResult> Function(List<String>) onDelete,
    VoidCallback? onComplete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      builder: (context) => BulkDeleteBottomSheet(
        itemIds: itemIds,
        itemType: itemType,
        onDelete: onDelete,
        onComplete: onComplete,
      ),
    );
  }
}

class _BulkDeleteBottomSheetState extends State<BulkDeleteBottomSheet> {
  BulkDeleteStatus _status = BulkDeleteStatus.deleting;
  Timer? _undoTimer;
  int _undoSecondsRemaining = 5;
  bool _canUndo = true;
  bool _deleteInProgress = false;
  BulkDeleteResult? _result;

  @override
  void initState() {
    super.initState();
    _startUndoTimer();
    _performDelete();
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  void _startUndoTimer() {
    _undoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_undoSecondsRemaining > 0) {
        setState(() => _undoSecondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _canUndo = false);
      }
    });
  }

  Future<void> _performDelete() async {
    setState(() => _deleteInProgress = true);

    try {
      final result = await widget.onDelete(widget.itemIds);

      if (mounted) {
        setState(() {
          _result = result;
          _deleteInProgress = false;
          if (result.isSuccessful) {
            _status = BulkDeleteStatus.completed;
          } else if (result.isPartialFailure) {
            _status = BulkDeleteStatus.partialFailure;
          } else {
            _status = BulkDeleteStatus.error;
          }
        });

        // Auto-dismiss on success after 2 seconds
        if (result.isSuccessful && mounted) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
              widget.onComplete?.call();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = BulkDeleteStatus.error;
          _deleteInProgress = false;
        });
      }
    }
  }

  void _undoDelete() {
    if (_canUndo && !_deleteInProgress) {
      _undoTimer?.cancel();
      Navigator.pop(context);
      HapticUtils.lightImpact();
      showToast('Delete cancelled');
    }
  }

  void _dismiss() {
    Navigator.pop(context);
    widget.onComplete?.call();
  }

  String _getItemTypeLabel() {
    return widget.itemType == 'itineraries' ? 'visit' : 'client';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          const SizedBox(height: 24),

          // Content based on status
          if (_status == BulkDeleteStatus.deleting) ..._buildDeletingContent(),
          if (_status == BulkDeleteStatus.completed) ..._buildCompletedContent(),
          if (_status == BulkDeleteStatus.partialFailure) ..._buildPartialFailureContent(),
          if (_status == BulkDeleteStatus.error) ..._buildErrorContent(),
        ],
      ),
    );
  }

  List<Widget> _buildDeletingContent() {
    return [
      // Icon
      Icon(
        LucideIcons.trash2,
        size: 48,
        color: Colors.grey[400],
      ),
      const SizedBox(height: 16),

      // Title
      Text(
        'Deleting ${widget.itemIds.length} ${_getItemTypeLabel()}${widget.itemIds.length == 1 ? '' : 's'}...',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 24),

      // Progress indicator (indeterminate)
      SizedBox(
        width: 200,
        child: LinearProgressIndicator(
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
        ),
      ),

      const SizedBox(height: 32),

      // Undo and Cancel buttons
      Row(
        children: [
          // Undo button
          Expanded(
            child: _PillButton(
              icon: Icon(
                LucideIcons.rotateCcw,
                size: 16,
                color: _canUndo ? const Color(0xFF0F172A) : Colors.grey,
              ),
              label: _canUndo ? 'Undo (${_undoSecondsRemaining}s)' : 'Too late',
              onTap: _canUndo ? _undoDelete : null,
              isEnabled: _canUndo,
            ),
          ),
          const SizedBox(width: 12),
          // Cancel button
          GestureDetector(
            onTap: () {
              HapticUtils.lightImpact();
              _dismiss();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                LucideIcons.x,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildCompletedContent() {
    final count = _result?.successCount ?? 0;

    return [
      // Success icon
      Icon(
        LucideIcons.checkCircle,
        size: 48,
        color: Colors.green[600],
      ),
      const SizedBox(height: 16),

      // Title
      Text(
        '$count ${_getItemTypeLabel()}${count == 1 ? '' : 's'} deleted',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 32),

      // OK button
      SizedBox(
        width: 200,
        height: 48,
        child: ElevatedButton(
          onPressed: _dismiss,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('OK'),
        ),
      ),
    ];
  }

  List<Widget> _buildPartialFailureContent() {
    final successCount = _result?.successCount ?? 0;
    final errorCount = _result?.errorCount ?? 0;

    return [
      // Warning icon
      Icon(
        LucideIcons.alertTriangle,
        size: 48,
        color: Colors.orange[600],
      ),
      const SizedBox(height: 16),

      // Title
      Text(
        '$successCount deleted, $errorCount failed',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 16),

      // Error list
      if (_result?.errors.isNotEmpty ?? false)
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _result!.errors.length,
            itemBuilder: (context, index) {
              final error = _result!.errors[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.x,
                      size: 14,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${error.itemName ?? error.id}: ${error.error}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

      const SizedBox(height: 24),

      // Action buttons
      Row(
        children: [
          // OK button
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _dismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildErrorContent() {
    return [
      // Error icon
      Icon(
        LucideIcons.alertCircle,
        size: 48,
        color: Colors.red[400],
      ),
      const SizedBox(height: 16),

      // Title
      const Text(
        'Delete Failed',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 8),

      // Error message
      Text(
        _getErrorMessage(),
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 32),

      // Retry button
      SizedBox(
        width: 200,
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // User can retry by selecting items and tapping Remove again
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('OK'),
        ),
      ),
    ];
  }

  String _getErrorMessage() {
    if (_result?.message != null) {
      return _result!.message!;
    }
    return 'Could not delete items. Please check your connection and try again.';
  }
}

class _PillButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _PillButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isEnabled
              ? const Color(0xFFF1F5F9)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled
                ? const Color(0xFFE2E8F0)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isEnabled
                    ? const Color(0xFF0F172A)
                    : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
