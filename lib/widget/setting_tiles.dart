import 'package:flutter/material.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/core/settings_service.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeyTile extends StatelessWidget {
  final SettingItem item;
  final HotKey? hotKey;
  final ValueChanged<HotKey> onHotKeyChanged;

  const HotkeyTile({
    Key? key,
    required this.item,
    required this.hotKey,
    required this.onHotKeyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon, color: item.iconColor),
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      onTap: () async {
        // Handle hotkey change logic
      },
    );
  }
}

class ThemeTile extends StatelessWidget {
  final SettingItem item;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const ThemeTile({
    Key? key,
    required this.item,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon, color: item.iconColor),
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      onTap: () {
        // Handle theme change logic
      },
    );
  }
}