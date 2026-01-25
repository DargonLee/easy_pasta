import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/core/record_hotkey_dialog.dart';
import 'package:easy_pasta/widget/setting_counter.dart';
import 'package:easy_pasta/model/settings_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';

class HotkeyTile extends StatelessWidget {
  final SettingItem item;
  final HotKey? hotKey;
  final ValueChanged<HotKey> onHotKeyChanged;

  const HotkeyTile({
    super.key,
    required this.item,
    required this.hotKey,
    required this.onHotKeyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final captionStyle =
        isDark ? AppTypography.darkCaption : AppTypography.lightCaption;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showHotKeyDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // 图标
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (item.iconColor ?? AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  item.icon,
                  color: item.iconColor ?? AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // 文字内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: (isDark
                              ? AppTypography.darkBody
                              : AppTypography.lightBody)
                          .copyWith(
                        color: item.textColor,
                        fontWeight: AppFontWeights.regular,
                      ),
                    ),
                    if (hotKey != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      HotKeyVirtualView(hotKey: hotKey!),
                    ] else ...[
                      const SizedBox(height: AppSpacing.xs / 2),
                      Text(
                        item.subtitle,
                        style: isDark
                            ? AppTypography.darkFootnote
                            : AppTypography.lightFootnote,
                      ),
                    ],
                  ],
                ),
              ),

              // 按钮
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  hotKey != null
                      ? SettingsConstants.modifyText
                      : SettingsConstants.setUpText,
                  style: (isDark
                          ? AppTypography.darkFootnote
                          : AppTypography.lightFootnote)
                      .copyWith(
                    color: AppColors.primary,
                    fontWeight: AppFontWeights.semiBold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showHotKeyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RecordHotKeyDialog(
          onHotKeyRecorded: onHotKeyChanged,
        );
      },
    );
  }
}

class ThemeTile extends StatelessWidget {
  final SettingItem item;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const ThemeTile({
    super.key,
    required this.item,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
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
          // 图标
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  (item.iconColor ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              item.icon,
              color: item.iconColor ?? AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // 文字内容
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

          // 分段控制器
          CupertinoSegmentedControl<int>(
            padding: const EdgeInsets.all(2),
            children: {
              0: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  '自动',
                  style: captionStyle,
                ),
              ),
              1: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  '浅色',
                  style: captionStyle,
                ),
              ),
              2: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  '深色',
                  style: captionStyle,
                ),
              ),
            },
            groupValue: currentThemeMode == ThemeMode.system
                ? 0
                : currentThemeMode == ThemeMode.light
                    ? 1
                    : 2,
            onValueChanged: (value) {
              HapticFeedback.selectionClick();
              switch (value) {
                case 0:
                  onThemeModeChanged(ThemeMode.system);
                  break;
                case 1:
                  onThemeModeChanged(ThemeMode.light);
                  break;
                case 2:
                  onThemeModeChanged(ThemeMode.dark);
                  break;
              }
            },
            unselectedColor: isDark
                ? AppColors.darkSecondaryBackground
                : AppColors.lightSecondaryBackground,
            selectedColor: AppColors.primary,
            borderColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            pressedColor: AppColors.primary.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}

class AutoLaunchTile extends StatelessWidget {
  final SettingItem item;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AutoLaunchTile({
    super.key,
    required this.item,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleSettingTile(
      item: item,
      value: value,
      onChanged: onChanged,
    );
  }
}

class ToggleSettingTile extends StatelessWidget {
  final SettingItem item;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;

  const ToggleSettingTile({
    super.key,
    required this.item,
    required this.value,
    required this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BaseSettingTile(
      item: item,
      onTap: onTap,
      trailing: CupertinoSwitch(
        value: value,
        onChanged: (val) {
          HapticFeedback.lightImpact();
          onChanged(val);
        },
        activeColor: AppColors.primary,
      ),
    );
  }
}

class AutoPasteTile extends StatelessWidget {
  final SettingItem item;
  final bool value;
  final bool isPermissionOk;
  final ValueChanged<bool> onChanged;

