import 'package:flutter/material.dart';
import 'package:easy_pasta/model/clipboard_analytics.dart';
import 'package:easy_pasta/service/analytics_service.dart';
import 'dart:math' as math;

// 科技风格颜色常量
class _TechColors {
  static const bgPrimary = Color(0xFF0a0e14);
  static const bgSecondary = Color(0xFF121820);
  static const bgTertiary = Color(0xFF1a1f2e);
  static const accentCyan = Color(0xFF00d9ff);
  static const accentPurple = Color(0xFFa855f7);
  static const accentPink = Color(0xFFec4899);
  static const accentGreen = Color(0xFF10b981);
  static const accentOrange = Color(0xFFf59e0b);
  static const textPrimary = Color(0xFFe0e7ff);
  static const textSecondary = Color(0xFF94a3b8);
  static const textMuted = Color(0xFF64748b);
  static const borderColor = Color(0x1A94a3b8);
}

/// 背景网格装饰
class _GridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _TechColors.accentCyan.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const spacing = 50.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 浮动光晕效果
class _GlowOrb extends StatefulWidget {
  final double size;
  final Color color;
  final Duration delay;
  final Alignment alignment;

  const _GlowOrb({
    required this.size,
    required this.color,
    required this.delay,
    required this.alignment,
  });

  @override
  State<_GlowOrb> createState() => _GlowOrbState();
}

class _GlowOrbState extends State<_GlowOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat();
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
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final scale = 1 + 0.1 * math.sin(value * 2 * math.pi);
        final offsetX = 30 * math.sin(value * 2 * math.pi);
        final offsetY = -30 * math.cos(value * 2 * math.pi);

        return Align(
          alignment: widget.alignment,
          child: Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.15),
                      widget.color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 复制热力图组件 - 横向24小时，纵向7天
class CopyHeatmapWidget extends StatelessWidget {
  final List<HeatmapDataPoint> data;

  const CopyHeatmapWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxCount = data.isEmpty
        ? 1
        : data.map((d) => d.count).reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 3.0;
        const labelWidth = 45.0;

        final gridWidth = constraints.maxWidth - labelWidth;
        final cellWidth = (gridWidth - 23 * gap) / 24;
        final cellHeight = (constraints.maxHeight - 6 * gap) / 7;
        final cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;

