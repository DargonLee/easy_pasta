import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

/// 负责管理与原生平台的通信
class ChannelManager {
  // 单例模式
  static final ChannelManager _instance = ChannelManager._internal();
  factory ChannelManager() => _instance;
  ChannelManager._internal();

  // 通道名称常量
  static const String _eventChannelName = 'com.easy.pasteboard.event';
  static const String _methodChannelName = 'com.easy.pasteboard.method';

  // 通道实例
  final EventChannel _eventChannel = const EventChannel(_eventChannelName);
  final MethodChannel _methodChannel = const MethodChannel(_methodChannelName);

  // 回调函数
  late final ValueChanged<NSPboardTypeModel> onPasteboardChanged;

  /// 初始化通道监听
  void initChannel() {
    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        final List<Map> pasteboardItems = List<Map>.from(event);
        final model = NSPboardTypeModel.fromItemArray(pasteboardItems);
        onPasteboardChanged(model);
      },
      onError: (error) {
        developer.log('事件通道错误: ${error.message}');
      },
      cancelOnError: true,
    );
  }

  /// 设置剪贴板内容
  Future<void> setPasteboardItem(NSPboardTypeModel model) async {
    try {
      await _methodChannel.invokeMethod(
        'setPasteboardItem',
        model.toMap(),
      );
    } on PlatformException catch (e) {
      developer.log('设置剪贴板失败: ${e.message}');
    }
  }

  /// 显示主窗口
  Future<void> showMainPasteboardWindow() async {
    try {
      await _methodChannel.invokeMethod('showMainPasteboardWindow');
    } on PlatformException catch (e) {
      developer.log('显示主窗口失败: ${e.message}');
    }
  }

  /// 设置开机启动状态
  Future<void> setLaunchCtl(bool status) async {
    try {
      await _methodChannel.invokeMethod('setLaunchCtl', status);
    } on PlatformException catch (e) {
      developer.log('设置开机启动失败: ${e.message}');
    }
  }
}
