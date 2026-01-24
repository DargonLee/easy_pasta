import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/core/animation_helper.dart';

/// 搜索空状态组件
/// 当搜索或筛选没有结果时显示
class SearchEmptyState extends StatefulWidget {
  final String? searchQuery;
  final VoidCallback? onClear;

  const SearchEmptyState({
    super.key,
    this.searchQuery,
    this.onClear,
  });

  @override
  State<SearchEmptyState> createState() => _SearchEmptyStateState();
}

class _SearchEmptyStateState extends State<SearchEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _rotateAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimationHelper.fadeIn(
      duration: AppDurations.normal,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 主标题
                Text(
                  '未找到相关内容',
                  style: (isDark
                          ? AppTypography.darkTitle3
                          : AppTypography.lightTitle3)
                      .copyWith(
                    fontWeight: AppFontWeights.semiBold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.md),

                // 搜索关键词
                if (widget.searchQuery != null &&
                    widget.searchQuery!.isNotEmpty)
                  _buildSearchQuery(isDark),

                const SizedBox(height: AppSpacing.lg),

                // 建议
                _buildSuggestions(isDark),

                // 清除按钮
                if (widget.onClear != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _buildClearButton(isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建搜索关键词显示
  Widget _buildSearchQuery(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: (isDark
                ? AppColors.darkSecondaryBackground
                : AppColors.lightSecondaryBackground)
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              '"${widget.searchQuery}"',
              style: (isDark ? AppTypography.darkBody : AppTypography.lightBody)
                  .copyWith(
                fontWeight: AppFontWeights.medium,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建建议列表
  Widget _buildSuggestions(bool isDark) {
    final suggestions = [
      _Suggestion(
        icon: Icons.edit_note_rounded,
        text: '尝试使用不同的关键词',
      ),
      _Suggestion(
        icon: Icons.short_text_rounded,
        text: '使用更短或更通用的词语',
      ),
      _Suggestion(
        icon: Icons.filter_alt_off_rounded,
        text: '清除筛选条件重新搜索',
      ),
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: (isDark
                ? AppColors.darkSecondaryBackground
                : AppColors.lightSecondaryBackground)
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '搜索建议',
                style: (isDark
                        ? AppTypography.darkFootnote
                        : AppTypography.lightFootnote)
                    .copyWith(
                  fontWeight: AppFontWeights.semiBold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...suggestions.map((suggestion) => _buildSuggestionItem(
                suggestion,
                isDark,
              )),
        ],
      ),
    );
  }

  /// 构建单个建议项
  Widget _buildSuggestionItem(_Suggestion suggestion, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(
              suggestion.icon,
              size: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              suggestion.text,
              style: (isDark
                      ? AppTypography.darkFootnote
                      : AppTypography.lightFootnote)
                  .copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建清除按钮
  Widget _buildClearButton(bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onClear,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.clear_all_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '清除搜索',
                style:
                    (isDark ? AppTypography.darkBody : AppTypography.lightBody)
                        .copyWith(
                  color: Colors.white,
                  fontWeight: AppFontWeights.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Suggestion {
  final IconData icon;
  final String text;

  _Suggestion({
    required this.icon,
    required this.text,
  });
}
