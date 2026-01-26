import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/core/string_utils.dart';

/// HTML内容卡片
/// 使用纯文本显示，避免复杂的HTML渲染问题
class HtmlContent extends StatelessWidget {
  final String htmlData;
  final String? fallbackText;
  final int? maxLines;

  const HtmlContent({
    super.key,
    required this.htmlData,
    this.fallbackText,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 直接使用 pvalue (fallbackText)，它在大部情况下已经是 SuperClipboard 提取好的纯文本
    // 只有在 fallbackText 缺失时才尝试从 htmlData 提取，且使用轻量级方法
    String? displayText =
        (fallbackText?.isNotEmpty ?? false) ? fallbackText : null;

    if (displayText == null && htmlData.isNotEmpty) {
      // 如果没有预提取的文本，我们这里的提取逻辑应该尽可能轻量，或者在后台完成
      // 暂时直接显示 HTML 片段的摘要或简单处理
      displayText = StringUtils.stripHtmlTags(htmlData);
    }

    if (displayText == null || displayText.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Text(
        displayText,
        maxLines: maxLines,
        overflow: TextOverflow.fade,
        style: (isDark ? AppTypography.darkBody : AppTypography.lightBody)
            .copyWith(
          height: 1.5,
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code,
            size: 20,
            color: (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary)
                .withValues(alpha: 0.5),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'HTML 内容',
            style: (isDark
                    ? AppTypography.darkCaption
                    : AppTypography.lightCaption)
                .copyWith(
              color: (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
