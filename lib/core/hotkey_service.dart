import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:easy_pasta/db/shared_preference_helper.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class HotkeyService {
  // 单例模式
  static final HotkeyService _instance = HotkeyService._internal();
  factory HotkeyService() => _instance;
  HotkeyService._internal();

  Future<void> init() async {
    await hotKeyManager.unregisterAll();

    final hotkey = await SharedPreferenceHelper.getShortcutKey();
    if (hotkey.isEmpty) return;

    final hotKey = HotKey.fromJson(json.decode(hotkey));
    await setHotkey(hotKey);
  }

  // 注册新的热键
  Future<void> setHotkey(HotKey hotkey) async {
    await hotKeyManager.register(
      hotkey,
      keyDownHandler: (hotKey) {
        // 热键按下时的回调
        developer.log('热键 ${hotKey.toJson()} 被按下');
      },
    );
  }
}
