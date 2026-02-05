import 'package:flutter/material.dart';
import 'package:easy_pasta/model/clipboard_analytics.dart';

// ==================== 重复内容列表 ====================

class DuplicateListWidget extends StatefulWidget {
  const DuplicateListWidget({super.key});

  @override
  State<DuplicateListWidget> createState() => _DuplicateListWidgetState();
}

class _DuplicateListWidgetState extends State<DuplicateListWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<DuplicateItem> _duplicates = [
    DuplicateItem(
      content: 'console.log(',
      count: 47,
      suggestion: '创建代码片段',
    ),
    DuplicateItem(
      content: 'import React from "react"',
      count: 38,
      suggestion: '模板化导入',
    ),
    DuplicateItem(
      content: '139****8765',
      count: 23,
      suggestion: '保存到通讯录',
    ),
    DuplicateItem(
      content: 'https://api.example.com/',
      count: 19,
      suggestion: '环境变量管理',
    ),
    DuplicateItem(
      content: 'docker-compose up -d',
      count: 15,
      suggestion: '创建别名',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _duplicates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _DuplicateCard(
          item: _duplicates[index],
          delay: index * 100,
          animation: _controller,
        );
      },
    );
  }
}

class _DuplicateCard extends StatefulWidget {
  final DuplicateItem item;
  final int delay;
  final Animation<double> animation;

  const _DuplicateCard({
    required this.item,
    required this.delay,
    required this.animation,
  });

  @override
  State<_DuplicateCard> createState() => _DuplicateCardState();
}

class _DuplicateCardState extends State<_DuplicateCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: widget.animation,
          curve: Interval(
            widget.delay / 1000,
            (widget.delay + 300) / 1000,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: widget.animation,
            curve: Interval(
              widget.delay / 1000,
              (widget.delay + 300) / 1000,
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: MouseRegion(
          onEnter: (_) {
            setState(() => _isHovered = true);
            _hoverController.forward();
          },
          onExit: (_) {
            setState(() => _isHovered = false);
            _hoverController.reverse();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered ? AppColors.accentCyan : Colors.transparent,
                width: 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AppColors.accentCyan.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Content
                Expanded(
                  child: Text(
                    widget.item.content,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentCyan, AppColors.accentPurple],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.item.count}次',
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Suggestion
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.item.suggestion,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== 智能洞察组件 ====================

class InsightsWidget extends StatefulWidget {
  const InsightsWidget({super.key});

  @override
  State<InsightsWidget> createState() => _InsightsWidgetState();
}

class _InsightsWidgetState extends State<InsightsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<InsightData> _insights = [
    InsightData(
      icon: '🚀',
      title: '发现高频工作流',
      description: '你经常从 VS Code 复制内容到 Terminal，本周已发生 145 次。建议创建自动化脚本或使用集成终端来优化此流程。',
      type: InsightType.optimization,
      timeSaved: 72.5,
    ),
    InsightData(
      icon: '💡',
      title: '活跃开发者模式',
      description: '本周已复制 327 段代码，建议在 VS Code 中安装 Snippets 管理插件，提高代码复用效率。',
      type: InsightType.pattern,
      timeSaved: null,
    ),
    InsightData(
      icon: '⚠️',
      title: '个人信息重复使用',
      description: '检测到手机号码被使用了 23 次，建议保存到系统通讯录或使用密码管理工具的自动填充功能。',
      type: InsightType.warning,
      timeSaved: 11.5,
    ),
    InsightData(
      icon: '📊',
      title: '工作效率巅峰时段',
      description: '数据显示你在每天 14:00-17:00 最为活跃，建议将重要任务安排在这个时段。',
      type: InsightType.pattern,
      timeSaved: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _insights.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        return _InsightCard(
          insight: _insights[index],
          delay: index * 150,
          animation: _controller,
        );
      },
    );
  }
}

class _InsightCard extends StatefulWidget {
  final InsightData insight;
  final int delay;
  final Animation<double> animation;

  const _InsightCard({
    required this.insight,
    required this.delay,
    required this.animation,
  });

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _getBorderColor(widget.insight.type);

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: widget.animation,
          curve: Interval(
            widget.delay / 1200,
            (widget.delay + 400) / 1200,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: widget.animation,
            curve: Interval(
              widget.delay / 1200,
              (widget.delay + 400) / 1200,
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(_isHovered ? 8 : 0, 0, 0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: borderColor,
                  width: 4,
                ),
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: borderColor.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(-4, 0),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with icon
                Row(
                  children: [
                    Text(
                      widget.insight.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.insight.title,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Description
                Text(
                  widget.insight.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Meta info
                Row(
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: borderColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getTypeLabel(widget.insight.type),
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: borderColor,
                        ),
                      ),
                    ),
                    
                    if (widget.insight.timeSaved != null) ...[
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          const Text(
                            '💾',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '预计节省: ${widget.insight.timeSaved!.toStringAsFixed(1)}分钟/周',
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(InsightType type) {
    switch (type) {
      case InsightType.optimization:
        return AppColors.accentGreen;
      case InsightType.warning:
        return AppColors.accentOrange;
      case InsightType.pattern:
        return AppColors.accentPurple;
    }
  }

  String _getTypeLabel(InsightType type) {
    switch (type) {
      case InsightType.optimization:
        return '优化建议';
      case InsightType.warning:
        return '注意';
      case InsightType.pattern:
        return '模式发现';
    }
  }
}

// ==================== 数据模型 ====================

class DuplicateItem {
  final String content;
  final int count;
  final String suggestion;

  DuplicateItem({
    required this.content,
    required this.count,
    required this.suggestion,
  });
}

class InsightData {
  final String icon;
  final String title;
  final String description;
  final InsightType type;
  final double? timeSaved;

  InsightData({
    required this.icon,
    required this.title,
    required this.description,
    required this.type,
    this.timeSaved,
  });
}

enum InsightType {
  optimization,
  warning,
  pattern,
}

// ==================== 颜色定义 ====================

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
