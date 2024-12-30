import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';

class WindowService {
  Future<void> init() async {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(950, 650),
      minimumSize: Size(300, 220),
      center: true,
      backgroundColor: Colors.red,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
    // 确保窗口在最前面
    await windowManager.setAlwaysOnTop(true);
    await Future.delayed(const Duration(milliseconds: 100));
    await windowManager.setAlwaysOnTop(false);
  }
}
