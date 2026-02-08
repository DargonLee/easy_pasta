import 'package:flutter/material.dart';
import 'package:easy_pasta/model/clipboard_analytics.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/service/analytics_service.dart';

// ==================== 常量定义 ====================

class HeatmapConstants {
  HeatmapConstants._();

  static const double heatmapHeight = 400.0;
  static const double dayLabelTopPadding = 30.0;
  static const double dayLabelRightPadding = 8.0;
  static const double dayLabelSpacing = 12.0;
  static const double hourLabelSpacing = 8.0;
  static const double legendSpacing = 20.0;
  static const double tooltipMarginTop = 16.0;

  static const double cellPadding = 1.5;
  static const double cellBorderRadius = 4.0;
  static const double cellHoverScale = 1.3;
  static const double cellGlowBlur = 12.0;
  static const double cellGlowSpread = 2.0;

  static const double legendItemSize = 20.0;
  static const double legendItemSpacing = 4.0;
  static const double legendTextSpacing = 12.0;

  static const double tooltipPadding = 12.0;
  static const double tooltipBorderRadius = 8.0;
  static const double tooltipGlowBlur = 24.0;
  static const double tooltipContentSpacing = 12.0;
  static const double tooltipBadgePaddingH = 8.0;
  static const double tooltipBadgePaddingV = 2.0;
  static const double tooltipBadgeBorderRadius = 4.0;

  static const int hourLabelInterval = 3;
  static const int daysInWeek = 7;
  static const int hoursInDay = 24;

  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Curve animationCurve = Curves.easeOut;

  static const List<String> dayNames = [
    '周日',
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六'
  ];

  // Intensity thresholds
  static const Map<int, int> intensityThresholds = {
    1: 10,
    2: 20,
    3: 30,
    4: 40,
  };
}

// ==================== 热力图主组件 ====================

/// 热力图组件
///
/// 显示 7x24 的复制活动热力图
class HeatmapWidget extends StatefulWidget {
  final TimePeriod period;

  const HeatmapWidget({
    super.key,
    this.period = TimePeriod.week,
  });

  @override
  State<HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends State<HeatmapWidget> {
  List<HeatmapDataPoint>? _heatmapData;
  Map<int, HeatmapDataPoint> _heatmapDataByKey = {};
  HeatmapDataPoint? _hoveredCell;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant HeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _resetState();
      _loadData();
    }
  }

  void _resetState() {
    setState(() {
      _hoveredCell = null;
      _heatmapData = null;
      _loadError = null;
      _heatmapDataByKey = {};
    });
  }

  Future<void> _loadData() async {
    try {
      final data = await ClipboardAnalyticsService.instance.getHeatmapData(
        period: widget.period,
      );

      if (!mounted) return;

      setState(() {
        _loadError = null;
        _heatmapData = data;
        _heatmapDataByKey = _buildDataMap(data);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = '加载热力图失败';
        _heatmapData = const [];
        _heatmapDataByKey = {};
      });
    }
  }

  Map<int, HeatmapDataPoint> _buildDataMap(List<HeatmapDataPoint> data) {
    return {
      for (final point in data) _cellKey(point.day, point.hour): point,
    };
  }

  int _cellKey(int day, int hour) => day * HeatmapConstants.hoursInDay + hour;

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return _buildErrorState();
    }

    if (_heatmapData == null) {
      return _buildLoadingState();
    }

    return _buildHeatmap();
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        _loadError!,
        style: const TextStyle(
          fontSize: 12,
          color: AnalyticsColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(AnalyticsColors.accentCyan),
      ),
    );
  }

  Widget _buildHeatmap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: HeatmapConstants.heatmapHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DayLabels(),
              const SizedBox(width: HeatmapConstants.dayLabelSpacing),
              Expanded(
                child: Column(
                  children: [
                    const _HourLabels(),
                    const SizedBox(height: HeatmapConstants.hourLabelSpacing),
                    Expanded(
                      child: _HeatmapGrid(
                        dataMap: _heatmapDataByKey,
                        onCellHover: _handleCellHover,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: HeatmapConstants.legendSpacing),
        const _HeatmapLegend(),
        if (_hoveredCell != null) _HeatmapTooltip(data: _hoveredCell!),
      ],
    );
  }

  void _handleCellHover(HeatmapDataPoint? data) {
    if (_hoveredCell != data) {
      setState(() => _hoveredCell = data);
    }
  }
}

// ==================== 子组件 ====================

