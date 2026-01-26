import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';

class CommandContent extends StatelessWidget {
  final String commandText;
  final int maxLines;

  const CommandContent({
    super.key,
    required this.commandText,
    this.maxLines = 3,
  });

  String _normalizeCommand(String input) {
    final firstLine = input.split('\n').first.trim();
    return firstLine.replaceFirst(RegExp(r'^\s*[$>]\s+'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = _normalizeCommand(commandText);
    final parts = normalized.split(RegExp(r'\s+'));
    final command = parts.isNotEmpty ? parts.first : normalized;
    final args = parts.length > 1 ? normalized.substring(command.length).trim() : '';

    final containerColor = isDark
        ? AppColors.darkSecondaryBackground.withValues(alpha: 0.6)
        : AppColors.lightSecondaryBackground.withValues(alpha: 0.6);
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.4)
        : AppColors.lightBorder.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'CMD',
                  style: (isDark
                          ? AppTypography.darkCaption
                          : AppTypography.lightCaption)
                      .copyWith(
                    color: AppColors.primary,
                    fontWeight: AppFontWeights.semiBold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  command,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (isDark
                          ? AppTypography.darkMonospace
                          : AppTypography.lightMonospace)
                      .copyWith(fontWeight: AppFontWeights.semiBold),
                ),
              ),
            ],
          ),
          if (args.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              args,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: isDark
                  ? AppTypography.darkMonospace
                  : AppTypography.lightMonospace,
            ),
          ],
        ],
      ),
    );
  }
}
