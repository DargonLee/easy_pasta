part of '../chart_widgets.dart';

// ==================== 趋势图组件 ====================

class TrendChartWidget extends StatefulWidget {
  final TimePeriod period;

  const TrendChartWidget({
    super.key,
    this.period = TimePeriod.week,
  });

  @override
  State<TrendChartWidget> createState() => _TrendChartWidgetState();
}

class _TrendChartWidgetState extends State<TrendChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Future<List<TrendData>> _trendFuture;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ChartConstants.animationDuration,
    );
    _trendFuture = _loadTrendData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TrendChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      setState(() {
        _hoveredIndex = null;
        _trendFuture = _loadTrendData();
      });
    }
  }

  Future<List<TrendData>> _loadTrendData() async {
    final trendMap = await ClipboardAnalyticsService.instance
        .getDailyTrend(period: widget.period);

    if (trendMap.isEmpty) {
      return const <TrendData>[];
    }

    final trendData = _processTrendData(trendMap);

    if (mounted && trendData.isNotEmpty) {
      _controller.forward(from: 0);
    }

    return trendData;
  }

  List<TrendData> _processTrendData(Map<String, int> trendMap) {
    final sortedEntries = trendMap.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedEntries.map((entry) {
      final date = DateTime.tryParse(entry.key);
      final label = date == null ? entry.key : _formatDateLabel(date);
      return TrendData(label, entry.value);
    }).toList(growable: false);
  }

  String _formatDateLabel(DateTime date) {
    if (widget.period == TimePeriod.week) {
      return ChartConstants.dayNames[date.weekday % 7];
    }
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TrendData>>(
      future: _trendFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ChartLoadingIndicator();
        }

        if (snapshot.hasError) {
          return const ChartEmptyState(message: '加载趋势数据失败');
        }

        final data = snapshot.data ?? const <TrendData>[];
        if (data.isEmpty) {
          return const ChartEmptyState(message: '当前时间范围暂无趋势数据');
        }

        return _buildChart(data);
      },
    );
  }

  Widget _buildChart(List<TrendData> data) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: TrendChartPainter(
          data: data,
          progress: _controller.value,
          hoveredIndex: _hoveredIndex,
        ),
        child: SizedBox(
          height: ChartConstants.defaultChartHeight,
          child: GestureDetector(
            onTapDown: (details) {
              final index =
                  _getIndexFromPosition(details.localPosition, data.length);
              if (index != null) {
                setState(() => _hoveredIndex = index);
              }
            },
          ),
        ),
      ),
    );
  }

  int? _getIndexFromPosition(Offset position, int dataLength) {
    if (dataLength <= 0) return null;

    final width = MediaQuery.of(context).size.width;
    final index = (position.dx / (width / dataLength)).floor();

    return (index >= 0 && index < dataLength) ? index : null;
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

  static const _padding = 40.0;
  static const _gridLines = 4;
  static const _pointRadius = 5.0;
  static const _hoveredPointRadius = 7.0;
  static const _pointInnerRadius = 2.0;
  static const _hoveredPointInnerRadius = 4.0;
  static const _glowRadius = 10.0;
  static const _lineWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = _getMaxValue();
    if (maxValue <= 0) return;

    final chartWidth = size.width - _padding * 2;
    final chartHeight = size.height - _padding * 2;

    _drawGrid(canvas, size, chartHeight);
    _drawAreaFill(canvas, size, chartWidth, chartHeight, maxValue);
    _drawLine(canvas, size, chartWidth, chartHeight, maxValue);
    _drawPoints(canvas, chartWidth, chartHeight, maxValue);
    _drawLabels(canvas, size, chartWidth);
  }

  double _getMaxValue() {
    return data.map((d) => d.value).reduce(math.max).toDouble();
  }

  void _drawGrid(Canvas canvas, Size size, double chartHeight) {
    final gridPaint = Paint()
      ..color = AppColors.borderColor
      ..strokeWidth = 1;

    for (var i = 0; i <= _gridLines; i++) {
      final y = _padding + (chartHeight * i / _gridLines);
      canvas.drawLine(
        Offset(_padding, y),
        Offset(size.width - _padding, y),
        gridPaint,
      );
    }
  }

  void _drawAreaFill(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
    double maxValue,
  ) {
    final path = _createChartPath(chartWidth, chartHeight, maxValue, true);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.accentCyan.withValues(alpha: 0.3),
        AppColors.accentCyan.withValues(alpha: 0.05),
      ],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
    double maxValue,
  ) {
    final path = _createChartPath(chartWidth, chartHeight, maxValue, false);

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accentCyan
        ..strokeWidth = _lineWidth
        ..style = PaintingStyle.stroke,
    );
  }

  Path _createChartPath(
    double chartWidth,
    double chartHeight,
    double maxValue,
    bool closePath,
  ) {
    final path = Path();
    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : 0.0;

    if (closePath) {
      final firstX = _xAt(0, chartWidth, stepX);
      path.moveTo(firstX, _padding + chartHeight);
    }

    for (var i = 0; i < data.length; i++) {
      final x = _xAt(i, chartWidth, stepX);
      final y = _yAt(i, chartHeight, maxValue);

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        final prevX = _xAt(i - 1, chartWidth, stepX);
        final prevY = _yAt(i - 1, chartHeight, maxValue);
        final controlX = (prevX + x) / 2;

        path.cubicTo(controlX, prevY, controlX, y, x, y);
      }
    }

    if (closePath) {
      final lastX = _xAt(data.length - 1, chartWidth, stepX);
      path.lineTo(lastX, _padding + chartHeight);
      path.close();
    }

    return path;
  }

  void _drawPoints(
    Canvas canvas,
    double chartWidth,
    double chartHeight,
    double maxValue,
  ) {
    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : 0.0;

    for (var i = 0; i < data.length; i++) {
      final x = _xAt(i, chartWidth, stepX);
      final y = _yAt(i, chartHeight, maxValue);
      final isHovered = hoveredIndex == i;

      _drawPoint(canvas, Offset(x, y), isHovered);
    }
  }

  void _drawPoint(Canvas canvas, Offset position, bool isHovered) {
    if (isHovered) {
      canvas.drawCircle(
        position,
        _glowRadius,
        Paint()
          ..color = AppColors.accentCyan.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    canvas.drawCircle(
      position,
      isHovered ? _hoveredPointRadius : _pointRadius,
      Paint()..color = AppColors.accentCyan,
    );

    canvas.drawCircle(
      position,
      isHovered ? _hoveredPointInnerRadius : _pointInnerRadius,
      Paint()..color = AppColors.bgPrimary,
    );
  }

  void _drawLabels(Canvas canvas, Size size, double chartWidth) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : 0.0;

    for (var i = 0; i < data.length; i++) {
      final x = _xAt(i, chartWidth, stepX);

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
        Offset(x - textPainter.width / 2, size.height - _padding + 10),
      );
    }
  }

  double _xAt(int index, double chartWidth, double stepX) {
    if (data.length <= 1) {
      return _padding + chartWidth / 2;
    }
    return _padding + index * stepX;
  }

  double _yAt(int index, double chartHeight, double maxValue) {
    return _padding +
        chartHeight -
        (data[index].value / maxValue * chartHeight * progress);
  }

  @override
  bool shouldRepaint(TrendChartPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        hoveredIndex != oldDelegate.hoveredIndex;
  }
}
