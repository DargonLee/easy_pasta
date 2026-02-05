import 'package:easy_pasta/model/clipboard_analytics.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/db/database_helper.dart';

/// 剪贴板数据分析服务
class ClipboardAnalyticsService {
  static final ClipboardAnalyticsService instance =
      ClipboardAnalyticsService._internal();
  ClipboardAnalyticsService._internal();

  final List<ClipboardAnalyticsData> _analyticsCache = [];
  final _duplicateDetector = <String, int>{}; // contentHash -> count
  final _appTransferTracker =
      <String, Map<String, int>>{}; // sourceApp -> {targetApp -> count}

  /// 记录一次剪贴板操作
  Future<void> recordClipboardEvent(
      ClipboardItemModel item, String sourceAppName) async {
    final analyticsData = ClipboardAnalyticsData.fromClipboardItem(
      item,
      sourceAppName: sourceAppName,
    );

    _analyticsCache.add(analyticsData);

    // 检测重复
    if (analyticsData.contentHash != null) {
      _duplicateDetector[analyticsData.contentHash!] =
          (_duplicateDetector[analyticsData.contentHash!] ?? 0) + 1;
    }

    // 保持缓存大小合理
    if (_analyticsCache.length > 10000) {
      _analyticsCache.removeAt(0);
    }

    // 持久化到数据库（可选）
    await _persistAnalyticsData(analyticsData);
  }

  /// 记录应用间流转（如果能检测到粘贴目标应用）
  void recordAppTransfer(String sourceApp, String targetApp) {
    _appTransferTracker.putIfAbsent(sourceApp, () => {});
    _appTransferTracker[sourceApp]![targetApp] =
        (_appTransferTracker[sourceApp]![targetApp] ?? 0) + 1;
  }

  // ==================== 1. 复制热力图分析 ====================

  /// 生成复制热力图数据
  List<HeatmapDataPoint> generateHeatmapData({
    required TimePeriod period,
    DateTime? startDate,
  }) {
    final now = DateTime.now();
    DateTime start;

    switch (period) {
      case TimePeriod.day:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TimePeriod.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case TimePeriod.month:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
    }

    final filteredData =
        _analyticsCache.where((d) => d.timestamp.isAfter(start)).toList();

    // 按小时和星期几分组
    final heatmapMap = <String, List<ClipboardAnalyticsData>>{};

    for (final data in filteredData) {
      final key = '${data.timestamp.weekday % 7}_${data.timestamp.hour}';
      heatmapMap.putIfAbsent(key, () => []).add(data);
    }

    // 转换为 HeatmapDataPoint
    final result = <HeatmapDataPoint>[];
    for (var day = 0; day < 7; day++) {
      for (var hour = 0; hour < 24; hour++) {
        final key = '${day}_$hour';
        final dataList = heatmapMap[key] ?? [];

        if (dataList.isNotEmpty) {
          // 统计主要用途
          final purposeCount = <ContentPurpose, int>{};
          for (final d in dataList) {
            purposeCount[d.purpose] = (purposeCount[d.purpose] ?? 0) + 1;
          }
          final topPurposes = purposeCount.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          result.add(HeatmapDataPoint(
            hour: hour,
            day: day,
            count: dataList.length,
            purposes: topPurposes.take(2).map((e) => e.key).toList(),
          ));
        }
      }
    }

    return result;
  }

  /// 获取工作效率时段
  Map<String, dynamic> getProductivityInsights() {
    final heatmapData = generateHeatmapData(period: TimePeriod.week);

    if (heatmapData.isEmpty) {
      return {};
    }

    // 找出高峰时段
    final sortedByCount = heatmapData.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final topHours = sortedByCount.take(5).toList();

    // 计算平均活跃度
    final totalCopies = heatmapData.fold<int>(0, (sum, h) => sum + h.count);
    final avgPerHour = totalCopies / 24 / 7;

    // 找出最活跃的工作日
    final dayCount = <int, int>{};
    for (final h in heatmapData) {
      dayCount[h.day] = (dayCount[h.day] ?? 0) + h.count;
    }
    final mostActiveDay =
        dayCount.entries.reduce((a, b) => a.value > b.value ? a : b);

    final dayNames = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

    return {
      'peakHour': '${topHours.first.hour}:00-${topHours.first.hour + 1}:00',
      'peakDay': dayNames[mostActiveDay.key],
      'totalCopies': totalCopies,
      'avgPerHour': avgPerHour.toStringAsFixed(1),
      'topHours': topHours.map((h) => '${h.hour}:00 (${h.count}次)').toList(),
      'productivityScore': _calculateProductivityScore(heatmapData),
    };
  }

