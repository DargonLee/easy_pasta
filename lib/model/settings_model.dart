import 'package:flutter/material.dart';

enum SettingType {
  hotkey,
  theme,
  autoLaunch,
  maxStorage,
  clearData,
  exitApp,
  about,
  bonjour,
  retention,
  autoPaste,
}

class SettingItem {
  final SettingType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? textColor;

  const SettingItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.textColor,
  });
}
