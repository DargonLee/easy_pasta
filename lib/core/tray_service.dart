import 'dart:io' show Platform, exit;
import 'package:tray_manager/tray_manager.dart';
import 'package:easy_pasta/core/window_service.dart';

class TrayService {
  Future<void> init() async {
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/images/tray_icon.ico'
          : 'assets/images/mac_icon.png',
    );
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Window',
          onClick: (menuItem) => WindowService().showWindow(),
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit App',
          onClick: (menuItem) => exit(0),
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }
}
