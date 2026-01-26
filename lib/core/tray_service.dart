import 'dart:io' show Platform;
import 'package:tray_manager/tray_manager.dart';

class TrayService {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/images/tray_icon_original.ico'
          : 'assets/images/tray_icon_original.png',
    );
    
    _isInitialized = true;
  }
}
