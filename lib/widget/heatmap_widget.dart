import 'package:flutter/material.dart';
import 'package:easy_pasta/model/clipboard_analytics.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // TODO: 从实际服务获取数据
    // final service = context.read<ClipboardAnalyticsService>();
    // final data = await service.generateHeatmapData(period: widget.period);

    // Mock data
    final data = _generateMockHeatmapData();

    setState(() {
      _heatmapData = data;
      _heatmapDataByKey = {
        for (final point in data) _cellKey(point.day, point.hour): point,
      };
    });
  }

  List<HeatmapDataPoint> _generateMockHeatmapData() {
    final data = <HeatmapDataPoint>[];
    for (var day = 0; day < 7; day++) {
      for (var hour = 0; hour < 24; hour++) {
        final isWorkHour = day >= 1 && day <= 5 && hour >= 9 && hour <= 18;
        final baseIntensity =
            isWorkHour ? (15 + (hour % 3) * 10) : (5 + (hour % 2) * 5);

        data.add(HeatmapDataPoint(
          hour: hour,
          day: day,
          count: baseIntensity,
          purposes: [ContentPurpose.code, ContentPurpose.text],
        ));
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    if (_heatmapData == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.accentCyan),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heatmap grid
        SizedBox(
          height: 400,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
              _buildDayLabels(),

              const SizedBox(width: 12),

              // Heatmap cells
              Expanded(
                child: Column(
                  children: [
                    // Hour labels
                    _buildHourLabels(),

                    const SizedBox(height: 8),

                    // Grid
                    Expanded(child: _buildHeatmapGrid()),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Legend
        _buildLegend(),

        // Tooltip
        if (_hoveredCell != null) _buildTooltip(),
      ],
    );
  }

  Widget _buildDayLabels() {
    const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 30), // Align with hour labels
        ...days.map((day) => Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildHourLabels() {
    return Row(
      children: List.generate(24, (hour) {
        // Only show labels for every 3 hours
        final shouldShow = hour % 3 == 0;

        return Expanded(
          child: Center(
            child: Text(
              shouldShow ? '$hour' : '',
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeatmapGrid() {
    return Column(
      children: List.generate(7, (day) {
        return Expanded(
          child: Row(
            children: List.generate(24, (hour) {
              final cellData = _heatmapDataByKey[_cellKey(day, hour)] ??
                  HeatmapDataPoint(
                    hour: hour,
                    day: day,
                    count: 0,
                  );

              return Expanded(
                child: _HeatmapCell(
                  data: cellData,
                  onHover: (isHovered) {
                    setState(() {
                      _hoveredCell = isHovered ? cellData : null;
                    });
                  },
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  int _cellKey(int day, int hour) => day * 24 + hour;

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '较少',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        ...List.generate(5, (index) {
          return Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: _getIntensityColor(index + 1),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
        const SizedBox(width: 12),
        const Text(
          '较多',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildTooltip() {
    const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentCyan),
        boxShadow: const [
          BoxShadow(
            color: AppColors.glowCyan,
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${days[_hoveredCell!.day]} ${_hoveredCell!.hour}:00',
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentCyan, AppColors.accentPurple],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_hoveredCell!.count} 次',
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getIntensityColor(int intensity) {
    switch (intensity) {
      case 1:
        return AppColors.accentCyan.withValues(alpha: 0.2);
      case 2:
        return AppColors.accentCyan.withValues(alpha: 0.4);
      case 3:
        return AppColors.accentCyan.withValues(alpha: 0.6);
      case 4:
        return AppColors.accentCyan.withValues(alpha: 0.8);
      case 5:
        return AppColors.accentCyan;
      default:
        return AppColors.bgTertiary;
    }
  }
}

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

class _HeatmapCellState extends State<_HeatmapCell>
    {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final intensity = _calculateIntensity(widget.data.count);

    return MouseRegion(
      onEnter: (_) {
        if (_isHovered) return;
        setState(() => _isHovered = true);
        widget.onHover(true);
      },
      onExit: (_) {
        if (!_isHovered) return;
        setState(() => _isHovered = false);
        widget.onHover(false);
      },
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: AnimatedScale(
          scale: _isHovered ? 1.3 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: _getColor(intensity),
              borderRadius: BorderRadius.circular(4),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AppColors.accentCyan.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : const [],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateIntensity(int count) {
    if (count == 0) return 0;
    if (count < 10) return 1;
    if (count < 20) return 2;
    if (count < 30) return 3;
    if (count < 40) return 4;
    return 5;
  }

  Color _getColor(int intensity) {
    switch (intensity) {
      case 0:
        return AppColors.bgTertiary;
      case 1:
        return AppColors.accentCyan.withValues(alpha: 0.2);
      case 2:
        return AppColors.accentCyan.withValues(alpha: 0.4);
      case 3:
        return AppColors.accentCyan.withValues(alpha: 0.6);
      case 4:
        return AppColors.accentCyan.withValues(alpha: 0.8);
      case 5:
        return AppColors.accentCyan;
      default:
        return AppColors.bgTertiary;
    }
  }
}

// Colors definition (if not in main file)
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
