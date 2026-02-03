import 'package:flutter/material.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';

/// 图标容器组件
class SettingIconContainer extends StatelessWidget {
  final SettingItem item;
  final double size;

  const SettingIconContainer({
    super.key,
    required this.item,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.iconColor ?? AppColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        item.icon,
        color: color,
        size: 20,
      ),
    );
  }
}

/// 基础设置文本组件
class SettingTextContent extends StatelessWidget {
  final SettingItem item;
  final Widget? customSubtitle;

  const SettingTextContent({
    super.key,
    required this.item,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: (isDark ? AppTypography.darkBody : AppTypography.lightBody)
              .copyWith(color: item.textColor),
        ),
        const SizedBox(height: AppSpacing.xs / 2),
        customSubtitle ??
            Text(
              item.subtitle,
              style: isDark
                  ? AppTypography.darkFootnote
                  : AppTypography.lightFootnote,
            ),
      ],
    );
  }
}

/// 基础设置项组件 - 所有设置项的基类
class BaseSettingTile extends StatelessWidget {
  final SettingItem item;
  final Widget? trailing;
  final Widget? customSubtitle;
  final VoidCallback? onTap;

  const BaseSettingTile({
    super.key,
    required this.item,
    this.trailing,
    this.customSubtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SettingIconContainer(item: item),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SettingTextContent(
              item: item,
              customSubtitle: customSubtitle,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
