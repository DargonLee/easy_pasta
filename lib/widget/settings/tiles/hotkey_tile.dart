import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/model/settings_constants.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/core/record_hotkey_dialog.dart';
import 'package:easy_pasta/widget/settings/base_setting_tile.dart';

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
              SettingIconContainer(item: item),
              const SizedBox(width: AppSpacing.md),
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
