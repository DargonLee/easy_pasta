import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tray_manager/tray_manager.dart';

class TrayService {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  bool _isInitialized = false;
  VoidCallback? _themeChangeListener;

  Future<void> init() async {
    if (_isInitialized) return;

    // 设置初始图标
    await _updateTrayIcon();

    // 监听系统主题变化
    _setupThemeListener();

    _isInitialized = true;
  }

  /// 更新托盘图标
  Future<void> _updateTrayIcon() async {
    final isDarkMode = _isSystemDarkMode();

    String iconPath;
    if (Platform.isWindows) {
      // Windows 使用 .ico 格式
      iconPath = 'assets/images/tray_icon_original.ico';
    } else if (Platform.isMacOS) {
      // macOS 根据主题选择图标
      iconPath = isDarkMode
          ? 'assets/images/tray_icon_original_dart.png'
          : 'assets/images/tray_icon_original.png';
    } else {
      // Linux 或其他平台
      iconPath = 'assets/images/tray_icon_original.png';
    }

    await trayManager.setIcon(iconPath);
  }

  /// 检测系统是否为暗黑模式
  bool _isSystemDarkMode() {
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  /// 设置主题变化监听器
  void _setupThemeListener() {
    // 使用 WidgetsBinding 监听平台亮度变化
    _themeChangeListener = () {
      _updateTrayIcon();
    };

    // 监听平台亮度变化
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      _updateTrayIcon();
    };
  }

  /// 手动刷新图标（可在主题切换时调用）
  Future<void> refreshIcon() async {
    if (!_isInitialized) return;
    await _updateTrayIcon();
  }

  /// 设置自定义图标
  Future<void> setCustomIcon(String path) async {
    await trayManager.setIcon(path);
  }

  /// 销毁服务
  void dispose() {
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        null;
    _themeChangeListener = null;
    _isInitialized = false;
  }
}
