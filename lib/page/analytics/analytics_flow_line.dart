import 'package:flutter/material.dart';
import 'package:easy_pasta/page/analytics/analytics_styles.dart';

class DataFlowLine extends StatefulWidget {
  const DataFlowLine({super.key});

  @override
  State<DataFlowLine> createState() => _DataFlowLineState();
}

class _DataFlowLineState extends State<DataFlowLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: FlowLinePainter(progress: _controller.value),
        ),
      ),
    );
  }
}

class FlowLinePainter extends CustomPainter {
  final double progress;

  FlowLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: const [
          Colors.transparent,
          AnalyticsColors.accentCyan,
          AnalyticsColors.accentPurple,
          Colors.transparent,
        ],
        stops: [
          (progress - 0.3).clamp(0, 1),
          progress.clamp(0, 1),
          (progress + 0.1).clamp(0, 1),
          (progress + 0.3).clamp(0, 1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(FlowLinePainter oldDelegate) =>
      progress != oldDelegate.progress;
}
