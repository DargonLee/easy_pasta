import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/widget/settings/base_setting_tile.dart';

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
