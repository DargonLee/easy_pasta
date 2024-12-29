import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeyService {
  Future<void> init() async {
    await hotKeyManager.unregisterAll();
  }
}
