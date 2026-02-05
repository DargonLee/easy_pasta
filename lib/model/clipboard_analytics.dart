import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/db/database_helper.dart';

/// 分析时间段类型
enum TimePeriod { day, week, month }

/// 内容用途分类
enum ContentPurpose {
  code,      // 代码
  text,      // 普通文本
  url,       // 链接
  image,     // 图片
  command,   // 命令
  personal,  // 个人信息（地址、电话等）
  other,     // 其他
}

/// 剪贴板分析数据模型
@immutable
class ClipboardAnalyticsData {
  final String id;
  final String sourceAppId;
  final String sourceAppName;
  final DateTime timestamp;
  final ContentPurpose purpose;
  final int contentLength;
  final String? contentHash;  // 用于检测重复
  final List<String> tags;
  final int copyCount;        // 该内容的复制次数
  final Duration? dwellTime;  // 在剪贴板停留时间（直到被覆盖或粘贴）

  const ClipboardAnalyticsData({
    required this.id,
    required this.sourceAppId,
    required this.sourceAppName,
    required this.timestamp,
    required this.purpose,
    required this.contentLength,
    this.contentHash,
    this.tags = const [],
    this.copyCount = 1,
    this.dwellTime,
  });

  factory ClipboardAnalyticsData.fromClipboardItem(
    ClipboardItemModel item, {
    required String sourceAppName,
    ContentPurpose? purpose,
  }) {
    return ClipboardAnalyticsData(
      id: item.id,
      sourceAppId: item.sourceAppId ?? 'unknown',
      sourceAppName: sourceAppName,
      timestamp: DateTime.parse(item.time),
      purpose: purpose ?? _detectPurpose(item),
      contentLength: item.pvalue.length,
      contentHash: _generateContentHash(item),
      tags: _autoTag(item),
    );
  }

  static ContentPurpose _detectPurpose(ClipboardItemModel item) {
    final value = item.pvalue.toLowerCase();
    
    if (item.ptype.toString().contains('image')) return ContentPurpose.image;
    if (_isCode(value)) return ContentPurpose.code;
    if (_isUrl(value)) return ContentPurpose.url;
    if (_isCommand(value)) return ContentPurpose.command;
    if (_isPersonalInfo(value)) return ContentPurpose.personal;
    
    return ContentPurpose.text;
  }

  static bool _isCode(String value) {
    final codePatterns = [
      RegExp(r'^(const|let|var|function|class|import|export|def|class)\s'),
      RegExp(r'[{};]\s*\n.*[{};]'),  // 多行代码特征
      RegExp(r'^(https?://|git@|npm|pip|brew)\s'),
    ];
    return codePatterns.any((p) => p.hasMatch(value));
  }

  static bool _isUrl(String value) {
    return RegExp(r'^https?://').hasMatch(value);
  }

  static bool _isCommand(String value) {
    return RegExp(r'^(cd|ls|mkdir|git|docker|npm|yarn|pip|brew)\s').hasMatch(value);
  }

  static bool _isPersonalInfo(String value) {
    // 检测地址、电话、邮箱等
    return RegExp(r'(路|街|号|单元|室|电话|手机|@)').hasMatch(value) ||
           RegExp(r'\d{11}').hasMatch(value);  // 手机号
  }

  static String? _generateContentHash(ClipboardItemModel item) {
    // 简化版本的内容哈希，用于检测重复
    final normalized = item.pvalue
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.length < 10) return null;
    return normalized.substring(0, normalized.length > 50 ? 50 : normalized.length);
  }

  static List<String> _autoTag(ClipboardItemModel item) {
    final tags = <String>[];
    final value = item.pvalue.toLowerCase();
    
    // 语言标签
    if (value.contains('flutter')) tags.add('Flutter');
    if (value.contains('python')) tags.add('Python');
    if (value.contains('javascript') || value.contains('js')) tags.add('JavaScript');
    if (value.contains('docker')) tags.add('Docker');
    if (value.contains('sql')) tags.add('SQL');
    
    // 场景标签
    if (value.contains('http')) tags.add('网络');
    if (value.contains('error') || value.contains('exception')) tags.add('错误处理');
    if (RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(value)) tags.add('日期');
    
    return tags;
  }
}

/// 复制热力图数据点
class HeatmapDataPoint {
  final int hour;      // 0-23
  final int day;       // 0-6 (周一到周日)
  final int count;     // 复制次数
  final List<ContentPurpose> purposes;  // 该时段的主要用途

  const HeatmapDataPoint({
    required this.hour,
    required this.day,
    required this.count,
    this.purposes = const [],
  });
}

/// 重复内容组
class DuplicateContentGroup {
  final String contentHash;
  final String representativeText;
  final int occurrenceCount;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final List<String> sourceApps;
  final ContentPurpose purpose;

  const DuplicateContentGroup({
    required this.contentHash,
    required this.representativeText,
    required this.occurrenceCount,
    required this.firstSeen,
    required this.lastSeen,
    required this.sourceApps,
    required this.purpose,
  });

  bool get isWorthOptimizing => occurrenceCount >= 3;
  
  String get suggestion {
    if (purpose == ContentPurpose.personal) {
      return '这是您的个人信息，建议保存到地址簿或密码管理器';
    } else if (purpose == ContentPurpose.code) {
      return '这段代码被频繁使用，建议保存为代码片段或创建快捷键';
    } else if (purpose == ContentPurpose.url) {
      return '这个链接经常被访问，建议添加到浏览器书签';
    }
    return '这段文本被频繁复制，建议保存为快捷短语';
  }
}

/// 应用流转数据
class AppFlowData {
  final String sourceApp;
  final String targetApp;
  final int transferCount;
  final List<ContentPurpose> contentTypes;
  final DateTime lastTransfer;

  const AppFlowData({
    required this.sourceApp,
    required this.targetApp,
    required this.transferCount,
    this.contentTypes = const [],
    required this.lastTransfer,
  });
}

/// 效率洞察
class EfficiencyInsight {
  final String title;
  final String description;
  final InsightType type;
  final double potentialTimeSaved;  // 预计节省的分钟数

  const EfficiencyInsight({
    required this.title,
    required this.description,
    required this.type,
    this.potentialTimeSaved = 0,
  });
}

enum InsightType {
  optimization,  // 优化建议
  pattern,       // 模式发现
  achievement,   // 成就
  warning,       // 警告
}

/// 分析报告
class AnalyticsReport {
  final TimePeriod period;
  final DateTime generatedAt;
  final List<HeatmapDataPoint> heatmapData;
  final List<DuplicateContentGroup> duplicates;
  final List<AppFlowData> appFlows;
  final List<EfficiencyInsight> insights;
  final Map<String, dynamic> statistics;

  const AnalyticsReport({
    required this.period,
    required this.generatedAt,
    required this.heatmapData,
    required this.duplicates,
    required this.appFlows,
    required this.insights,
    required this.statistics,
  });
}
