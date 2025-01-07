import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';

class WindowService {
  Future<void> init() async {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(950, 680),
      minimumSize: Size(370, 680),
      center: true,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
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

  Future<void> hideWindow() async {
    await windowManager.hide();
  }

  Future<void> closeWindow() async {
    await windowManager.close();
  }
}
