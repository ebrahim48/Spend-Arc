import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Animated aurora background using the GLSL fragment shader.
/// Wrap any screen with this for the aurora effect.
class AuroraBackground extends StatefulWidget {
  final Widget child;

  const AuroraBackground({super.key, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ui.FragmentShader? _shader;
  bool _shaderLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/aurora.frag');
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
          _shaderLoaded = true;
        });
      }
    } catch (_) {
      // Shader not available — graceful fallback
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shaderLoaded || _shader == null) {
      return widget.child;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _AuroraPainter(
                  shader: _shader!,
                  time: _controller.value * 60.0,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;

  const _AuroraPainter({required this.shader, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, time)
      ..setFloat(1, size.width)
      ..setFloat(2, size.height)
      // uColor1 — purple
      ..setFloat(3, 0.42)
      ..setFloat(4, 0.39)
      ..setFloat(5, 1.0)
      ..setFloat(6, 1.0)
      // uColor2 — teal
      ..setFloat(7, 0.01)
      ..setFloat(8, 0.85)
      ..setFloat(9, 0.78)
      ..setFloat(10, 1.0);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) =>
      oldDelegate.time != time;
}