  double _calculateProductivityScore(List<HeatmapDataPoint> data) {
    // 基于复制频率和分布计算效率分数
    if (data.isEmpty) return 0;

    final total = data.fold<int>(0, (sum, h) => sum + h.count);
    final avg = total / data.length;

    // 考虑集中度：如果集中在某些时段，效率更高
    final highActivityHours = data.where((h) => h.count > avg * 1.5).length;

    return ((highActivityHours / 24) * 100).clamp(0, 100);
  }

  // ==================== 2. 重复工作检测 ====================

  /// 检测重复复制的内容
  List<DuplicateContentGroup> detectDuplicates({
    int minOccurrences = 3,
    TimePeriod period = TimePeriod.week,
  }) {
    final now = DateTime.now();
    DateTime start;

    switch (period) {
      case TimePeriod.day:
        start = now.subtract(const Duration(days: 1));
        break;
      case TimePeriod.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case TimePeriod.month:
        start = now.subtract(const Duration(days: 30));
        break;
    }

    final recentData = _analyticsCache
        .where((d) => d.timestamp.isAfter(start) && d.contentHash != null)
        .toList();

    // 按 contentHash 分组
    final groups = <String, List<ClipboardAnalyticsData>>{};
    for (final data in recentData) {
      groups.putIfAbsent(data.contentHash!, () => []).add(data);
    }

    // 筛选出重复的组
    final duplicates = <DuplicateContentGroup>[];
    for (final entry in groups.entries) {
      if (entry.value.length >= minOccurrences) {
        final sourceApps =
            entry.value.map((d) => d.sourceAppName).toSet().toList();

        duplicates.add(DuplicateContentGroup(
          contentHash: entry.key,
          representativeText: _getRepresentativeText(entry.value.first),
          occurrenceCount: entry.value.length,
          firstSeen: entry.value
              .map((d) => d.timestamp)
              .reduce((a, b) => a.isBefore(b) ? a : b),
          lastSeen: entry.value
              .map((d) => d.timestamp)
              .reduce((a, b) => a.isAfter(b) ? a : b),
          sourceApps: sourceApps,
          purpose: entry.value.first.purpose,
        ));
      }
    }

    // 按重复次数排序
    duplicates.sort((a, b) => b.occurrenceCount.compareTo(a.occurrenceCount));

    return duplicates.take(20).toList(); // 最多返回20个
  }

  /// 生成快捷短语建议
  List<Map<String, dynamic>> generateShortcutSuggestions() {
    final duplicates = detectDuplicates(minOccurrences: 3);
    final suggestions = <Map<String, dynamic>>[];

    for (final dup in duplicates.where((d) => d.isWorthOptimizing)) {
      suggestions.add({
        'content': dup.representativeText,
        'count': dup.occurrenceCount,
        'suggestion': dup.suggestion,
        'purpose': dup.purpose.toString().split('.').last,
        'potentialTimeSaved': _estimateTimeSaved(dup.occurrenceCount),
      });
    }

    return suggestions;
  }

  double _estimateTimeSaved(int occurrenceCount) {
    // 假设每次复制-粘贴需要5秒，使用快捷短语只需1秒
    return (occurrenceCount * 4) / 60; // 转换为分钟
  }

  String _getRepresentativeText(ClipboardAnalyticsData data) {
    // 返回内容的简化表示
    if (data.contentLength > 50) {
      return '${data.contentLength} 字符的内容';
    }
    return '短文本';
  }

  // ==================== 3. 跨应用流转分析 ====================

  /// 获取应用流转数据
  List<AppFlowData> getAppFlowAnalysis() {
    final result = <AppFlowData>[];

    for (final sourceEntry in _appTransferTracker.entries) {
      for (final targetEntry in sourceEntry.value.entries) {
        result.add(AppFlowData(
          sourceApp: sourceEntry.key,
          targetApp: targetEntry.key,
          transferCount: targetEntry.value,
          lastTransfer: DateTime.now(), // 可以记录实际时间
        ));
      }
    }

    // 按流转次数排序
    result.sort((a, b) => b.transferCount.compareTo(a.transferCount));
    return result.take(15).toList();
  }