/// 星期标签列
class _DayLabels extends StatelessWidget {
  const _DayLabels();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: HeatmapConstants.dayLabelTopPadding),
        ...HeatmapConstants.dayNames.map(
          (day) => Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: HeatmapConstants.dayLabelRightPadding,
                ),
                child: Text(
                  day,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: AnalyticsColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 小时标签行
class _HourLabels extends StatelessWidget {
  const _HourLabels();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        HeatmapConstants.hoursInDay,
        (hour) => Expanded(
          child: Center(
            child: Text(
              _shouldShowHourLabel(hour) ? '$hour' : '',
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                color: AnalyticsColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowHourLabel(int hour) {
    return hour % HeatmapConstants.hourLabelInterval == 0;
  }
}

/// 热力图网格
class _HeatmapGrid extends StatelessWidget {
  final Map<int, HeatmapDataPoint> dataMap;
  final ValueChanged<HeatmapDataPoint?> onCellHover;

  const _HeatmapGrid({
    required this.dataMap,
    required this.onCellHover,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        HeatmapConstants.daysInWeek,
        (day) => Expanded(
          child: _buildDayRow(day),
        ),
      ),
    );
  }

  Widget _buildDayRow(int day) {
    return Row(
      children: List.generate(
        HeatmapConstants.hoursInDay,
        (hour) => Expanded(
          child: _buildCell(day, hour),
        ),
      ),
    );
  }

  Widget _buildCell(int day, int hour) {
    final cellData = dataMap[_cellKey(day, hour)] ??
        HeatmapDataPoint(hour: hour, day: day, count: 0);

    return _HeatmapCell(
      data: cellData,
      onHover: (isHovered) => onCellHover(isHovered ? cellData : null),
    );
  }

  int _cellKey(int day, int hour) => day * HeatmapConstants.hoursInDay + hour;
}

/// 图例
class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '较少',
          style: TextStyle(
            fontSize: 11,
            color: AnalyticsColors.textMuted,
          ),
        ),
        const SizedBox(width: HeatmapConstants.legendTextSpacing),
        ...List.generate(5, (index) => _buildLegendItem(index + 1)),
        const SizedBox(width: HeatmapConstants.legendTextSpacing),
        const Text(
          '较多',
          style: TextStyle(
            fontSize: 11,
            color: AnalyticsColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(int intensity) {
    return Container(
      width: HeatmapConstants.legendItemSize,
      height: HeatmapConstants.legendItemSize,
      margin: const EdgeInsets.only(right: HeatmapConstants.legendItemSpacing),
      decoration: BoxDecoration(
        color: IntensityColorHelper.getColor(intensity),
        borderRadius: BorderRadius.circular(HeatmapConstants.cellBorderRadius),
      ),
    );
  }
}

/// 悬停提示框
class _HeatmapTooltip extends StatelessWidget {
  final HeatmapDataPoint data;

  const _HeatmapTooltip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: HeatmapConstants.tooltipMarginTop),
      padding: const EdgeInsets.all(HeatmapConstants.tooltipPadding),
      decoration: BoxDecoration(
        color: AnalyticsColors.bgTertiary,
        borderRadius:
            BorderRadius.circular(HeatmapConstants.tooltipBorderRadius),
        border: Border.all(color: AnalyticsColors.accentCyan),
        boxShadow: const [
          BoxShadow(
            color: AnalyticsColors.glowCyan,
            blurRadius: HeatmapConstants.tooltipGlowBlur,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTimeLabel(),
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
              color: AnalyticsColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: HeatmapConstants.tooltipContentSpacing),
          _buildCountBadge(),
        ],
      ),
    );
  }

  String _formatTimeLabel() {
    return '${HeatmapConstants.dayNames[data.day]} ${data.hour}:00';
  }

  Widget _buildCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HeatmapConstants.tooltipBadgePaddingH,
        vertical: HeatmapConstants.tooltipBadgePaddingV,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AnalyticsColors.accentCyan, AnalyticsColors.accentPurple],
        ),
        borderRadius: BorderRadius.circular(
          HeatmapConstants.tooltipBadgeBorderRadius,
        ),
      ),
      child: Text(
        '${data.count} 次',
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ==================== 单元格组件 ====================

/// 单个热力图单元格
class _HeatmapCell extends StatefulWidget {
  final HeatmapDataPoint data;
  final ValueChanged<bool> onHover;

  const _HeatmapCell({
    required this.data,
    required this.onHover,
  });

  @override
  State<_HeatmapCell> createState() => _HeatmapCellState();
}

class _HeatmapCellState extends State<_HeatmapCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final intensity = IntensityCalculator.calculate(widget.data.count);
    final color = IntensityColorHelper.getColor(intensity);

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Padding(
        padding: const EdgeInsets.all(HeatmapConstants.cellPadding),
        child: AnimatedScale(
          scale: _isHovered ? HeatmapConstants.cellHoverScale : 1.0,
          duration: HeatmapConstants.animationDuration,
          curve: HeatmapConstants.animationCurve,
          child: AnimatedContainer(
            duration: HeatmapConstants.animationDuration,
            curve: HeatmapConstants.animationCurve,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(
                HeatmapConstants.cellBorderRadius,
              ),
              boxShadow: _isHovered ? _buildGlowEffect() : const [],
            ),
          ),
        ),
      ),
    );
  }

  void _setHovered(bool hovered) {
    if (_isHovered == hovered) return;

    setState(() => _isHovered = hovered);
    widget.onHover(hovered);
  }

  List<BoxShadow> _buildGlowEffect() {
    return [
      BoxShadow(
        color: AnalyticsColors.accentCyan.withValues(alpha: 0.4),
        blurRadius: HeatmapConstants.cellGlowBlur,
        spreadRadius: HeatmapConstants.cellGlowSpread,
      ),
    ];
  }
}

// ==================== 工具类 ====================

/// 强度计算器
class IntensityCalculator {
  IntensityCalculator._();

  static int calculate(int count) {
    if (count == 0) return 0;

    for (final entry in HeatmapConstants.intensityThresholds.entries) {
      if (count < entry.value) {
        return entry.key;
      }
    }

    return 5; // Maximum intensity
  }
}

/// 强度颜色辅助类
class IntensityColorHelper {
  IntensityColorHelper._();

  static const Map<int, double> _alphaValues = {
    0: 0.0,
    1: 0.2,
    2: 0.4,
    3: 0.6,
    4: 0.8,
    5: 1.0,
  };

  static Color getColor(int intensity) {
    if (intensity == 0) {
      return AnalyticsColors.bgTertiary;
    }

    final alpha = _alphaValues[intensity] ?? 1.0;
    return AnalyticsColors.accentCyan.withValues(alpha: alpha);
  }
}
