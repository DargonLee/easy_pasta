import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/widget/settings/base_setting_tile.dart';

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
        activeTrackColor: Theme.of(context).primaryColor,
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
