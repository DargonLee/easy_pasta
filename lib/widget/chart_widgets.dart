import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:easy_pasta/model/clipboard_analytics.dart';

// ==================== 饼图组件 ====================

class PurposeChartWidget extends StatefulWidget {
  const PurposeChartWidget({super.key});

  @override
  State<PurposeChartWidget> createState() => _PurposeChartWidgetState();
}

class _PurposeChartWidgetState extends State<PurposeChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _hoveredIndex;

  final List<ChartData> _data = [
    ChartData('代码', 327, AppColors.accentCyan),
    ChartData('文本', 189, AppColors.accentPurple),
    ChartData('链接', 156, AppColors.accentPink),
    ChartData('个人信息', 87, AppColors.accentGreen),
    ChartData('其他', 43, AppColors.accentOrange),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Donut chart
        SizedBox(
          height: 220,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              painter: DonutChartPainter(
                data: _data,
                progress: _controller.value,
                hoveredIndex: _hoveredIndex,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(_data.length, (index) {
            return _buildLegendItem(_data[index], index);
          }),
        ),
      ],
    );
  }

  Widget _buildLegendItem(ChartData data, int index) {
    final isHovered = _hoveredIndex == index;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isHovered ? data.color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: data.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              data.label,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                color: isHovered ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isHovered ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${data.value}',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                color: data.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double progress;
  final int? hoveredIndex;

  DonutChartPainter({
    required this.data,
    required this.progress,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final innerRadius = radius * 0.6;

    final total = data.fold<int>(0, (sum, item) => sum + item.value);
    var startAngle = -math.pi / 2;

    for (var i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * math.pi * progress;
      final isHovered = hoveredIndex == i;
      final currentRadius = isHovered ? radius + 10 : radius;

      final paint = Paint()
        ..color = data[i].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentRadius - innerRadius
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(
        center: center,
        radius: (currentRadius + innerRadius) / 2,
      );

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      // Glow effect for hovered segment
      if (isHovered) {
        final glowPaint = Paint()
          ..color = data[i].color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = currentRadius - innerRadius + 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

        canvas.drawArc(
          rect,
          startAngle,
          sweepAngle,
          false,
          glowPaint,
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) =>
      progress != oldDelegate.progress || hoveredIndex != oldDelegate.hoveredIndex;
}

// ==================== 趋势图组件 ====================

class TrendChartWidget extends StatefulWidget {
  const TrendChartWidget({super.key});

  @override
  State<TrendChartWidget> createState() => _TrendChartWidgetState();
}

class _TrendChartWidgetState extends State<TrendChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _hoveredIndex;

  final List<TrendData> _data = [
    TrendData('周一', 156),
    TrendData('周二', 198),
    TrendData('周三', 234),
    TrendData('周四', 187),
    TrendData('周五', 245),
    TrendData('周六', 89),
    TrendData('周日', 67),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: TrendChartPainter(
          data: _data,
          progress: _controller.value,
          hoveredIndex: _hoveredIndex,
        ),
        child: SizedBox(
          height: 250,
          child: GestureDetector(
            onTapDown: (details) {
              final index = _getIndexFromPosition(details.localPosition);
              setState(() => _hoveredIndex = index);
            },
          ),
        ),
      ),
    );
  }

  int? _getIndexFromPosition(Offset position) {
    // Simple approximation
    final index = (position.dx / (MediaQuery.of(context).size.width / _data.length)).floor();
    if (index >= 0 && index < _data.length) {
      return index;
    }
    return null;
  }
}

class TrendChartPainter extends CustomPainter {
  final List<TrendData> data;
  final double progress;
  final int? hoveredIndex;

  TrendChartPainter({
    required this.data,
    required this.progress,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.map((d) => d.value).reduce(math.max).toDouble();
    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final stepX = chartWidth / (data.length - 1);

    // Draw grid lines
    _drawGrid(canvas, size, padding, chartHeight, maxValue);

    // Draw area fill
    _drawAreaFill(canvas, size, padding, chartHeight, maxValue, stepX);

    // Draw line
    _drawLine(canvas, size, padding, chartHeight, maxValue, stepX);

    // Draw points
    _drawPoints(canvas, size, padding, chartHeight, maxValue, stepX);

    // Draw labels
    _drawLabels(canvas, size, padding, chartHeight);
  }

  void _drawGrid(Canvas canvas, Size size, double padding, double chartHeight, double maxValue) {
    final gridPaint = Paint()
      ..color = AppColors.borderColor
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = padding + (chartHeight * i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }
  }

  void _drawAreaFill(
    Canvas canvas,
    Size size,
    double padding,
    double chartHeight,
    double maxValue,
    double stepX,
  ) {
    final path = Path();
    path.moveTo(padding, size.height - padding);

    for (var i = 0; i < data.length; i++) {
      final x = padding + i * stepX;
      final y = padding + chartHeight - (data[i].value / maxValue * chartHeight * progress);
      
      if (i == 0) {
        path.lineTo(x, y);
      } else {
        final prevX = padding + (i - 1) * stepX;
        final prevY = padding + chartHeight - (data[i - 1].value / maxValue * chartHeight * progress);
        final controlX = (prevX + x) / 2;
        
        path.cubicTo(
          controlX, prevY,
          controlX, y,
          x, y,
        );
      }
    }

    path.lineTo(size.width - padding, size.height - padding);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.accentCyan.withOpacity(0.3),
        AppColors.accentCyan.withOpacity(0.05),
      ],
    );

    canvas.drawPath(
      path,
      Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    double padding,
    double chartHeight,
    double maxValue,
    double stepX,
  ) {
    final path = Path();
    
    for (var i = 0; i < data.length; i++) {
      final x = padding + i * stepX;
      final y = padding + chartHeight - (data[i].value / maxValue * chartHeight * progress);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = padding + (i - 1) * stepX;
        final prevY = padding + chartHeight - (data[i - 1].value / maxValue * chartHeight * progress);
        final controlX = (prevX + x) / 2;
        
        path.cubicTo(
          controlX, prevY,
          controlX, y,
          x, y,
        );
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accentCyan
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawPoints(
    Canvas canvas,
    Size size,
    double padding,
    double chartHeight,
    double maxValue,
    double stepX,
  ) {
    for (var i = 0; i < data.length; i++) {
      final x = padding + i * stepX;
      final y = padding + chartHeight - (data[i].value / maxValue * chartHeight * progress);
      final isHovered = hoveredIndex == i;

      // Glow
      if (isHovered) {
        canvas.drawCircle(
          Offset(x, y),
          10,
          Paint()
            ..color = AppColors.accentCyan.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }

      // Outer circle
      canvas.drawCircle(
        Offset(x, y),
        isHovered ? 7 : 5,
        Paint()..color = AppColors.accentCyan,
      );

      // Inner circle
      canvas.drawCircle(
        Offset(x, y),
        isHovered ? 4 : 2,
        Paint()..color = AppColors.bgPrimary,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size, double padding, double chartHeight) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var i = 0; i < data.length; i++) {
      final x = padding + i * ((size.width - padding * 2) / (data.length - 1));
      
      textPainter.text = TextSpan(
        text: data[i].label,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 10,
          color: AppColors.textMuted,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - padding + 10),
      );
    }
  }

  @override
  bool shouldRepaint(TrendChartPainter oldDelegate) =>
      progress != oldDelegate.progress || hoveredIndex != oldDelegate.hoveredIndex;
}

// ==================== 应用流转图 ====================

class AppFlowWidget extends StatefulWidget {
  const AppFlowWidget({super.key});

  @override
  State<AppFlowWidget> createState() => _AppFlowWidgetState();
}

class _AppFlowWidgetState extends State<AppFlowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<FlowConnection> _flows = [
    FlowConnection('VS Code', 'Terminal', 145, 0),
    FlowConnection('Chrome', 'VS Code', 98, 1),
    FlowConnection('Notion', 'Slack', 67, 2),
    FlowConnection('Figma', 'VS Code', 54, 3),
    FlowConnection('Terminal', 'VS Code', 43, 4),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: FlowDiagramPainter(
            flows: _flows,
            progress: _controller.value,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class FlowDiagramPainter extends CustomPainter {
  final List<FlowConnection> flows;
  final double progress;

  FlowDiagramPainter({
    required this.flows,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final apps = _getUniqueApps();
    final positions = _calculatePositions(apps, size);

    // Draw connections first
    for (var i = 0; i < flows.length; i++) {
      if (progress >= i / flows.length) {
        _drawConnection(canvas, flows[i], positions, size);
      }
    }

    // Draw nodes on top
    for (final app in apps) {
      _drawNode(canvas, app, positions[app]!, size);
    }
  }

  List<String> _getUniqueApps() {
    final apps = <String>{};
    for (final flow in flows) {
      apps.add(flow.source);
      apps.add(flow.target);
    }
    return apps.toList();
  }

  Map<String, Offset> _calculatePositions(List<String> apps, Size size) {
    final positions = <String, Offset>{};
    final padding = 60.0;
    
    for (var i = 0; i < apps.length; i++) {
      final x = i % 2 == 0 ? padding : size.width - padding;
      final y = (i * size.height / apps.length) + padding;
      positions[apps[i]] = Offset(x, y);
    }
    
    return positions;
  }

  void _drawConnection(
    Canvas canvas,
    FlowConnection flow,
    Map<String, Offset> positions,
    Size size,
  ) {
    final start = positions[flow.source]!;
    final end = positions[flow.target]!;
    final thickness = (flow.count / 150 * 10).clamp(2.0, 15.0);

    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    final controlX = size.width / 2;
    final controlY = (start.dy + end.dy) / 2;
    
    path.quadraticBezierTo(
      controlX, controlY,
      end.dx, end.dy,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accentCyan.withOpacity(
          math.min(flow.count / 150, 0.8),
        )
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawNode(Canvas canvas, String app, Offset position, Size size) {
    // Outer glow
    canvas.drawCircle(
      position,
      16,
      Paint()
        ..color = AppColors.accentCyan.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Circle
    canvas.drawCircle(
      position,
      12,
      Paint()..color = AppColors.accentCyan,
    );

    canvas.drawCircle(
      position,
      10,
      Paint()..color = AppColors.bgSecondary,
    );

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: app,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 12,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - 30,
      ),
    );
  }

  @override
  bool shouldRepaint(FlowDiagramPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// ==================== 数据模型 ====================

class ChartData {
  final String label;
  final int value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}

class TrendData {
  final String label;
  final int value;

  TrendData(this.label, this.value);
}

class FlowConnection {
  final String source;
  final String target;
  final int count;
  final int index;

  FlowConnection(this.source, this.target, this.count, this.index);
}

// ==================== 颜色定义 ====================

class AppColors {
  static const bgPrimary = Color(0xFF0A0E14);
  static const bgSecondary = Color(0xFF121820);
  static const bgTertiary = Color(0xFF1A1F2E);
  
  static const accentCyan = Color(0xFF00D9FF);
  static const accentPurple = Color(0xFFA855F7);
  static const accentPink = Color(0xFFEC4899);
  static const accentGreen = Color(0xFF10B981);
  static const accentOrange = Color(0xFFF59E0B);
  
  static const textPrimary = Color(0xFFE0E7FF);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
  
  static const borderColor = Color(0x1A94A3B8);
  static const glowCyan = Color(0x4D00D9FF);
  static const glowPurple = Color(0x4DA855F7);
}
