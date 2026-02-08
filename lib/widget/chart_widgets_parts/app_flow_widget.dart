part of '../chart_widgets.dart';

// ==================== 应用流转图 ====================

class AppFlowWidget extends StatefulWidget {
  final TimePeriod period;
  final int limit;

  const AppFlowWidget({
    super.key,
    this.period = TimePeriod.week,
    this.limit = 15,
  });

  @override
  State<AppFlowWidget> createState() => _AppFlowWidgetState();
}

class _AppFlowWidgetState extends State<AppFlowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Future<List<FlowConnection>> _flowsFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _flowsFuture = _loadFlows();
  }

  @override
  void didUpdateWidget(covariant AppFlowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period || oldWidget.limit != widget.limit) {
      _flowsFuture = _loadFlows();
    }
  }

  Future<List<FlowConnection>> _loadFlows() async {
    final flows = await ClipboardAnalyticsService.instance.getAppFlowData(
      period: widget.period,
      limit: widget.limit,
    );

    if (flows.isEmpty) return const [];

    if (mounted) {
      _controller.forward(from: 0);
    }

    return List.generate(
      flows.length,
      (index) => FlowConnection(
        flows[index].sourceApp,
        flows[index].targetApp,
        flows[index].transferCount,
        index,
      ),
      growable: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FlowConnection>>(
      future: _flowsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ChartLoadingIndicator(
            height: ChartConstants.flowChartHeight,
          );
        }

        final flows = snapshot.data ?? const <FlowConnection>[];
        if (flows.isEmpty) {
          return const ChartEmptyState(
            message: '当前时间范围暂无应用流转数据',
            height: ChartConstants.flowChartHeight,
          );
        }

        return SizedBox(
          height: ChartConstants.flowChartHeight,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: FlowDiagramPainter(
                flows: flows,
                progress: _controller.value,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
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

  static const _nodePadding = 60.0;
  static const _nodeRadius = 12.0;
  static const _nodeInnerRadius = 10.0;
  static const _nodeGlowRadius = 16.0;
  static const _minLineThickness = 2.0;
  static const _maxLineThickness = 15.0;
  static const _thicknessScaleFactor = 150.0;
  static const _maxAlpha = 0.8;

  @override
  void paint(Canvas canvas, Size size) {
    final apps = _getUniqueApps();
    final positions = _calculatePositions(apps, size);

    _drawConnections(canvas, positions, size);
    _drawNodes(canvas, apps, positions);
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

    for (var i = 0; i < apps.length; i++) {
      final x = i % 2 == 0 ? _nodePadding : size.width - _nodePadding;
      final y = (i * size.height / apps.length) + _nodePadding;
      positions[apps[i]] = Offset(x, y);
    }

    return positions;
  }

  void _drawConnections(
    Canvas canvas,
    Map<String, Offset> positions,
    Size size,
  ) {
    for (var i = 0; i < flows.length; i++) {
      if (progress >= i / flows.length) {
        _drawConnection(canvas, flows[i], positions, size);
      }
    }
  }

  void _drawConnection(
    Canvas canvas,
    FlowConnection flow,
    Map<String, Offset> positions,
    Size size,
  ) {
    final start = positions[flow.source];
    final end = positions[flow.target];

    if (start == null || end == null) return;

    final thickness = _calculateLineThickness(flow.count);
    final path = _createConnectionPath(start, end, size);

    canvas.drawPath(
      path,
      Paint()
        ..color = AnalyticsColors.accentCyan.withValues(
          alpha: math.min(flow.count / _thicknessScaleFactor, _maxAlpha),
        )
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke,
    );
  }

  double _calculateLineThickness(int count) {
    return (count / _thicknessScaleFactor * 10)
        .clamp(_minLineThickness, _maxLineThickness);
  }

  Path _createConnectionPath(Offset start, Offset end, Size size) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final controlX = size.width / 2;
    final controlY = (start.dy + end.dy) / 2;

    path.quadraticBezierTo(controlX, controlY, end.dx, end.dy);
    return path;
  }

  void _drawNodes(
    Canvas canvas,
    List<String> apps,
    Map<String, Offset> positions,
  ) {
    for (final app in apps) {
      final position = positions[app];
      if (position != null) {
        _drawNode(canvas, app, position);
      }
    }
  }

  void _drawNode(Canvas canvas, String app, Offset position) {
    // Outer glow
    canvas.drawCircle(
      position,
      _nodeGlowRadius,
      Paint()
        ..color = AnalyticsColors.accentCyan.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Outer circle
    canvas.drawCircle(
      position,
      _nodeRadius,
      Paint()..color = AnalyticsColors.accentCyan,
    );

    // Inner circle
    canvas.drawCircle(
      position,
      _nodeInnerRadius,
      Paint()..color = AnalyticsColors.bgSecondary,
    );

    // Label
    _drawNodeLabel(canvas, app, position);
  }

  void _drawNodeLabel(Canvas canvas, String app, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: app,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 12,
          color: AnalyticsColors.textPrimary,
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
  bool shouldRepaint(FlowDiagramPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
