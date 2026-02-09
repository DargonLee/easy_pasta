import 'package:flutter/material.dart';
import 'package:easy_pasta/model/clipboard_analytics.dart';
import 'package:easy_pasta/service/analytics_service.dart';
import 'package:easy_pasta/page/analytics/analytics_styles.dart';

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
          return const _DuplicateStateHint(
            icon: Icons.error_outline_rounded,
            message: '加载重复内容失败',
            iconColor: AnalyticsColors.accentOrange,
          );
        }

        final duplicates = snapshot.data ?? [];
        if (duplicates.isEmpty) {
          return const _DuplicateStateHint(
            icon: Icons.inbox_rounded,
            message: '暂无重复内容',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: duplicates.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
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

class _DuplicateStateHint extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color iconColor;

  const _DuplicateStateHint({
    required this.icon,
    required this.message,
    this.iconColor = AnalyticsColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
              color: AnalyticsColors.textMuted,
            ),
          ),
        ],
      ),
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

class _DuplicateCardState extends State<_DuplicateCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final start = widget.delay / 1000;
    final end = ((widget.delay + 320) / 1000).clamp(0.0, 1.0);
    final appearCurve = CurvedAnimation(
      parent: widget.animation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: appearCurve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(appearCurve),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AnalyticsColors.bgTertiary,
                  AnalyticsColors.bgTertiary.withValues(alpha: 0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? AnalyticsColors.accentCyan.withValues(alpha: 0.8)
                    : AnalyticsColors.borderColor,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: AnalyticsColors.accentCyan.withValues(alpha: 0.16),
                    blurRadius: 24,
                    spreadRadius: -6,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    offset: const Offset(0, 6),
                    blurRadius: 18,
                    spreadRadius: -8,
                  ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 580;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AnalyticsColors.accentPurple.withValues(
                              alpha: 0.16,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.content_paste_search_rounded,
                            size: 18,
                            color: AnalyticsColors.accentPurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '重复内容',
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 11,
                                  letterSpacing: 0.3,
                                  color: AnalyticsColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.item.content,
                                style: const TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 14,
                                  height: 1.35,
                                  color: AnalyticsColors.textPrimary,
                                ),
                                maxLines: compact ? 3 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 10),
                          _DuplicateCountBadge(count: widget.item.count),
                        ],
                      ],
                    ),
                    if (compact) ...[
                      const SizedBox(height: 10),
                      _DuplicateCountBadge(count: widget.item.count),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AnalyticsColors.accentGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AnalyticsColors.accentGreen.withValues(
                            alpha: 0.22,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: AnalyticsColors.accentGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.item.suggestion,
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 11,
                                height: 1.4,
                                color: AnalyticsColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DuplicateCountBadge extends StatelessWidget {
  final int count;

  const _DuplicateCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AnalyticsColors.accentCyan, AnalyticsColors.accentPurple],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '重复 $count 次',
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
