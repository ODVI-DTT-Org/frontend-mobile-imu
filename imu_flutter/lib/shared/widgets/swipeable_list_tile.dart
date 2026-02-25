import 'package:flutter/material.dart';
import '../../core/utils/haptic_utils.dart';

/// Swipeable list tile with actions
class SwipeableListTile extends StatefulWidget {
  final Widget child;
  final List<SwipeAction> leftActions;
  final List<SwipeAction> rightActions;
  final double actionWidth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SwipeableListTile({
    super.key,
    required this.child,
    this.leftActions = const [],
    this.rightActions = const [],
    this.actionWidth = 80,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<SwipeableListTile> createState() => _SwipeableListTileState();
}

class _SwipeableListTileState extends State<SwipeableListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  double _dragExtent = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _isDragging = true;
    HapticUtils.lightImpact();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      _dragExtent += details.delta.dx;
      // Limit drag extent
      final maxDrag = widget.actionWidth * widget.rightActions.length;
      final minDrag = -widget.actionWidth * widget.leftActions.length;
      _dragExtent = _dragExtent.clamp(minDrag.toDouble(), maxDrag.toDouble());
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    _isDragging = false;
    final threshold = widget.actionWidth * 0.5;

    if (_dragExtent.abs() > threshold) {
      // Snap open
      HapticUtils.mediumImpact();
    } else {
      // Snap closed
      setState(() => _dragExtent = 0);
      HapticUtils.lightImpact();
    }
  }

  void _close() {
    setState(() => _dragExtent = 0);
    HapticUtils.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final hasLeftActions = widget.leftActions.isNotEmpty;
    final hasRightActions = widget.rightActions.isNotEmpty;

    return Stack(
      children: [
        // Background actions
        if (hasRightActions)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: widget.rightActions.map((action) {
                return _SwipeActionWidget(
                  action: action,
                  width: widget.actionWidth,
                  onClose: _close,
                );
              }).toList(),
            ),
          ),
        if (hasLeftActions)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.leftActions.map((action) {
                return _SwipeActionWidget(
                  action: action,
                  width: widget.actionWidth,
                  onClose: _close,
                );
              }).toList(),
            ),
          ),
        // Foreground content
        GestureDetector(
          onHorizontalDragStart: hasLeftActions || hasRightActions
              ? _handleDragStart
              : null,
          onHorizontalDragUpdate: hasLeftActions || hasRightActions
              ? _handleDragUpdate
              : null,
          onHorizontalDragEnd: hasLeftActions || hasRightActions
              ? _handleDragEnd
              : null,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: Container(
              color: Colors.white,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

class _SwipeActionWidget extends StatelessWidget {
  final SwipeAction action;
  final double width;
  final VoidCallback onClose;

  const _SwipeActionWidget({
    required this.action,
    required this.width,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticUtils.mediumImpact();
        onClose();
        action.onTap();
      },
      child: Container(
        width: width,
        color: action.backgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.foregroundColor),
            const SizedBox(height: 4),
            Text(
              action.label,
              style: TextStyle(
                color: action.foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Swipe action configuration
class SwipeAction {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const SwipeAction({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
    required this.onTap,
  });

  // Common actions
  static SwipeAction edit(VoidCallback onTap) => SwipeAction(
        icon: Icons.edit,
        label: 'Edit',
        backgroundColor: Colors.blue,
        onTap: onTap,
      );

  static SwipeAction delete(VoidCallback onTap) => SwipeAction(
        icon: Icons.delete,
        label: 'Delete',
        backgroundColor: Colors.red,
        onTap: onTap,
      );

  static SwipeAction archive(VoidCallback onTap) => SwipeAction(
        icon: Icons.archive,
        label: 'Archive',
        backgroundColor: Colors.orange,
        onTap: onTap,
      );

  static SwipeAction call(VoidCallback onTap) => SwipeAction(
        icon: Icons.phone,
        label: 'Call',
        backgroundColor: Colors.green,
        onTap: onTap,
      );

  static SwipeAction navigate(VoidCallback onTap) => SwipeAction(
        icon: Icons.directions,
        label: 'Navigate',
        backgroundColor: Colors.blue,
        onTap: onTap,
      );

  static SwipeAction favorite(VoidCallback onTap) => SwipeAction(
        icon: Icons.star,
        label: 'Star',
        backgroundColor: Colors.amber,
        onTap: onTap,
      );

  static SwipeAction more(VoidCallback onTap) => SwipeAction(
        icon: Icons.more_horiz,
        label: 'More',
        backgroundColor: Colors.grey,
        onTap: onTap,
      );
}
