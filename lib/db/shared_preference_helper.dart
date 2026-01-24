import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// 持久化存储帮助类
/// 负责管理应用程序的配置项存储
class SharedPreferenceHelper {
  // 私有构造函数
  SharedPreferenceHelper._();

  // 静态实例
  static SharedPreferenceHelper? _instance;

  // SharedPreferences 实例
  static SharedPreferences? _preferences;

  // 初始化锁
  static bool _isInitializing = false;
  static Future<SharedPreferenceHelper>? _initFuture;

  /// 存储键名常量
  static const String _keyPrefix = 'Pboard_';
  static const String shortcutKey = '${_keyPrefix}ShortcutKey';
  static const String loginInLaunchKey = '${_keyPrefix}LoginInLaunchKey';
  static const String maxItemStoreKey = '${_keyPrefix}MaxItemStoreKey';
  static const String themeModeKey = '${_keyPrefix}ThemeModeKey';
  static const String bonjourEnabledKey = '${_keyPrefix}BonjourEnabledKey';

  /// 默认值常量
  static const int defaultMaxItems = 50;
  static const bool defaultLoginInLaunch = false;
  static const bool defaultBonjourEnabled = false;

  /// 平台特定的默认快捷键
  static String get defaultShortcut {
    if (Platform.isMacOS) {
      return '{"identifier":"ae9b502e-d9c2-4c8c-acf6-100270b8234a","key":{"usageCode":458758},"modifiers":["meta","shift"],"scope":"system"}'; // macOS 默认快捷键
    } else if (Platform.isWindows) {
      return '{"identifier":"ae9b502e-d9c2-4c8c-acf6-100270b8234a","key":{"usageCode":458758},"modifiers":["control","shift"],"scope":"system"}'; // Windows 默认快捷键
    } else if (Platform.isLinux) {
      return '{"identifier":"ae9b502e-d9c2-4c8c-acf6-100270b8234a","key":{"usageCode":458758},"modifiers":["control","shift"],"scope":"system"}'; // Linux 默认快捷键
    } else {
      return ''; // 其他平台默认为空
    }
  }

  /// 获取单例实例
  static Future<SharedPreferenceHelper> get instance async {
    // 如果已初始化，直接返回
    if (_instance != null && _preferences != null) {
      return _instance!;
    }

    // 如果正在初始化，等待完成
    if (_isInitializing && _initFuture != null) {
      return _initFuture!;
    }

    // 开始初始化
    _isInitializing = true;
    _initFuture = _initialize();

    try {
      final result = await _initFuture!;
      return result;
    } finally {
      _isInitializing = false;
      _initFuture = null;
    }
  }

  /// 初始化方法
  static Future<SharedPreferenceHelper> _initialize() async {
    _instance ??= SharedPreferenceHelper._();
    _preferences ??= await SharedPreferences.getInstance();

    // 设置默认值
    if (_preferences?.getString(shortcutKey) == null) {
      await _instance!.setShortcutKey(defaultShortcut);
    }
    if (_preferences?.getInt(maxItemStoreKey) == null) {
      await _instance!.setMaxItemStore(defaultMaxItems);
    }

    return _instance!;
  }

  /// 快捷键相关操作
  Future<void> setShortcutKey(String value) async {
    await _preferences?.setString(shortcutKey, value);
  }

  String getShortcutKey() {
    return _preferences?.getString(shortcutKey) ?? '';
  }

  /// 最大存储数量相关操作
  Future<void> setMaxItemStore(int count) async {
    if (count < 0) return;
    await _preferences?.setInt(maxItemStoreKey, count);
  }

  int getMaxItemStore() {
    return _preferences?.getInt(maxItemStoreKey) ?? defaultMaxItems;
  }

  /// 开机启动相关操作
  Future<void> setLoginInLaunch(bool status) async {
    await _preferences?.setBool(loginInLaunchKey, status);
  }

  bool getLoginInLaunch() {
    return _preferences?.getBool(loginInLaunchKey) ?? defaultLoginInLaunch;
  }

  /// 主题模式相关操作
  Future<void> setThemeMode(int mode) async {
    await _preferences?.setInt(themeModeKey, mode);
  }

  int getThemeMode() {
    return _preferences?.getInt(themeModeKey) ?? ThemeMode.system.index;
  }

  /// Bonjour 相关操作
  Future<void> setBonjourEnabled(bool status) async {
    await _preferences?.setBool(bonjourEnabledKey, status);
  }

  bool getBonjourEnabled() {
    return _preferences?.getBool(bonjourEnabledKey) ?? defaultBonjourEnabled;
  }

  /// 批量操作方法
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'shortcutKey': getShortcutKey(),
      'maxItemStore': getMaxItemStore(),
      'loginInLaunch': getLoginInLaunch(),
      'bonjourEnabled': getBonjourEnabled(),
    };
  }

  /// 重置所有设置为默认值
  Future<void> resetToDefaults() async {
    await Future.wait([
      setShortcutKey(defaultShortcut),
      setMaxItemStore(defaultMaxItems),
      setLoginInLaunch(defaultLoginInLaunch),
      setBonjourEnabled(defaultBonjourEnabled),
    ]);
  }

  /// 清除特定键的值
  Future<void> remove(String key) async {
    await _preferences?.remove(key);
  }

  /// 清除所有存储的值
  Future<void> clearAll() async {
    await _preferences?.clear();
  }

  /// 检查键是否存在
  bool hasKey(String key) {
    return _preferences?.containsKey(key) ?? false;
  }
}
