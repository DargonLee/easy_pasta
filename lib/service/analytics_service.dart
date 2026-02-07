import 'package:easy_pasta/model/clipboard_analytics.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/db/database_helper.dart';

/// 剪贴板数据分析服务
class ClipboardAnalyticsService {
  static const int _maxAnalyticsCacheSize = 10000;
  static const int _maxAppTransferEvents = 10000;
  static const int _maxReturnedDuplicateGroups = 20;
  static const int _daysPerWeek = 7;
  static const int _hoursPerDay = 24;

  static final ClipboardAnalyticsService instance =
      ClipboardAnalyticsService._internal();
  ClipboardAnalyticsService._internal();

  final List<ClipboardAnalyticsData> _analyticsCache = [];
  final _duplicateDetector = <String, int>{}; // contentHash -> count
  final _appTransferTracker =
      <String, Map<String, int>>{}; // sourceApp -> {targetApp -> count}
  final List<_AppTransferEvent> _appTransferEvents = [];
  final Map<String, _CachedResult<List<HeatmapDataPoint>>> _heatmapDataCache =
      {};
  final Map<String, _CachedResult<List<DuplicateContentGroup>>>
      _duplicateGroupsCache = {};
  int _analyticsCacheVersion = 0;

  void _incrementAnalyticsVersion() {
    _analyticsCacheVersion++;
    _heatmapDataCache.clear();
    _duplicateGroupsCache.clear();
  }

  void _incrementDuplicateHash(String? hash) {
    if (hash == null) return;
    _duplicateDetector[hash] = (_duplicateDetector[hash] ?? 0) + 1;
  }

  void _decrementDuplicateHash(String? hash) {
    if (hash == null) return;
    final current = _duplicateDetector[hash];
    if (current == null) return;
    if (current <= 1) {
      _duplicateDetector.remove(hash);
      return;
    }
    _duplicateDetector[hash] = current - 1;
  }

  void _appendAnalyticsData(ClipboardAnalyticsData analyticsData) {
    _analyticsCache.add(analyticsData);
    _incrementDuplicateHash(analyticsData.contentHash);

    while (_analyticsCache.length > _maxAnalyticsCacheSize) {
      final evicted = _analyticsCache.removeAt(0);
      _decrementDuplicateHash(evicted.contentHash);
    }

    _incrementAnalyticsVersion();
  }

  void _incrementAppTransfer(String sourceApp, String targetApp) {
    _appTransferTracker.putIfAbsent(sourceApp, () => {});
    _appTransferTracker[sourceApp]![targetApp] =
        (_appTransferTracker[sourceApp]![targetApp] ?? 0) + 1;
  }

  void _decrementAppTransfer(String sourceApp, String targetApp) {
    final targets = _appTransferTracker[sourceApp];
    if (targets == null) return;
    final current = targets[targetApp];
    if (current == null) return;
    if (current <= 1) {
      targets.remove(targetApp);
      if (targets.isEmpty) {
        _appTransferTracker.remove(sourceApp);
      }
      return;
    }
    targets[targetApp] = current - 1;
  }

  void _appendAppTransferEvent(String sourceApp, String targetApp) {
    _appTransferEvents.add(_AppTransferEvent(
      sourceApp: sourceApp,
      targetApp: targetApp,
      timestamp: DateTime.now(),
    ));
    _incrementAppTransfer(sourceApp, targetApp);

    while (_appTransferEvents.length > _maxAppTransferEvents) {
      final evicted = _appTransferEvents.removeAt(0);
      _decrementAppTransfer(evicted.sourceApp, evicted.targetApp);
    }
  }

  DateTime _resolveHeatmapStart(TimePeriod period, DateTime? startDate) {
    if (startDate != null) return startDate;

    final now = DateTime.now();
    switch (period) {
      case TimePeriod.day:
        return DateTime(now.year, now.month, now.day);
      case TimePeriod.week:
        return now.subtract(const Duration(days: 7));
      case TimePeriod.month:
        return DateTime(now.year, now.month - 1, now.day);
    }
  }

  DateTime _resolveDuplicateStart(TimePeriod period) {
    final now = DateTime.now();
    switch (period) {
      case TimePeriod.day:
        return now.subtract(const Duration(days: 1));
      case TimePeriod.week:
        return now.subtract(const Duration(days: 7));
      case TimePeriod.month:
        return now.subtract(const Duration(days: 30));
    }
  }