  /// 获取应用使用情况统计
  Map<String, dynamic> getAppUsageStatistics() {
    final appCopyCount = <String, int>{};
    final appPurposeCount = <String, Map<ContentPurpose, int>>{};

    for (final data in _analyticsCache) {
      appCopyCount[data.sourceAppName] =
          (appCopyCount[data.sourceAppName] ?? 0) + 1;

      appPurposeCount.putIfAbsent(data.sourceAppName, () => {});
      appPurposeCount[data.sourceAppName]![data.purpose] =
          (appPurposeCount[data.sourceAppName]![data.purpose] ?? 0) + 1;
    }

    // 排序
    final sortedApps = appCopyCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'topApps': sortedApps
          .take(10)
          .map((e) => {
                'name': e.key,
                'copyCount': e.value,
                'topPurpose': appPurposeCount[e.key]
                    ?.entries
                    .reduce((a, b) => a.value > b.value ? a : b)
                    .key
                    .toString()
                    .split('.')
                    .last,
              })
          .toList(),
      'totalApps': appCopyCount.length,
    };
  }

  /// 发现工作流模式
  List<EfficiencyInsight> discoverWorkflowPatterns() {
    final insights = <EfficiencyInsight>[];

    // 模式1：发现频繁的 A->B->C 路径
    final flows = getAppFlowAnalysis();
    if (flows.isNotEmpty) {
      final topFlow = flows.first;
      if (topFlow.transferCount > 10) {
        insights.add(EfficiencyInsight(
          title: '发现高频工作流',
          description: '你经常从 ${topFlow.sourceApp} 复制内容到 ${topFlow.targetApp}，'
              '本月已发生 ${topFlow.transferCount} 次。建议创建自动化脚本优化此流程。',
          type: InsightType.optimization,
          potentialTimeSaved: topFlow.transferCount * 0.5,
        ));
      }
    }

    // 模式2：代码片段收集模式
    final codeCopies =
        _analyticsCache.where((d) => d.purpose == ContentPurpose.code).length;
    if (codeCopies > 50) {
      insights.add(EfficiencyInsight(
        title: '活跃开发者模式',
        description: '本周已复制 $codeCopies 段代码，建议在 VS Code 中安装 Snippets 管理插件',
        type: InsightType.pattern,
      ));
    }

    // 模式3：重复地址输入
    final duplicates = detectDuplicates(minOccurrences: 5);
    final personalInfoDups =
        duplicates.where((d) => d.purpose == ContentPurpose.personal);
    if (personalInfoDups.isNotEmpty) {
      insights.add(EfficiencyInsight(
        title: '个人信息重复使用',
        description: '检测到 "${personalInfoDups.first.representativeText}" 被使用了 '
            '${personalInfoDups.first.occurrenceCount} 次，建议保存到系统通讯录',
        type: InsightType.optimization,
        potentialTimeSaved: personalInfoDups.first.occurrenceCount * 0.3,
      ));
    }

    return insights;
  }

  // ==================== 生成完整报告 ====================

  Future<AnalyticsReport> generateReport(TimePeriod period) async {
    final now = DateTime.now();

    return AnalyticsReport(
      period: period,
      generatedAt: now,
      heatmapData: generateHeatmapData(period: period),
      duplicates: detectDuplicates(period: period),
      appFlows: getAppFlowAnalysis(),
      insights: discoverWorkflowPatterns(),
      statistics: {
        'totalCopies': _analyticsCache.length,
        'productivity': getProductivityInsights(),
        'appUsage': getAppUsageStatistics(),
        'uniqueContentCount': _duplicateDetector.length,
      },
    );
  }

  // 持久化（可选实现）
  Future<void> _persistAnalyticsData(ClipboardAnalyticsData data) async {
    // 可以存储到单独的分析数据库表
    // 目前仅使用内存缓存
  }

  /// 清理旧数据
  void cleanupOldData({int keepDays = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    _analyticsCache.removeWhere((d) => d.timestamp.isBefore(cutoff));
  }

  // ==================== 真实数据库查询 ====================

  /// 获取总复制次数
  Future<int> getTotalCopies({TimePeriod period = TimePeriod.week}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    DateTime start;

    switch (period) {
      case TimePeriod.day:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TimePeriod.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case TimePeriod.month:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
    }

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${DatabaseConfig.tableName}
      WHERE ${DatabaseConfig.columnTime} >= ?
    ''', [start.toString()]);

    return result.first['count'] as int? ?? 0;
  }

  /// 获取活跃应用数
  Future<int> getActiveApps({TimePeriod period = TimePeriod.week}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    DateTime start;

    switch (period) {
      case TimePeriod.day:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TimePeriod.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case TimePeriod.month:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
    }

    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT ${DatabaseConfig.columnSourceAppId}) as count 
      FROM ${DatabaseConfig.tableName}
      WHERE ${DatabaseConfig.columnTime} >= ? 
      AND ${DatabaseConfig.columnSourceAppId} IS NOT NULL
    ''', [start.toString()]);

    return result.first['count'] as int? ?? 0;
  }

  /// 获取重复内容数（基于相同 value 的条目数）
  Future<int> getDuplicateCount({TimePeriod period = TimePeriod.week}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    DateTime start;

    switch (period) {
      case TimePeriod.day:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TimePeriod.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case TimePeriod.month:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
    }

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM (
        SELECT ${DatabaseConfig.columnValue}
        FROM ${DatabaseConfig.tableName}
        WHERE ${DatabaseConfig.columnTime} >= ?
        GROUP BY ${DatabaseConfig.columnValue}
        HAVING COUNT(*) > 1
      )
    ''', [start.toString()]);

    return result.first['count'] as int? ?? 0;
  }

  /// 获取效率评分（基于复制频率和活跃时段计算）
  Future<double> getProductivityScore(
      {TimePeriod period = TimePeriod.week}) async {
    final total = await getTotalCopies(period: period);
    final activeApps = await getActiveApps(period: period);

    if (total == 0) return 0;

    // 基于总复制次数和活跃应用数计算评分
    // 基准：100次复制 + 5个活跃应用 = 100分
    final copyScore = (total / 100).clamp(0, 60).toDouble();
    final appScore = (activeApps / 5 * 40).clamp(0, 40).toDouble();

    return (copyScore + appScore).clamp(0, 100);
  }

  /// 获取热力图数据（从真实数据库）
  Future<List<HeatmapDataPoint>> getHeatmapData(
      {TimePeriod period = TimePeriod.week}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    DateTime start;

    switch (period) {
      case TimePeriod.day:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TimePeriod.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case TimePeriod.month:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
    }

    final results = await db.rawQuery('''
      SELECT 
        CAST(strftime('%w', ${DatabaseConfig.columnTime}) AS INTEGER) as day,
        CAST(strftime('%H', ${DatabaseConfig.columnTime}) AS INTEGER) as hour,
        COUNT(*) as count
      FROM ${DatabaseConfig.tableName}
      WHERE ${DatabaseConfig.columnTime} >= ?
      GROUP BY day, hour
      ORDER BY day, hour
    ''', [start.toString()]);

    return results
        .map((row) => HeatmapDataPoint(
              hour: row['hour'] as int,
              day: row['day'] as int,
              count: row['count'] as int,
              purposes: [], // 可以从数据库中获取，但这里简化处理
            ))
        .toList();
  }

  /// 获取内容类型分布
  Future<Map<String, int>> getContentTypeDistribution(
      {TimePeriod period = TimePeriod.week}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    DateTime start;

    switch (period) {
      case TimePeriod.day:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TimePeriod.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case TimePeriod.month:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
    }

    final results = await db.rawQuery('''
      SELECT ${DatabaseConfig.columnType}, COUNT(*) as count
      FROM ${DatabaseConfig.tableName}
      WHERE ${DatabaseConfig.columnTime} >= ?
      GROUP BY ${DatabaseConfig.columnType}
    ''', [start.toString()]);

    return {
      for (var row in results) row['type'] as String: row['count'] as int
    };
  }

  /// 获取每日复制趋势
  Future<Map<String, int>> getDailyTrend(
      {TimePeriod period = TimePeriod.week}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    DateTime start;

    switch (period) {
      case TimePeriod.day:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TimePeriod.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case TimePeriod.month:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
    }

    final results = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m-%d', ${DatabaseConfig.columnTime}) as date,
        COUNT(*) as count
      FROM ${DatabaseConfig.tableName}
      WHERE ${DatabaseConfig.columnTime} >= ?
      GROUP BY date
      ORDER BY date
    ''', [start.toString()]);

    return {
      for (var row in results) row['date'] as String: row['count'] as int
    };
  }

  /// 获取应用使用统计
  Future<Map<String, dynamic>> getAppUsageStats(
      {TimePeriod period = TimePeriod.week}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    DateTime start;

    switch (period) {
      case TimePeriod.day:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TimePeriod.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case TimePeriod.month:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
    }

    final appResults = await db.rawQuery('''
      SELECT 
        ${DatabaseConfig.columnSourceAppId},
        COUNT(*) as count
      FROM ${DatabaseConfig.tableName}
      WHERE ${DatabaseConfig.columnTime} >= ?
      AND ${DatabaseConfig.columnSourceAppId} IS NOT NULL
      GROUP BY ${DatabaseConfig.columnSourceAppId}
      ORDER BY count DESC
    ''', [start.toString()]);

    final totalApps = await db.rawQuery('''
      SELECT COUNT(DISTINCT ${DatabaseConfig.columnSourceAppId}) as count 
      FROM ${DatabaseConfig.tableName}
      WHERE ${DatabaseConfig.columnTime} >= ?
      AND ${DatabaseConfig.columnSourceAppId} IS NOT NULL
    ''', [start.toString()]);

    return {
      'topApps': appResults
          .map((row) => {
                'name': row[DatabaseConfig.columnSourceAppId],
                'copyCount': row['count'],
              })
          .toList(),
      'totalApps': totalApps.first['count'],
    };
  }
}
