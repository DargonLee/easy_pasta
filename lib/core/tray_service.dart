import 'dart:io' show Platform;
import 'package:tray_manager/tray_manager.dart';

class TrayService {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await _updateTrayIcon();
    _isInitialized = true;
  }

  /// 更新托盘图标
  Future<void> _updateTrayIcon() async {
    String iconPath;
    if (Platform.isWindows) {
      // Windows 使用 .ico 格式
      iconPath = 'assets/images/tray_icon_original.ico';
    } else if (Platform.isMacOS) {
      // macOS 使用固定图标
      iconPath = 'assets/images/tray_icon_original_dart.png';
    } else {
      // Linux 或其他平台
      iconPath = 'assets/images/tray_icon_original.png';
    }

    await trayManager.setIcon(iconPath);
  }

  /// 设置自定义图标
  Future<void> setCustomIcon(String path) async {
    await trayManager.setIcon(path);
  }

  /// 销毁服务
  void dispose() {
    _isInitialized = false;
  }
}
