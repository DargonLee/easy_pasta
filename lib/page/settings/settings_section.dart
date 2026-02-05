import 'package:flutter/material.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<SettingItem> items;
  final Widget Function(SettingItem item) itemBuilder;

  const SettingsSection({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: (isDark
                    ? AppTypography.darkCaption
                    : AppTypography.lightCaption)
                .copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontWeight: AppFontWeights.semiBold,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // 设置项卡片
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppGradients.darkCardSheen
                : AppGradients.lightCardSheen,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isDark
                  ? AppColors.darkFrostedBorder
                  : AppColors.lightFrostedBorder,
            ),
            boxShadow: isDark ? AppShadows.darkSm : AppShadows.sm,
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Column(
                  children: [
                    itemBuilder(items[i]),
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        indent: AppSpacing.xxxl + AppSpacing.lg,
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
