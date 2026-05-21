import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom arc meter (gauge) using CustomPainter.
/// Draws a sweeping arc from -150° to +150° (300° total sweep).
class ArcMeterPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color trackColor;
  final Color fillColor;
  final Color dangerColor;
  final double strokeWidth;
  final bool showGlow;

  const ArcMeterPainter({
    required this.progress,
    this.trackColor = const Color(0xFF2A2A45),
    this.fillColor = const Color(0xFF6C63FF),
    this.dangerColor = const Color(0xFFFF5252),
    this.strokeWidth = 14.0,
    this.showGlow = true,
  });

  static const double _startAngle = 150 * math.pi / 180; // 150° in radians
  static const double _sweepTotal = 240 * math.pi / 180; // 240° sweep

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track (background arc)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      math.pi / 2 + _startAngle,
      _sweepTotal,
      false,
      trackPaint,
    );

    if (progress <= 0) return;

    final clampedProgress = progress.clamp(0.0, 1.0);
    final isOverBudget = progress > 1.0;
    final activeColor = isOverBudget ? dangerColor : fillColor;

    // Glow effect
    if (showGlow) {
      final glowPaint = Paint()
        ..color = activeColor.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        rect,
        math.pi / 2 + _startAngle,
        _sweepTotal * clampedProgress,
        false,
        glowPaint,
      );
    }

    // Gradient fill arc
    final gradient = SweepGradient(
      startAngle: math.pi / 2 + _startAngle,
      endAngle: math.pi / 2 + _startAngle + _sweepTotal,
      colors: isOverBudget
          ? [dangerColor.withOpacity(0.7), dangerColor]
          : [fillColor.withOpacity(0.7), fillColor],
      tileMode: TileMode.clamp,
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      math.pi / 2 + _startAngle,
      _sweepTotal * clampedProgress,
      false,
      fillPaint,
    );

    // Thumb dot at the end of the arc
    final thumbAngle =
        math.pi / 2 + _startAngle + _sweepTotal * clampedProgress;
    final thumbX = center.dx + radius * math.cos(thumbAngle);
    final thumbY = center.dy + radius * math.sin(thumbAngle);

    final thumbPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(thumbX, thumbY), strokeWidth / 2 + 2, thumbPaint);

    // Inner white dot
    canvas.drawCircle(
      Offset(thumbX, thumbY),
      strokeWidth / 4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(ArcMeterPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.dangerColor != dangerColor;
}

/// Animated arc meter widget
class AnimatedArcMeter extends StatefulWidget {
  final double progress;
  final double size;
  final Color? fillColor;
  final Widget? child;
  final Duration duration;

  const AnimatedArcMeter({
    super.key,
    required this.progress,
    this.size = 160,
    this.fillColor,
    this.child,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<AnimatedArcMeter> createState() => _AnimatedArcMeterState();
}

class _AnimatedArcMeterState extends State<AnimatedArcMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedArcMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = _animation.value;
      _animation =
          Tween<double>(begin: _previousProgress, end: widget.progress)
              .animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: ArcMeterPainter(
              progress: _animation.value,
              fillColor: widget.fillColor ?? const Color(0xFF6C63FF),
            ),
            child: child,
          );
        },
        child: widget.child != null
            ? Center(child: widget.child)
            : null,
      ),
    );
  }
}