  /// 记录一次剪贴板操作
  Future<void> recordClipboardEvent(
      ClipboardItemModel item, String sourceAppName) async {
    final analyticsData = ClipboardAnalyticsData.fromClipboardItem(
      item,
      sourceAppName: sourceAppName,
    );

    _appendAnalyticsData(analyticsData);

    // 持久化到数据库（可选）
    await _persistAnalyticsData(analyticsData);
  }

  /// 记录应用间流转（如果能检测到粘贴目标应用）
  void recordAppTransfer(String sourceApp, String targetApp) {
    _appendAppTransferEvent(sourceApp, targetApp);
  }

  // ==================== 1. 复制热力图分析 ====================

  /// 生成复制热力图数据
  List<HeatmapDataPoint> generateHeatmapData({
    required TimePeriod period,
    DateTime? startDate,
  }) {
    final start = _resolveHeatmapStart(period, startDate);
    final cacheKey = '${period.name}_${start.millisecondsSinceEpoch}';
    final cached = _heatmapDataCache[cacheKey];
    if (cached != null && cached.version == _analyticsCacheVersion) {
      return cached.data;
    }

    const slotCount = _daysPerWeek * _hoursPerDay;
    final counts = List<int>.filled(slotCount, 0);
    final purposeCounts = List.generate(
      slotCount,
      (_) => <ContentPurpose, int>{},
      growable: false,
    );

    for (final data in _analyticsCache) {
      if (!data.timestamp.isAfter(start)) continue;

      final day = data.timestamp.weekday % _daysPerWeek;
      final hour = data.timestamp.hour;
      final index = day * _hoursPerDay + hour;
      counts[index]++;

      final purposeCountMap = purposeCounts[index];
      purposeCountMap[data.purpose] = (purposeCountMap[data.purpose] ?? 0) + 1;
    }

    final result = <HeatmapDataPoint>[];
    for (var day = 0; day < _daysPerWeek; day++) {
      for (var hour = 0; hour < _hoursPerDay; hour++) {
        final index = day * _hoursPerDay + hour;
        final count = counts[index];
        if (count == 0) continue;

        final topPurposes = purposeCounts[index].entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        result.add(HeatmapDataPoint(
          hour: hour,
          day: day,
          count: count,
          purposes: topPurposes.take(2).map((e) => e.key).toList(),
        ));
      }
    }

    final immutableResult = List<HeatmapDataPoint>.unmodifiable(result);
    _heatmapDataCache[cacheKey] = _CachedResult(
      version: _analyticsCacheVersion,
      data: immutableResult,
    );
    return immutableResult;
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
    final cacheKey = '${period.name}_$minOccurrences';
    final cached = _duplicateGroupsCache[cacheKey];
    if (cached != null && cached.version == _analyticsCacheVersion) {
      return cached.data;
    }
    final start = _resolveDuplicateStart(period);

    final groups = <String, _DuplicateAccumulator>{};
    for (final data in _analyticsCache) {
      if (!data.timestamp.isAfter(start)) continue;
      final hash = data.contentHash;
      if (hash == null) continue;
      groups.putIfAbsent(hash, () => _DuplicateAccumulator(data)).add(data);
    }

    final duplicates = <DuplicateContentGroup>[];
    for (final entry in groups.entries) {
      final summary = entry.value;
      if (summary.count < minOccurrences) continue;
      duplicates.add(DuplicateContentGroup(
        contentHash: entry.key,
        representativeText: _getRepresentativeText(summary.firstData),
        occurrenceCount: summary.count,
        firstSeen: summary.firstSeen,
        lastSeen: summary.lastSeen,
        sourceApps: summary.sourceApps.toList(growable: false),
        purpose: summary.purpose,
      ));
    }

    duplicates.sort((a, b) => b.occurrenceCount.compareTo(a.occurrenceCount));
    final limited = List<DuplicateContentGroup>.unmodifiable(
      duplicates.take(_maxReturnedDuplicateGroups).toList(growable: false),
    );
    _duplicateGroupsCache[cacheKey] = _CachedResult(
      version: _analyticsCacheVersion,
      data: limited,
    );
    return limited;
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
    final removedAnalytics = <ClipboardAnalyticsData>[];
    _analyticsCache.removeWhere((data) {
      final shouldRemove = data.timestamp.isBefore(cutoff);
      if (shouldRemove) {
        removedAnalytics.add(data);
      }
      return shouldRemove;
    });
    if (removedAnalytics.isNotEmpty) {
      for (final data in removedAnalytics) {
        _decrementDuplicateHash(data.contentHash);
      }
      _incrementAnalyticsVersion();
    }

    final removedTransfers = <_AppTransferEvent>[];
    _appTransferEvents.removeWhere((event) {
      final shouldRemove = event.timestamp.isBefore(cutoff);
      if (shouldRemove) {
        removedTransfers.add(event);
      }
      return shouldRemove;
    });
    for (final event in removedTransfers) {
      _decrementAppTransfer(event.sourceApp, event.targetApp);
    }
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

  /// 获取重复内容列表（基于相同 value 的条目数）
  Future<List<DuplicateItem>> getDuplicateItems({
    TimePeriod period = TimePeriod.week,
    int minOccurrences = 2,
    int limit = 20,
  }) async {
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
        ${DatabaseConfig.columnValue} as value,
        COUNT(*) as count,
        MAX(${DatabaseConfig.columnTime}) as lastTime
      FROM ${DatabaseConfig.tableName}
      WHERE ${DatabaseConfig.columnTime} >= ?
        AND ${DatabaseConfig.columnValue} IS NOT NULL
        AND length(${DatabaseConfig.columnValue}) > 0
      GROUP BY ${DatabaseConfig.columnValue}
      HAVING COUNT(*) >= ?
      ORDER BY count DESC, lastTime DESC
      LIMIT ?
    ''', [start.toString(), minOccurrences, limit]);

    return results.map((row) {
      final rawValue = row['value']?.toString() ?? '';
      final count = row['count'] as int? ?? 0;
      final content = _formatDuplicateContent(rawValue);
      final purpose = _inferPurposeFromText(rawValue);
      final suggestion = _suggestionForPurpose(purpose);

      return DuplicateItem(
        content: content,
        count: count,
        suggestion: suggestion,
      );
    }).toList();
  }

  String _formatDuplicateContent(String value) {
    final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= 120) return collapsed;
    return '${collapsed.substring(0, 120)}…';
  }

  ContentPurpose _inferPurposeFromText(String value) {
    final text = value.toLowerCase();

    if (_isUrl(text)) return ContentPurpose.url;
    if (_isCommand(text)) return ContentPurpose.command;
    if (_isPersonalInfo(text)) return ContentPurpose.personal;
    if (_isCode(text)) return ContentPurpose.code;

    return ContentPurpose.text;
  }

  bool _isUrl(String value) {
    return RegExp(r'^https?://').hasMatch(value);
  }

  bool _isCommand(String value) {
    return RegExp(r'^(cd|ls|mkdir|git|docker|npm|yarn|pip|brew)\s')
        .hasMatch(value);
  }

  bool _isPersonalInfo(String value) {
    return RegExp(r'(路|街|号|单元|室|电话|手机|@)').hasMatch(value) ||
        RegExp(r'\d{11}').hasMatch(value);
  }

  bool _isCode(String value) {
    final codePatterns = [
      RegExp(r'^(const|let|var|function|class|import|export|def|class)\s'),
      RegExp(r'[{};]\s*\n.*[{};]'),
      RegExp(r'^(https?://|git@|npm|pip|brew)\s'),
    ];
    return codePatterns.any((p) => p.hasMatch(value));
  }

  String _suggestionForPurpose(ContentPurpose purpose) {
    if (purpose == ContentPurpose.personal) {
      return '这是您的个人信息，建议保存到地址簿或密码管理器';
    } else if (purpose == ContentPurpose.code) {
      return '这段代码被频繁使用，建议保存为代码片段或创建快捷键';
    } else if (purpose == ContentPurpose.url) {
      return '这个链接经常被访问，建议添加到浏览器书签';
    }
    return '这段文本被频繁复制，建议保存为快捷短语';
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

  /// 获取应用间流转关系（基于连续剪贴板来源应用变化推断）
  Future<List<AppFlowData>> getAppFlowData({
    TimePeriod period = TimePeriod.week,
    int limit = 15,
    Duration maxTransitionGap = const Duration(minutes: 30),
  }) async {
    final db = await DatabaseHelper.instance.database;
    final start = _startOfPeriod(period);
    final rows = await db.rawQuery('''
      SELECT ${DatabaseConfig.columnSourceAppId} as sourceApp, ${DatabaseConfig.columnTime} as time
      FROM ${DatabaseConfig.tableName}
      WHERE ${DatabaseConfig.columnTime} >= ?
        AND ${DatabaseConfig.columnSourceAppId} IS NOT NULL
        AND length(trim(${DatabaseConfig.columnSourceAppId})) > 0
      ORDER BY ${DatabaseConfig.columnTime} ASC
    ''', [start.toString()]);

    if (rows.length < 2) {
      return const [];
    }

    String? previousApp;
    DateTime? previousTime;
    final relationMap = <String, _AppFlowAccumulator>{};

    for (final row in rows) {
      final rawApp = row['sourceApp']?.toString().trim();
      final rawTime = row['time']?.toString();
      if (rawApp == null || rawApp.isEmpty || rawTime == null) continue;

      final currentTime = DateTime.tryParse(rawTime);
      if (currentTime == null) continue;

      final prevApp = previousApp;
      final prevTime = previousTime;
      if (prevApp != null &&
          prevTime != null &&
          rawApp != prevApp &&
          !currentTime.isBefore(prevTime)) {
        final gap = currentTime.difference(prevTime);
        if (gap <= maxTransitionGap) {
          final key = '$prevApp->$rawApp';
          relationMap
              .putIfAbsent(
                key,
                () => _AppFlowAccumulator(
                  sourceAppId: prevApp,
                  targetAppId: rawApp,
                  lastTransfer: currentTime,
                ),
              )
              .add(currentTime);
        }
      }

      previousApp = rawApp;
      previousTime = currentTime;
    }

    if (relationMap.isEmpty) {
      return const [];
    }

    final flows = relationMap.values
        .map(
          (accumulator) => AppFlowData(
            sourceApp: _formatAppName(accumulator.sourceAppId),
            targetApp: _formatAppName(accumulator.targetAppId),
            transferCount: accumulator.transferCount,
            lastTransfer: accumulator.lastTransfer,
          ),
        )
        .toList()
      ..sort((a, b) {
        final countCmp = b.transferCount.compareTo(a.transferCount);
        if (countCmp != 0) return countCmp;
        return b.lastTransfer.compareTo(a.lastTransfer);
      });

    return flows.take(limit).toList(growable: false);
  }

  DateTime _startOfPeriod(TimePeriod period) {
    final now = DateTime.now();
    switch (period) {
      case TimePeriod.day:
        return DateTime(now.year, now.month, now.day);
      case TimePeriod.week:
        return now.subtract(const Duration(days: 7));
      case TimePeriod.month:
        return DateTime(now.year, now.month - 1, now.day);
    }
  }

  String _formatAppName(String sourceAppId) {
    final raw = sourceAppId.trim();
    if (raw.isEmpty) return 'Unknown';

    const wellKnown = <String, String>{
      'com.microsoft.vscode': 'VS Code',
      'com.google.chrome': 'Chrome',
      'com.apple.safari': 'Safari',
      'com.apple.finder': 'Finder',
      'com.apple.terminal': 'Terminal',
      'com.todesktop.230313mzl4w4u92': 'Cursor',
      'com.figma.desktop': 'Figma',
      'notion.id': 'Notion',
      'com.tinyspeck.slackmacgap': 'Slack',
    };
    final normalizedRaw = raw.toLowerCase();
    final alias = wellKnown[normalizedRaw];
    if (alias != null) return alias;

    final tail = raw.contains('.') ? raw.split('.').last : raw;
    final spaced = tail
        .replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return spaced.isEmpty ? raw : spaced;
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

class _CachedResult<T> {
  final int version;
  final T data;

  const _CachedResult({
    required this.version,
    required this.data,
  });
}

class _AppTransferEvent {
  final String sourceApp;
  final String targetApp;
  final DateTime timestamp;

  const _AppTransferEvent({
    required this.sourceApp,
    required this.targetApp,
    required this.timestamp,
  });
}

class _AppFlowAccumulator {
  final String sourceAppId;
  final String targetAppId;
  int transferCount = 0;
  DateTime lastTransfer;

  _AppFlowAccumulator({
    required this.sourceAppId,
    required this.targetAppId,
    required this.lastTransfer,
  });

  void add(DateTime at) {
    transferCount++;
    if (at.isAfter(lastTransfer)) {
      lastTransfer = at;
    }
  }
}

class _DuplicateAccumulator {
  final ClipboardAnalyticsData firstData;
  final Set<String> sourceApps = <String>{};
  late DateTime firstSeen;
  late DateTime lastSeen;
  late ContentPurpose purpose;
  int count = 0;

  _DuplicateAccumulator(this.firstData) {
    purpose = firstData.purpose;
    firstSeen = firstData.timestamp;
    lastSeen = firstData.timestamp;
  }

  void add(ClipboardAnalyticsData data) {
    count++;
    sourceApps.add(data.sourceAppName);
    if (data.timestamp.isBefore(firstSeen)) {
      firstSeen = data.timestamp;
    }
    if (data.timestamp.isAfter(lastSeen)) {
      lastSeen = data.timestamp;
    }
  }
}
