part of '../chart_widgets.dart';

// ==================== 数据模型 ====================

class ChartData {
  final String label;
  final int value;
  final Color color;

  const ChartData(this.label, this.value, this.color);
}

class TrendData {
  final String label;
  final int value;

  const TrendData(this.label, this.value);
}

class FlowConnection {
  final String source;
  final String target;
  final int count;
  final int index;

  const FlowConnection(this.source, this.target, this.count, this.index);
}
