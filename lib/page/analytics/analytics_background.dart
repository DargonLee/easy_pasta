import 'package:flutter/material.dart';
import 'package:easy_pasta/page/analytics/analytics_styles.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grid pattern
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            painter: GridPainter(opacity: 0.3 + (_controller.value * 0.3)),
            size: Size.infinite,
          ),
        ),

        // Floating orbs
        const Positioned(
          top: -100,
          left: -100,
          child: _GlowOrb(
            color: AppColors.accentCyan,
            size: 400,
            delay: 0,
          ),
        ),
        const Positioned(
          bottom: -150,
          right: -150,
          child: _GlowOrb(
            color: AppColors.accentPurple,
            size: 500,
            delay: 5,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          right: MediaQuery.of(context).size.width * 0.1,
          child: const _GlowOrb(
            color: AppColors.accentPink,
            size: 300,
            delay: 10,
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  final double opacity;

  GridPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentCyan.withOpacity(opacity * 0.03)
      ..strokeWidth = 1;

    const spacing = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => opacity != oldDelegate.opacity;
}

class _GlowOrb extends StatefulWidget {
  final Color color;
  final double size;
  final int delay;

  const _GlowOrb({
    required this.color,
    required this.size,
    required this.delay,
  });

  @override
  State<_GlowOrb> createState() => _GlowOrbState();
}

class _GlowOrbState extends State<_GlowOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _animation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(30, -30)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(30, -30), end: const Offset(-20, 20)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-20, 20), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(_controller);

    Future.delayed(Duration(seconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.translate(
        offset: _animation.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withOpacity(0.15),
                widget.color.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
