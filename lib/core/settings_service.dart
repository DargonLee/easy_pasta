import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/db/shared_preference_helper.dart';
import 'package:easy_pasta/core/hotkey_service.dart';
import 'package:easy_pasta/core/startup_service.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final _prefs = SharedPreferenceHelper.instance;
  final _startupService = StartupService();
  final _hotkeyService = HotkeyService();

  Future<void> setHotKey(HotKey hotKey) async {
    await _hotkeyService.setHotkey(hotKey);
    await _prefs
        .then((prefs) => prefs.setShortcutKey(json.encode(hotKey.toJson())));
  }

  Future<HotKey?> getHotKey() async {
    final prefs = await _prefs;
    final hotkey = prefs.getShortcutKey();
    return hotkey.isNotEmpty ? HotKey.fromJson(json.decode(hotkey)) : null;
  }

  Future<void> setAutoLaunch(bool value) async {
    await _startupService.setEnable(value);
    await _prefs.then((prefs) => prefs.setLoginInLaunch(value));
  }

  Future<bool> getAutoLaunch() async {
    final prefs = await _prefs;
    return prefs.getLoginInLaunch();
  }

  Future<void> clearAllData(BuildContext context) async {
    context.read<PboardProvider>().clearAll();
  }
}
