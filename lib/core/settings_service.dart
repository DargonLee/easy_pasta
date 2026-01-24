import 'package:flutter/material.dart';
import 'package:easy_pasta/db/database_helper.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/db/shared_preference_helper.dart';
import 'package:easy_pasta/core/hotkey_service.dart';
import 'package:easy_pasta/core/startup_service.dart';
import 'dart:convert';
import 'package:easy_pasta/core/bonsoir_service.dart';
import 'package:easy_pasta/core/sync_portal_service.dart';
import 'package:provider/provider.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final _prefs = SharedPreferenceHelper.instance;
  final _startupService = StartupService();
  final _hotkeyService = HotkeyService();
  final _db = DatabaseHelper.instance;

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

  Future<void> setBonjourEnabled(bool value) async {
    await _prefs.then((prefs) => prefs.setBonjourEnabled(value));
    if (value) {
      await BonjourManager.instance.startService(attributes: {
        'portal_url': SyncPortalService.instance.portalUrl ?? ''
      });
    } else {
      await BonjourManager.instance.stopService();
    }
  }

  Future<bool> getBonjourEnabled() async {
    final prefs = await _prefs;
    return prefs.getBonjourEnabled();
  }

  Future<void> setMaxItems(int value) async {
    await _prefs.then((prefs) => prefs.setMaxItemStore(value));
  }

  Future<int> getMaxItems() async {
    final prefs = await _prefs;
    return prefs.getMaxItemStore();
  }

  Future<void> setRetentionDays(int value) async {
    await _prefs.then((prefs) => prefs.setRetentionDays(value));
  }

  Future<int> getRetentionDays() async {
    final prefs = await _prefs;
    return prefs.getRetentionDays();
  }

  Future<void> setAutoPaste(bool value) async {
    await _prefs.then((prefs) => prefs.setAutoPasteEnabled(value));
  }

  Future<bool> getAutoPaste() async {
    final prefs = await _prefs;
    return prefs.getAutoPasteEnabled();
  }

  Future<void> clearAllData(BuildContext context) async {
    context.read<PboardProvider>().clearAll();
  }

  Future<double> getDatabaseSize() async {
    return _db.getDatabaseSize();
  }

  Future<void> optimizeDatabase() async {
    return _db.optimizeDatabase();
  }
}
