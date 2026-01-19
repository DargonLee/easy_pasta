import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:flutter/material.dart';

class WindowService {
  static final WindowService _instance = WindowService._internal();
  factory WindowService() => _instance;
  WindowService._internal() {
    init();
  }

  static const Size _windowSize = Size(950, 680);

  Future<void> init() async {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: _windowSize,
      minimumSize: Size(370, 680),
      center: true,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {});
  }

  /// 显示窗口，并将其居中显示在鼠标当前所在的屏幕上
  Future<void> showWindow() async {
    // 获取鼠标当前位置
    final cursorPosition = await screenRetriever.getCursorScreenPoint();
    
    // 获取所有屏幕
    final displays = await screenRetriever.getAllDisplays();
    
    // 找到鼠标所在的屏幕
    Display? targetDisplay;
    for (final display in displays) {
      final bounds = display.visiblePosition != null && display.visibleSize != null
          ? Rect.fromLTWH(
              display.visiblePosition!.dx,
              display.visiblePosition!.dy,
              display.visibleSize!.width,
              display.visibleSize!.height,
            )
          : Rect.fromLTWH(
              display.size.width * displays.indexOf(display).toDouble(),
              0,
              display.size.width,
              display.size.height,
            );
      
      if (bounds.contains(cursorPosition)) {
        targetDisplay = display;
        break;
      }
    }
    
    // 如果找不到，使用主屏幕
    targetDisplay ??= await screenRetriever.getPrimaryDisplay();
    
    // 计算窗口在目标屏幕中心的位置
    final screenX = targetDisplay.visiblePosition?.dx ?? 0;
    final screenY = targetDisplay.visiblePosition?.dy ?? 0;
    final screenWidth = targetDisplay.visibleSize?.width ?? targetDisplay.size.width;
    final screenHeight = targetDisplay.visibleSize?.height ?? targetDisplay.size.height;
    
    final windowX = screenX + (screenWidth - _windowSize.width) / 2;
    final windowY = screenY + (screenHeight - _windowSize.height) / 2;
    
    // 设置窗口位置并显示
    await windowManager.setPosition(Offset(windowX, windowY));
    await windowManager.show();
    await windowManager.focus();
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
