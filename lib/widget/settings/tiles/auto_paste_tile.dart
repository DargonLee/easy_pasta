import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/widget/settings/base_setting_tile.dart';

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
      customSubtitle: Row(
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
        activeTrackColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
