import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Spring-physics swipe-to-delete widget.
/// Uses a SpringSimulation for the snap-back / snap-away animation.
class SpringSwipeDelete extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback? onUndo;
  final double deleteThreshold;

  const SpringSwipeDelete({
    super.key,
    required this.child,
    required this.onDelete,
    this.onUndo,
    this.deleteThreshold = 0.45,
  });

  @override
  State<SpringSwipeDelete> createState() => _SpringSwipeDeleteState();
}

class _SpringSwipeDeleteState extends State<SpringSwipeDelete>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0;
  bool _isDismissed = false;

  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 28,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() => _dragOffset = _controller.value);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isDismissed) return;
    setState(() {
      _dragOffset += details.delta.dx;
      // Resist dragging right
      if (_dragOffset > 0) _dragOffset = _dragOffset * 0.2;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isDismissed) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = -screenWidth * widget.deleteThreshold;

    if (_dragOffset < threshold ||
        details.velocity.pixelsPerSecond.dx < -800) {
      // Dismiss with spring
      final simulation = SpringSimulation(
        _spring,
        _dragOffset,
        -screenWidth * 1.2,
        details.velocity.pixelsPerSecond.dx / screenWidth,
      );
      _controller.animateWith(simulation).then((_) {
        if (mounted) {
          setState(() => _isDismissed = true);
          widget.onDelete();
        }
      });
    } else {
      // Snap back with spring
      final simulation = SpringSimulation(
        _spring,
        _dragOffset,
        0,
        details.velocity.pixelsPerSecond.dx / screenWidth,
      );
      _controller.animateWith(simulation);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final deleteProgress =
        (-_dragOffset / (screenWidth * widget.deleteThreshold)).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          // Delete background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF2A2A45),
                  const Color(0xFFFF5252),
                  deleteProgress,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: Opacity(
                opacity: deleteProgress,
                child: Transform.scale(
                  scale: 0.5 + deleteProgress * 0.5,
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          // Sliding content
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
