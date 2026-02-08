part of '../chart_widgets.dart';

// ==================== 饼图组件 ====================

class PurposeChartWidget extends StatefulWidget {
  final TimePeriod period;

  const PurposeChartWidget({
    super.key,
    this.period = TimePeriod.week,
  });

  @override
  State<PurposeChartWidget> createState() => _PurposeChartWidgetState();
}

class _PurposeChartWidgetState extends State<PurposeChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Future<List<ChartData>> _dataFuture;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _dataFuture = _loadChartData();
  }

  void _initializeController() {
    _controller = AnimationController(
      vsync: this,
      duration: ChartConstants.animationDuration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PurposeChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      setState(() {
        _hoveredIndex = null;
        _dataFuture = _loadChartData();
      });
    }
  }

  Future<List<ChartData>> _loadChartData() async {
    final distribution = await ClipboardAnalyticsService.instance
        .getContentTypeDistribution(period: widget.period);

    if (distribution.isEmpty) {
      return const <ChartData>[];
    }

    final chartData = _processDistributionData(distribution);

    if (mounted && chartData.isNotEmpty) {
      _controller.forward(from: 0);
    }

    return chartData;
  }

  List<ChartData> _processDistributionData(Map<String, int> distribution) {
    final sortedEntries = distribution.entries
        .where((entry) => entry.value > 0)
        .toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    return List<ChartData>.generate(
      sortedEntries.length,
      (index) => ChartData(
        _getTypeLabel(sortedEntries[index].key),
        sortedEntries[index].value,
        ChartConstants.chartPalette[index % ChartConstants.chartPalette.length],
      ),
      growable: false,
    );
  }

  String _getTypeLabel(String rawType) {
    return ChartConstants.contentTypeLabels[rawType.trim().toLowerCase()] ??
        '其他';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChartData>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ChartLoadingIndicator();
        }

        if (snapshot.hasError) {
          return const ChartEmptyState(message: '加载内容类型分布失败');
        }

        final data = snapshot.data ?? const <ChartData>[];
        if (data.isEmpty) {
          return const ChartEmptyState(message: '当前时间范围暂无内容类型数据');
        }

        return _buildChart(data);
      },
    );
  }

  Widget _buildChart(List<ChartData> data) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: DonutChartPainter(
                data: data,
                progress: _controller.value,
                hoveredIndex: _hoveredIndex,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildLegend(data),
      ],
    );
  }

  Widget _buildLegend(List<ChartData> data) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(
        data.length,
        (index) => _LegendItem(
          data: data[index],
          index: index,
          isHovered: _hoveredIndex == index,
          onHover: (hovered) =>
              setState(() => _hoveredIndex = hovered ? index : null),
        ),
      ),
    );
  }
}

/// 图例项组件
class _LegendItem extends StatelessWidget {
  final ChartData data;
  final int index;
  final bool isHovered;
  final ValueChanged<bool> onHover;

  const _LegendItem({
    required this.data,
    required this.index,
    required this.isHovered,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isHovered
              ? data.color.withValues(alpha: 0.1)
              : Colors.transparent,
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
                color:
                    isHovered ? AppColors.textPrimary : AppColors.textSecondary,
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

  static const _hoverRadiusOffset = 10.0;
  static const _glowBlurRadius = 10.0;
  static const _glowRadiusOffset = 10.0;
  static const _innerRadiusRatio = 0.6;
  static const _chartPadding = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _chartPadding;
    final innerRadius = radius * _innerRadiusRatio;
    final total = data.fold<int>(0, (sum, item) => sum + item.value);

    if (total <= 0) return;

    var startAngle = -math.pi / 2;

    for (var i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * math.pi * progress;
      final isHovered = hoveredIndex == i;

      _drawSegment(
        canvas,
        center,
        radius,
        innerRadius,
        startAngle,
        sweepAngle,
        data[i].color,
        isHovered,
      );

      startAngle += sweepAngle;
    }
  }

  void _drawSegment(
    Canvas canvas,
    Offset center,
    double radius,
    double innerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
    bool isHovered,
  ) {
    final currentRadius = isHovered ? radius + _hoverRadiusOffset : radius;
    final strokeWidth = currentRadius - innerRadius;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: center,
      radius: (currentRadius + innerRadius) / 2,
    );

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    if (isHovered) {
      _drawGlow(canvas, rect, startAngle, sweepAngle, color, strokeWidth);
    }
  }

  void _drawGlow(
    Canvas canvas,
    Rect rect,
    double startAngle,
    double sweepAngle,
    Color color,
    double strokeWidth,
  ) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + _glowRadiusOffset
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _glowBlurRadius);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        hoveredIndex != oldDelegate.hoveredIndex ||
        data.length != oldDelegate.data.length ||
        _getTotalValue() != oldDelegate._getTotalValue();
  }

  int _getTotalValue() => data.fold<int>(0, (sum, item) => sum + item.value);
}
