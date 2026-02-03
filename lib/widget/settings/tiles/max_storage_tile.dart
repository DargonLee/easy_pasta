import 'package:flutter/material.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/widget/settings/base_setting_tile.dart';
import 'package:easy_pasta/widget/setting_counter.dart';

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
