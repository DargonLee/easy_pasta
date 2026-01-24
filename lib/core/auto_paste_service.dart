import 'package:flutter/services.dart';

class AutoPasteService {
  static final AutoPasteService _instance = AutoPasteService._internal();
  factory AutoPasteService() => _instance;
  AutoPasteService._internal();

  static const MethodChannel _channel = MethodChannel('auto_paste');

  /// 检查是否获得了辅助功能权限
  Future<bool> checkAccessibility() async {
    try {
      final bool? isTrusted =
          await _channel.invokeMethod<bool>('checkAccessibility');
      return isTrusted ?? false;
    } on PlatformException catch (e) {
      print('Failed to check accessibility: ${e.message}');
      return false;
    }
  }

  /// 请求辅助功能权限（会弹出系统提示或引导跳转）
  Future<void> requestAccessibility() async {
    try {
      await _channel.invokeMethod('requestAccessibility');
    } on PlatformException catch (e) {
      print('Failed to request accessibility: ${e.message}');
    }
  }

  /// 执行粘贴动作
  Future<bool> paste() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('paste');
      return success ?? false;
    } on PlatformException catch (e) {
      print('Failed to perform paste: ${e.message}');
      return false;
    }
  }
}
