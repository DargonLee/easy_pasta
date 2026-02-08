part of '../chart_widgets.dart';

// ==================== 常量定义 ====================

class ChartConstants {
  static const animationDuration = Duration(milliseconds: 1500);
  static const loadingIndicatorSize = 22.0;
  static const defaultChartHeight = 250.0;
  static const flowChartHeight = 400.0;

  static const chartPalette = [
    AnalyticsColors.accentCyan,
    AnalyticsColors.accentPurple,
    AnalyticsColors.accentPink,
    AnalyticsColors.accentGreen,
    AnalyticsColors.accentOrange,
  ];

  static const contentTypeLabels = {
    'text': '文本',
    'url': '链接',
    'image': '图片',
    'file': '文件',
    'html': 'HTML',
    'rtf': 'RTF',
  };

  static const dayNames = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
}

// ==================== 通用组件 ====================

/// 通用的加载指示器
class ChartLoadingIndicator extends StatelessWidget {
  final double height;

  const ChartLoadingIndicator({
    super.key,
    this.height = ChartConstants.defaultChartHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: SizedBox(
          width: ChartConstants.loadingIndicatorSize,
          height: ChartConstants.loadingIndicatorSize,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// 通用的空状态提示
class ChartEmptyState extends StatelessWidget {
  final String message;
  final double height;

  const ChartEmptyState({
    super.key,
    required this.message,
    this.height = ChartConstants.defaultChartHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 12,
            color: AnalyticsColors.textMuted,
          ),
        ),
      ),
    );
  }
}
