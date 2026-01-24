import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/core/content_processor.dart';

/// HTML内容卡片
/// 使用纯文本显示，避免复杂的HTML渲染问题
class HtmlContent extends StatelessWidget {
  final String htmlData;
  final int? maxLines;

  const HtmlContent({
    super.key,
    required this.htmlData,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 从FIML中提取纯文本
    final plainText = ContentProcessor.extractTextFromHtml(htmlData);

    // 如果提取失败或为空，显示提示
    if (plainText.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Text(
        plainText,
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