  const AutoPasteTile({
    super.key,
    required this.item,
    required this.value,
    required this.isPermissionOk,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BaseSettingTile(
      item: item,
      subtitle: Row(
        children: [
          Text(
            item.subtitle,
            style: isDark
                ? AppTypography.darkFootnote
                : AppTypography.lightFootnote,
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: (isPermissionOk ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: (isPermissionOk ? Colors.green : Colors.orange)
                    .withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              isPermissionOk ? '权限正常' : '权限未就绪',
              style: TextStyle(
                fontSize: 10,
                color: isPermissionOk ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: (val) {
          HapticFeedback.lightImpact();
          onChanged(val);
        },
        activeColor: AppColors.primary,
      ),
    );
  }
}

class MaxStorageTile extends StatelessWidget {
  final SettingItem item;
  final int value;
  final ValueChanged<int> onChanged;

  const MaxStorageTile({
    super.key,
    required this.item,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BaseSettingTile(
      item: item,
      trailing: ModernCounter(
        defaultValue: value,
        onChanged: onChanged,
      ),
    );
  }
}

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
          // 图标
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  (item.iconColor ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              item.icon,
              color: item.iconColor ?? AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // 文字内容
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

          // 下拉选择
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
                items: [
                  const DropdownMenuItem(value: 3, child: Text('3 天')),
                  const DropdownMenuItem(value: 7, child: Text('7 天')),
                  const DropdownMenuItem(value: 14, child: Text('14 天')),
                  const DropdownMenuItem(value: 30, child: Text('30 天')),
                ],
                onChanged: (val) {
                  if (val != null) onChanged(val);
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

class ClearDataTile extends StatelessWidget {
  final SettingItem item;
  final VoidCallback onClear;

  const ClearDataTile({
    super.key,
    required this.item,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return BaseSettingTile(
      item: item,
      onTap: () {
        HapticFeedback.mediumImpact();
        onClear();
      },
    );
  }
}

class ExitAppTile extends StatelessWidget {
  final SettingItem item;

  const ExitAppTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return BaseSettingTile(
      item: item,
      onTap: () {
        HapticFeedback.mediumImpact();
        _showConfirmDialog(
          context: context,
          title: SettingsConstants.exitConfirmTitle,
          content: SettingsConstants.exitConfirmContent,
          onConfirm: () => exit(0),
        );
      },
    );
  }
}

class AboutTile extends StatelessWidget {
  final SettingItem item;

  const AboutTile({
    super.key,
    required this.item,
  });

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(SettingsConstants.githubUrl);
    try {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _launchUrl();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // 图标
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  item.icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // 文字内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: isDark
                          ? AppTypography.darkBody
                          : AppTypography.lightBody,
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      '当前版本：${SettingsConstants.appVersion}',
                      style: isDark
                          ? AppTypography.darkFootnote
                          : AppTypography.lightFootnote,
                    ),
                  ],
                ),
              ),

              // GitHub 链接
              Icon(
                Icons.open_in_new,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 基础设置项组件
class BaseSettingTile extends StatelessWidget {
  final SettingItem item;
  final Widget? trailing;
  final Widget? subtitle; // 新增自定义副标题支持
  final VoidCallback? onTap;

  const BaseSettingTile({
    required this.item,
    this.trailing,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // 图标
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  (item.iconColor ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              item.icon,
              color: item.iconColor ?? AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // 文字内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: (isDark
                          ? AppTypography.darkBody
                          : AppTypography.lightBody)
                      .copyWith(
                    color: item.textColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                subtitle ??
                    Text(
                      item.subtitle,
                      style: isDark
                          ? AppTypography.darkFootnote
                          : AppTypography.lightFootnote,
                    ),
              ],
            ),
          ),

          // 右侧内容
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

/// 显示确认对话框
Future<void> _showConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  required VoidCallback onConfirm,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(SettingsConstants.cancelText,
              style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text(SettingsConstants.confirmText,
              style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