        return Column(
          children: [
            // 小时标签
            Row(
              children: [
                const SizedBox(width: labelWidth),
                ...List.generate(24, (hour) {
                  final showLabel = hour % 4 == 0;
                  return Container(
                    width: cellSize + gap,
                    alignment: Alignment.center,
                    child: showLabel
                        ? Text(
                            '$hour',
                            style: const TextStyle(
                              fontSize: 10,
                              color: _TechColors.textMuted,
                            ),
                          )
                        : null,
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            // 热力图主体
            Expanded(
              child: Row(
                children: [
                  // 星期标签
                  SizedBox(
                    width: labelWidth - 8,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children:
                          ['周日', '周一', '周二', '周三', '周四', '周五', '周六'].map((day) {
                        return SizedBox(
                          height: cellSize,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _TechColors.textMuted,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 网格
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (day) {
                        return Row(
                          children: List.generate(24, (hour) {
                            final point = data.firstWhere(
                              (d) => d.hour == hour && d.day == day,
                              orElse: () => HeatmapDataPoint(
                                  hour: hour, day: day, count: 0),
                            );
                            return Container(
                              width: cellSize,
                              height: cellSize,
                              margin:
                                  EdgeInsets.only(right: hour < 23 ? gap : 0),
                              decoration: BoxDecoration(
                                color: _getHeatColor(point.count, maxCount),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getHeatColor(int count, int maxCount) {
    if (count == 0) return _TechColors.bgTertiary;

    final intensity = (count / maxCount).clamp(0.0, 1.0);
    if (intensity < 0.2) return _TechColors.accentCyan.withValues(alpha: 0.2);
    if (intensity < 0.4) return _TechColors.accentCyan.withValues(alpha: 0.4);
    if (intensity < 0.6) return _TechColors.accentCyan.withValues(alpha: 0.6);
    if (intensity < 0.8) return _TechColors.accentCyan.withValues(alpha: 0.8);
    return _TechColors.accentCyan;
  }
}

/// 重复内容检测组件
class DuplicateDetectorWidget extends StatelessWidget {
  final List<DuplicateContentGroup> duplicates;

  const DuplicateDetectorWidget({super.key, required this.duplicates});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.repeat, size: 18, color: _TechColors.accentOrange),
            const SizedBox(width: 8),
            const Text(
              '重复内容',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _TechColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_TechColors.accentCyan, _TechColors.accentPurple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${duplicates.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...duplicates.take(5).map((dup) => _buildDuplicateItem(dup)),
      ],
    );
  }

  Widget _buildDuplicateItem(DuplicateContentGroup dup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _TechColors.bgTertiary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _TechColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dup.representativeText,
              style: const TextStyle(
                fontSize: 13,
                color: _TechColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_TechColors.accentCyan, _TechColors.accentPurple],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${dup.occurrenceCount}次',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _TechColors.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              dup.suggestion,
              style: const TextStyle(
                fontSize: 11,
                color: _TechColors.accentGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 应用流转分析组件
class AppFlowWidget extends StatelessWidget {
  final List<AppFlowData> flows;
  final Map<String, dynamic> appUsage;

  const AppFlowWidget({super.key, required this.flows, required this.appUsage});

  @override
  Widget build(BuildContext context) {
    final topApps = (appUsage['topApps'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sync_alt,
                size: 18, color: _TechColors.accentPurple),
            const SizedBox(width: 8),
            const Text(
              '应用流转',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _TechColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${appUsage['totalApps'] ?? 0} 个应用',
              style: const TextStyle(
                fontSize: 13,
                color: _TechColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // TOP 应用
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: topApps.length.clamp(0, 5),
            itemBuilder: (context, index) {
              final app = topApps[index];
              final name = app['name'] as String? ?? '未知';
              final count = app['copyCount'] as int? ?? 0;

              return Container(
                width: 85,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _TechColors.bgTertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _TechColors.borderColor),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _TechColors.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.apps,
                        color: _TechColors.accentCyan,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name.length > 4 ? '${name.substring(0, 4)}' : name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _TechColors.textPrimary,
                      ),
                      maxLines: 1,
                    ),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _TechColors.accentCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (flows.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            '跨应用流转 TOP 5',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _TechColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...flows.take(5).map((flow) => _buildFlowItem(flow)),
        ],
      ],
    );
  }

  Widget _buildFlowItem(AppFlowData flow) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _TechColors.bgTertiary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _TechColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              flow.sourceApp,
              style: const TextStyle(
                fontSize: 13,
                color: _TechColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_forward,
              size: 14, color: _TechColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              flow.targetApp,
              style: const TextStyle(
                fontSize: 13,
                color: _TechColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_TechColors.accentCyan, _TechColors.accentPurple],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${flow.transferCount}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 效率洞察卡片
class EfficiencyInsightCard extends StatelessWidget {
  final EfficiencyInsight insight;

  const EfficiencyInsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _getBorderColor(insight.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _TechColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: const BorderSide(color: _TechColors.borderColor),
          right: const BorderSide(color: _TechColors.borderColor),
          bottom: const BorderSide(color: _TechColors.borderColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIcon(insight.type), color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insight.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _TechColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              insight.description,
              style: const TextStyle(
                fontSize: 13,
                color: _TechColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (insight.potentialTimeSaved > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getTypeLabel(insight.type),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.schedule, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    '预计节省 ${insight.potentialTimeSaved.toStringAsFixed(0)} 分钟',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBorderColor(InsightType type) {
    return switch (type) {
      InsightType.optimization => _TechColors.accentGreen,
      InsightType.pattern => _TechColors.accentPurple,
      InsightType.achievement => _TechColors.accentOrange,
      InsightType.warning => _TechColors.accentPink,
    };
  }

  IconData _getIcon(InsightType type) {
    return switch (type) {
      InsightType.optimization => Icons.rocket_launch,
      InsightType.pattern => Icons.psychology,
      InsightType.achievement => Icons.emoji_events,
      InsightType.warning => Icons.warning_amber,
    };
  }

  String _getTypeLabel(InsightType type) {
    return switch (type) {
      InsightType.optimization => '优化建议',
      InsightType.pattern => '模式发现',
      InsightType.achievement => '成就',
      InsightType.warning => '注意',
    };
  }
}

/// 统计卡片
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String? change;
  final bool isPositive;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.change,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _TechColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _TechColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部渐变线
          Container(
            width: double.infinity,
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0), color],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _TechColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: isPositive
                      ? _TechColors.accentGreen
                      : _TechColors.accentPink,
                ),
                const SizedBox(width: 4),
                Text(
                  change!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPositive
                        ? _TechColors.accentGreen
                        : _TechColors.accentPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
