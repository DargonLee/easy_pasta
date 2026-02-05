import 'package:flutter/material.dart';
import 'package:easy_pasta/model/clipboard_analytics.dart';
import 'package:easy_pasta/service/analytics_service.dart';

// ==================== 重复内容列表 ====================

class DuplicateListWidget extends StatefulWidget {
  final TimePeriod period;

  const DuplicateListWidget({
    super.key,
    required this.period,
  });

  @override
  State<DuplicateListWidget> createState() => _DuplicateListWidgetState();
}

class _DuplicateListWidgetState extends State<DuplicateListWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Future<List<DuplicateItem>> _duplicatesFuture;

  Future<List<DuplicateItem>> _loadDuplicates() {
    return ClipboardAnalyticsService.instance.getDuplicateItems(
      period: widget.period,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _duplicatesFuture = _loadDuplicates();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DuplicateListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _controller.reset();
      _controller.forward();
      setState(() {
        _duplicatesFuture = _loadDuplicates();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DuplicateItem>>(
      future: _duplicatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '加载重复内容失败',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          );
        }

        final duplicates = snapshot.data ?? [];
        if (duplicates.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '暂无重复内容',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: duplicates.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final delay = (index * 100).clamp(0, 700).toInt();
            return _DuplicateCard(
              item: duplicates[index],
              delay: delay,
              animation: _controller,
            );
          },
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
