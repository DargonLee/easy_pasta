import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/widget/settings/base_setting_tile.dart';

class RetentionDaysTile extends StatelessWidget {
  final SettingItem item;
  final int currentValue;
  final ValueChanged<int> onChanged;

  const RetentionDaysTile({
    super.key,
    required this.item,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final captionStyle =
        isDark ? AppTypography.darkCaption : AppTypography.lightCaption;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SettingIconContainer(item: item),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style:
                      isDark ? AppTypography.darkBody : AppTypography.lightBody,
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  item.subtitle,
                  style: isDark
                      ? AppTypography.darkFootnote
                      : AppTypography.lightFootnote,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSecondaryBackground
                  : AppColors.lightSecondaryBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: currentValue,
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 天')),
                  DropdownMenuItem(value: 7, child: Text('7 天')),
                  DropdownMenuItem(value: 14, child: Text('14 天')),
                  DropdownMenuItem(value: 30, child: Text('30 天')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    HapticFeedback.selectionClick();
                    onChanged(val);
                  }
                },
                style: captionStyle.copyWith(color: AppColors.primary),
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                dropdownColor: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
