import 'dart:async';
import 'package:flutter/material.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

class SuperClipboard {
  static final SuperClipboard _instance = SuperClipboard._internal();
  static SuperClipboard get instance => _instance;
  final clipboard = SystemClipboard.instance;

  // 剪贴板监听器回调
  ValueChanged<NSPboardTypeModel?>? _onClipboardChangedCallback;

  // 上一次剪贴板内容
  String? _lastClipboardContent;

  // 定时器
  Timer? _timer;

  // 私有构造函数，防止外部创建实例
  SuperClipboard._internal() {
    _startTimer();
    _initializeEventListeners();
  }

  // 初始化事件监听器
  void _initializeEventListeners() {}

  // 启动定时器，定期检查剪贴板
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _checkClipboard();
    });
  }

  // 检查剪贴板内容
  Future<void> _checkClipboard() async {
    try {
      final reader = await clipboard?.read();
      if (reader == null) return;
      String? currentContent;

      if (reader.canProvide(Formats.plainText)) {
        final text = await reader.readValue(Formats.plainText);
        currentContent = text;
      }

      debugPrint('currentContent: $currentContent');
      // 只有当内容变化时才触发回调
      if (currentContent != null && currentContent != _lastClipboardContent) {
        _lastClipboardContent = currentContent;
        _onClipboardChangedCallback?.call(
          NSPboardTypeModel(
            time: DateTime.now().toString(),
            ptype: 'text',
            pvalue: currentContent,
            appid: '',
            appname: '',
          ),
        );
      }
    } catch (e) {
      debugPrint('读取剪贴板失败: $e');
    }
  }

  // 设置剪贴板监听回调
  void onClipboardChanged(ValueChanged<NSPboardTypeModel?> callback) {
    _onClipboardChangedCallback = callback;
  }

  // 写入多格式内容到剪贴板
  Future<void> setMultiFormatContent({
    String? plainText,
  }) async {
    final item = DataWriterItem();
    if (plainText != null) {
      item.add(Formats.plainText(plainText));
      _lastClipboardContent = plainText;
    }
    await clipboard!.write([item]);
  }

  // 移除监听并停止定时器
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _onClipboardChangedCallback = null;
    _lastClipboardContent = null;
  }
}
