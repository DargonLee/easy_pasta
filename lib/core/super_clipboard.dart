import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/clipboard_type.dart';

/// 剪贴板管理器
/// 负责监听和管理系统剪贴板的变化
class SuperClipboard {
  // 单例实现
  static final SuperClipboard _instance = SuperClipboard._internal();
  static SuperClipboard get instance => _instance;

  /// 系统剪贴板实例
  final SystemClipboard? _clipboard = SystemClipboard.instance;

  /// 剪贴板内容变化回调
  ValueChanged<ClipboardItemModel?>? _onClipboardChanged;

  /// 缓存的上一次剪贴板内容
  ClipboardItemModel? _lastContent;

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

      if (reader.canProvide(Formats.htmlText)) {
        final html = await reader.readValue(Formats.htmlText);
        if (html != null) {
          _handleContentChange(html.toString(), ClipboardType.html);
        }
      } else if (reader.canProvide(Formats.fileUri)) {
        final fileUri = await reader.readValue(Formats.fileUri);
        if (fileUri != null) {
          _handleContentChange(fileUri.toString(), ClipboardType.file);
        }
      } else if (reader.canProvide(Formats.plainText)) {
        final text = await reader.readValue(Formats.plainText);
        if (text != null) {
          _handleContentChange(text.toString(), ClipboardType.text);
        }
      } else if (reader.canProvide(Formats.png)) {
        reader.getFile(Formats.png, (file) async {
          try {
            final stream = file.getStream();
            final bytes = await stream.toList();
            final imageData = bytes.expand((x) => x).toList();
            _handleContentChange(imageData.toString(), ClipboardType.image);
          } catch (e) {
            debugPrint('Error processing image: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Clipboard polling error: $e');
    }
  }

  /// 处理内容变化
  void _handleContentChange(dynamic currentContent, ClipboardType? type) {
    final contentModel = ClipboardItemModel(
      ptype: type,
      pvalue: currentContent,
    );
    if (contentModel != _lastContent) {
      _lastContent = contentModel;
      _notifyContentChange(contentModel);
    }
  }

  /// 通知内容变化
  void _notifyContentChange(ClipboardItemModel contentModel) {
    _onClipboardChanged?.call(contentModel);
  }

  /// 设置剪贴板变化监听器
  void setClipboardListener(ValueChanged<ClipboardItemModel?> listener) {
    _onClipboardChanged = listener;
  }

  /// 写入内容到剪贴板
  Future<void> setPasteboardItem(ClipboardItemModel model) async {
    await setContent(content: model.pvalue, type: model.ptype);
  }

  /// 写入多格式内容到剪贴板
  Future<void> setContent({dynamic content, ClipboardType? type}) async {
    if (content == null) return;

    final item = DataWriterItem();
    if (type == ClipboardType.html) {
      item.add(Formats.htmlText(content));
    } else if (type == ClipboardType.file) {
      item.add(Formats.fileUri(content));
    } else if (type == ClipboardType.text) {
      item.add(Formats.plainText(content));
    } else if (type == ClipboardType.image) {
      item.add(Formats.png(Uint8List.fromList(content)));
    }

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
    _lastContent = null;
  }
}
