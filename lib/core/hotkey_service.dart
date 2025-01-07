import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:easy_pasta/db/shared_preference_helper.dart';
import 'package:easy_pasta/core/window_service.dart';
import 'dart:convert';
import 'dart:io';

class HotkeyService {
  // 单例模式
  static final HotkeyService _instance = HotkeyService._internal();
  factory HotkeyService() => _instance;
  HotkeyService._internal();

  Future<void> init() async {
    await hotKeyManager.unregisterAll();
    final prefs = await SharedPreferenceHelper.instance;
    final hotkey = prefs.getShortcutKey();
    if (hotkey.isEmpty) return;

    final hotKey = HotKey.fromJson(json.decode(hotkey));
    await setHotkey(hotKey);
    await setCloseWindowHotkey();
  }

  Future<void> setCloseWindowHotkey() async {
    HotKey hotKey;
    if (Platform.isWindows) {
      hotKey = HotKey(
        key: const PhysicalKeyboardKey(0x0007001a),
        modifiers: [HotKeyModifier.control],
        scope: HotKeyScope.inapp,
      );
    } else {
      hotKey = HotKey(
        key: const PhysicalKeyboardKey(0x0007001a),
        modifiers: [HotKeyModifier.meta],
        scope: HotKeyScope.inapp,
      );
    }
    await hotKeyManager.register(hotKey, keyDownHandler: (hotKey) {
      WindowService().closeWindow();
    });
  }

  // 注册新的热键
  Future<void> setHotkey(HotKey hotkey) async {
    await hotKeyManager.register(
      hotkey,
      keyDownHandler: (hotKey) {
        WindowService().showWindow();
      },
    );
  }
}
