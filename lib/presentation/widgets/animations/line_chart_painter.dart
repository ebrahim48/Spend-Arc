import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/entities/chart_data.dart';

/// Fully custom line chart drawn from scratch with CustomPainter.
/// Features: animated draw-on, gradient fill, dot highlights, grid lines.
class LineChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final double maxValue;
  final double animationProgress; // 0.0 to 1.0
  final Color incomeColor;
  final Color expenseColor;
  final bool showIncome;
  final bool showExpense;

  const LineChartPainter({
    required this.points,
    required this.maxValue,
    required this.animationProgress,
    this.incomeColor = const Color(0xFF4CAF50),
    this.expenseColor = const Color(0xFFFF5252),
    this.showIncome = true,
    this.showExpense = true,
  });

  static const double _paddingLeft = 40;
  static const double _paddingRight = 16;
  static const double _paddingTop = 16;
  static const double _paddingBottom = 32;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartWidth = size.width - _paddingLeft - _paddingRight;
    final chartHeight = size.height - _paddingTop - _paddingBottom;
    final effectiveMax = maxValue > 0 ? maxValue : 1.0;

    // Draw grid
    _drawGrid(canvas, size, chartWidth, chartHeight, effectiveMax);

    // Draw income line
    if (showIncome) {
      _drawLine(
        canvas,
        size,
        chartWidth,
        chartHeight,
        effectiveMax,
        points.map((p) => p.income).toList(),
        incomeColor,
        fillBelow: true,
      );
    }

    // Draw expense line
    if (showExpense) {
      _drawLine(
        canvas,
        size,
        chartWidth,
        chartHeight,
        effectiveMax,
        points.map((p) => p.expense).toList(),
        expenseColor,
        fillBelow: false,
      );
    }

    // Draw x-axis labels
    _drawXLabels(canvas, size, chartWidth, chartHeight);
  }

  void _drawGrid(Canvas canvas, Size size, double chartWidth,
      double chartHeight, double effectiveMax) {
    final gridPaint = Paint()
      ..color = const Color(0xFF2A2A45)
      ..strokeWidth = 1;

    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = _paddingTop + chartHeight * (1 - i / gridLines);
      canvas.drawLine(
        Offset(_paddingLeft, y),
        Offset(_paddingLeft + chartWidth, y),
        gridPaint,
      );

      // Y-axis labels
      final value = effectiveMax * i / gridLines;
      final label = _formatValue(value);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF9090B0),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(_paddingLeft - tp.width - 4, y - tp.height / 2),
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
    double effectiveMax,
    List<double> values,
    Color color, {
    required bool fillBelow,
  }) {
    if (values.isEmpty) return;

    final totalPoints = values.length;
    final visibleCount =
        (totalPoints * animationProgress).ceil().clamp(1, totalPoints);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < visibleCount; i++) {
      final x = _paddingLeft + (i / (totalPoints - 1)) * chartWidth;
      final y = _paddingTop + chartHeight * (1 - values[i] / effectiveMax);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, _paddingTop + chartHeight);
        fillPath.lineTo(x, y);
      } else {
        // Smooth bezier curve
        final prevX =
            _paddingLeft + ((i - 1) / (totalPoints - 1)) * chartWidth;
        final prevY =
            _paddingTop + chartHeight * (1 - values[i - 1] / effectiveMax);
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    // Fill gradient
    if (fillBelow) {
      final lastX = _paddingLeft +
          ((visibleCount - 1) / (totalPoints - 1)) * chartWidth;
      fillPath.lineTo(lastX, _paddingTop + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(
          _paddingLeft,
          _paddingTop,
          chartWidth,
          chartHeight,
        ))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Dots at data points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < visibleCount; i++) {
      final x = _paddingLeft + (i / (totalPoints - 1)) * chartWidth;
      final y = _paddingTop + chartHeight * (1 - values[i] / effectiveMax);
      canvas.drawCircle(Offset(x, y), 5, dotBorderPaint);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  void _drawXLabels(
      Canvas canvas, Size size, double chartWidth, double chartHeight) {
    if (points.isEmpty) return;

    final step = math.max(1, (points.length / 5).round());
    for (int i = 0; i < points.length; i += step) {
      final x = _paddingLeft + (i / (points.length - 1)) * chartWidth;
      final label =
          '${points[i].date.month}/${points[i].date.day}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF9090B0),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, _paddingTop + chartHeight + 6),
      );
    }
  }

  String _formatValue(double value) {
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}k';
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) =>
      oldDelegate.animationProgress != animationProgress ||
      oldDelegate.points != points ||
      oldDelegate.maxValue != maxValue;
}

/// Animated line chart widget
class AnimatedLineChart extends StatefulWidget {
  final List<ChartPoint> points;
  final double maxValue;
  final double height;
  final bool showIncome;
  final bool showExpense;

  const AnimatedLineChart({
    super.key,
    required this.points,
    required this.maxValue,
    this.height = 200,
    this.showIncome = true,
    this.showExpense = true,
  });

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
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
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => CustomPaint(
          painter: LineChartPainter(
            points: widget.points,
            maxValue: widget.maxValue,
            animationProgress: _animation.value,
            showIncome: widget.showIncome,
            showExpense: widget.showExpense,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
