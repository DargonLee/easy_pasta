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

// ==================== 颜色定义 ====================

class AppColors {
  AppColors._();

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
