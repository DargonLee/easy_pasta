import 'package:flutter/material.dart';
import 'package:easy_pasta/db/shared_preference_helper.dart';

/// 主题管理器
/// 负责管理应用的主题模式，并持久化保存用户的主题偏好
class ThemeProvider extends ChangeNotifier {
  // 私有成员
  late final SharedPreferenceHelper _prefs;
  late ThemeMode _themeMode = ThemeMode.system;

  // 构造函数
  ThemeProvider() {
    _initPrefs();
  }

  /// 初始化偏好设置
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferenceHelper.instance;
    _initTheme();
    notifyListeners();
  }

  /// 初始化主题
  void _initTheme() {
    final savedThemeMode = _prefs.getThemeMode();
    _themeMode = ThemeMode.values[savedThemeMode];
  }

  /// 获取当前主题模式
  ThemeMode get themeMode => _themeMode;

  /// 判断是否为暗黑模式
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// 判断是否跟随系统
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    try {
      await _prefs.setThemeMode(mode.index);
      _themeMode = mode;
      notifyListeners();
    } catch (e) {
      // 可以在这里添加错误处理逻辑
    }
  }

  /// 切换明暗主题
  Future<void> toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// 切换是否跟随系统
  Future<void> toggleSystemMode() async {
    final newMode = _themeMode == ThemeMode.system
        ? (isDarkMode ? ThemeMode.dark : ThemeMode.light)
        : ThemeMode.system;
    await setThemeMode(newMode);
  }

  /// 获取主题相关文本
  String getThemeModeText() {
    switch (_themeMode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  /// 获取主题图标
  IconData getThemeModeIcon() {
    switch (_themeMode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.brightness_7;
      case ThemeMode.dark:
        return Icons.brightness_4;
    }
  }

  /// 获取当前主题的颜色方案
  ColorScheme getColorScheme(BuildContext context) {
    final brightness = _themeMode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : _themeMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light;

    return brightness == Brightness.dark
        ? const ColorScheme.dark(
            primary: Colors.blue,
            secondary: Colors.blueAccent,
            surface: Color(0xFF1E1E1E),
          )
        : const ColorScheme.light(
            primary: Colors.blue,
            secondary: Colors.blueAccent,
            surface: Colors.white,
          );
  }

  /// 释放资源
  @override
  void dispose() {
    super.dispose();
  }
}
