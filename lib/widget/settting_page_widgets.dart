import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/core/record_hotkey_dialog.dart';
import 'package:easy_pasta/widget/setting_counter.dart';
import 'package:easy_pasta/model/settings_constants.dart';

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
    return ListTile(
      leading: Icon(item.icon, color: item.iconColor),
      title: Text(item.title, style: TextStyle(color: item.textColor)),
      subtitle: hotKey != null
          ? HotKeyVirtualView(hotKey: hotKey!)
          : Text(item.subtitle),
      trailing: TextButton(
        onPressed: () => _showHotKeyDialog(context),
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        child: Text(
          hotKey != null
              ? SettingsConstants.modifyText
              : SettingsConstants.setUpText,
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
    return ListTile(
      leading: Icon(
        item.icon,
        color: item.iconColor ?? Theme.of(context).iconTheme.color,
      ),
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      trailing: CupertinoSegmentedControl<int>(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: const {
          0: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('自动'),
          ),
          1: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('浅色'),
          ),
          2: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('深色'),
          ),
        },
        groupValue: currentThemeMode == ThemeMode.system
            ? 0
            : currentThemeMode == ThemeMode.light
                ? 1
                : 2,
        onValueChanged: (value) {
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
        unselectedColor: Theme.of(context).colorScheme.surface,
        selectedColor: Theme.of(context).colorScheme.primary,
        borderColor: Theme.of(context).colorScheme.primary,
        pressedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
    return ListTile(
      leading: Icon(item.icon, color: item.iconColor),
      title: Text(item.title, style: TextStyle(color: item.textColor)),
      subtitle: Text(item.subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class MaxStorageTile extends StatelessWidget {
  final SettingItem item;

  const MaxStorageTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon, color: item.iconColor),
      title: Text(item.title, style: TextStyle(color: item.textColor)),
      subtitle: Text(item.subtitle),
      trailing: const ModernCounter(),
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
    return ListTile(
      leading: Icon(item.icon, color: item.iconColor),
      title: Text(item.title, style: TextStyle(color: item.textColor)),
      subtitle: Text(item.subtitle),
      onTap: onClear,
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
    return ListTile(
      leading: Icon(item.icon, color: item.iconColor),
      title: Text(item.title, style: TextStyle(color: item.textColor)),
      subtitle: Text(item.subtitle),
      onTap: () => _showConfirmDialog(
        context: context,
        title: SettingsConstants.exitConfirmTitle,
        content: SettingsConstants.exitConfirmContent,
        onConfirm: () => exit(0),
      ),
    );
  }
}

class AboutTile extends StatelessWidget {
  final SettingItem item;

  const AboutTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon, color: item.iconColor),
      title: Text(item.title, style: TextStyle(color: item.textColor)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('当前版本：${SettingsConstants.appVersion}'),
          const SizedBox(height: 4),
          SelectableText(
            SettingsConstants.githubUrl,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
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
