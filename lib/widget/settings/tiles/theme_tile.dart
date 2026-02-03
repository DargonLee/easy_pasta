import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/widget/settings/base_setting_tile.dart';

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
          CupertinoSegmentedControl<int>(
            padding: const EdgeInsets.all(2),
            children: {
              0: _buildSegment('自动', captionStyle),
              1: _buildSegment('浅色', captionStyle),
              2: _buildSegment('深色', captionStyle),
            },
            groupValue: _getThemeIndex(),
            onValueChanged: (value) => _handleThemeChange(value),
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

  Widget _buildSegment(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Text(text, style: style),
    );
  }

  int _getThemeIndex() {
    return switch (currentThemeMode) {
      ThemeMode.system => 0,
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
    };
  }

  void _handleThemeChange(int value) {
    HapticFeedback.selectionClick();
    final mode = switch (value) {
      0 => ThemeMode.system,
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    onThemeModeChanged(mode);
  }
}
