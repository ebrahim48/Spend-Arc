import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A particle that flies outward from a center point.
class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotationSpeed,
  });
}

class ParticleBurstPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0.0 to 1.0
  final Offset origin;

  const ParticleBurstPainter({
    required this.particles,
    required this.progress,
    required this.origin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final distance = p.speed * progress * 80;
      final x = origin.dx + math.cos(p.angle) * distance;
      final y = origin.dy + math.sin(p.angle) * distance;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final currentSize = p.size * (1 - progress * 0.5);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotationSpeed * progress * math.pi * 2);

      // Draw small diamond shape
      final path = Path()
        ..moveTo(0, -currentSize)
        ..lineTo(currentSize * 0.5, 0)
        ..lineTo(0, currentSize)
        ..lineTo(-currentSize * 0.5, 0)
        ..close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ParticleBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Widget that triggers a particle burst animation at a given position.
class ParticleBurst extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final List<Color> colors;
  final int particleCount;
  final VoidCallback? onComplete;

  const ParticleBurst({
    super.key,
    required this.child,
    required this.trigger,
    this.colors = const [
      Color(0xFF6C63FF),
      Color(0xFF4CAF50),
      Color(0xFFFFCA28),
      Color(0xFFFF5252),
      Color(0xFF03DAC6),
    ],
    this.particleCount = 20,
    this.onComplete,
  });

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<_Particle> _particles;
  final _random = math.Random();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _generateParticles();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isPlaying = false);
        widget.onComplete?.call();
      }
    });
  }

  void _generateParticles() {
    _particles = List.generate(widget.particleCount, (i) {
      return _Particle(
        angle: (i / widget.particleCount) * math.pi * 2 +
            _random.nextDouble() * 0.5,
        speed: 0.5 + _random.nextDouble() * 0.8,
        size: 4 + _random.nextDouble() * 6,
        color: widget.colors[_random.nextInt(widget.colors.length)],
        rotationSpeed: _random.nextDouble() * 2 - 1,
      );
    });
  }

  @override
  void didUpdateWidget(ParticleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _generateParticles();
      setState(() => _isPlaying = true);
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_isPlaying)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) => CustomPaint(
                  painter: ParticleBurstPainter(
                    particles: _particles,
                    progress: _animation.value,
                    origin: const Offset(0, 0),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
