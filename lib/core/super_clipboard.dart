import 'dart:async';
import 'package:flutter/material.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

/// 剪贴板管理器
/// 负责监听和管理系统剪贴板的变化
class SuperClipboard {
  // 单例实现
  static final SuperClipboard _instance = SuperClipboard._internal();
  static SuperClipboard get instance => _instance;

  /// 系统剪贴板实例
  final SystemClipboard? _clipboard = SystemClipboard.instance;

  /// 剪贴板内容变化回调
  ValueChanged<NSPboardTypeModel?>? _onClipboardChanged;

  /// 缓存的上一次剪贴板内容
  String? _cachedContent;

  /// 定时检查剪贴板的定时器
  Timer? _pollingTimer;

  /// 轮询间隔时间
  static const _pollingInterval = Duration(seconds: 1);

  SuperClipboard._internal() {
    _initializeClipboardMonitoring();
  }

  /// 初始化剪贴板监控
  void _initializeClipboardMonitoring() {
    _startPollingTimer();
  }

  /// 启动定时器进行剪贴板轮询
  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) => _pollClipboard());
  }

  /// 轮询检查剪贴板内容
  Future<void> _pollClipboard() async {
    try {
      final reader = await _clipboard?.read();
      if (reader == null) return;

      final (currentContent, type) = await _readClipboard(reader);
      _handleContentChange(currentContent, type);
    } catch (e) {
      debugPrint('Clipboard polling error: $e');
    }
  }

  /// 读取纯文本内容
  Future<(String?, String?)> _readClipboard(ClipboardReader reader) async {
    String type = "text";
    if (reader.canProvide(Formats.plainText)) {
      final text = await reader.readValue(Formats.plainText);
      return (text, type);
    }
    return (null, null);
  }

  /// 处理内容变化
  void _handleContentChange(String? currentContent, String? type) {
    if (currentContent != null && currentContent != _cachedContent) {
      _cachedContent = currentContent;
      _notifyContentChange(currentContent, type);
    }
  }

  /// 通知内容变化
  void _notifyContentChange(String content, String? type) {
    _onClipboardChanged?.call(
      NSPboardTypeModel(
        ptype: type ?? 'text',
        pvalue: content,
      ),
    );
  }

  /// 设置剪贴板变化监听器
  void setClipboardListener(ValueChanged<NSPboardTypeModel?> listener) {
    _onClipboardChanged = listener;
  }

  /// 写入内容到剪贴板
  Future<void> setPasteboardItem(NSPboardTypeModel model) async {
    await setContent(plainText: model.pvalue, type: model.ptype);
  }

  /// 写入多格式内容到剪贴板
  Future<void> setContent({String? plainText, String? type}) async {
    if (plainText == null) return;

    final item = DataWriterItem();
    item.add(Formats.plainText(plainText));
    _cachedContent = plainText;

    try {
      await _clipboard?.write([item]);
    } catch (e) {
      debugPrint('Failed to write to clipboard: $e');
      rethrow;
    }
  }

  /// 清理资源
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _onClipboardChanged = null;
    _cachedContent = null;
  }
}
