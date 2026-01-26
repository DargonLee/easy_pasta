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

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    await hotKeyManager.unregisterAll();
    final prefs = await SharedPreferenceHelper.instance;
    final hotkey = prefs.getShortcutKey();
    if (hotkey.isEmpty) {
      _isInitialized = true;
      return;
    }

    final hotKey = HotKey.fromJson(json.decode(hotkey));
    await setHotkey(hotKey);
    await setCloseWindowHotkey();
    
    _isInitialized = true;
  }

  Future<void> setCloseWindowHotkey() async {
    HotKey hotKey = _getCloseWindowHotKey();
    await hotKeyManager.register(hotKey, keyDownHandler: (hotKey) {
      WindowService().closeWindow();
    });
  }

  HotKey _getCloseWindowHotKey() {
    return HotKey(
      key: const PhysicalKeyboardKey(0x0007001a),
      modifiers:
          Platform.isWindows ? [HotKeyModifier.control] : [HotKeyModifier.meta],
      scope: HotKeyScope.inapp,
    );
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
