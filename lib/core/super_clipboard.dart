import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/core/html_processor.dart';
import 'package:easy_pasta/core/app_source_service.dart';

/// A singleton class that manages system clipboard operations and monitoring
class SuperClipboard {
  // Singleton implementation
  static final SuperClipboard _instance = SuperClipboard._internal();
  static SuperClipboard get instance => _instance;
  SuperClipboard._internal() {
    _startPollingTimer();
  }

  final SystemClipboard? _clipboard = SystemClipboard.instance;
  ValueChanged<ClipboardItemModel?>? _onClipboardChanged;
  ClipboardItemModel? _lastContent;
  Timer? _pollingTimer;
  bool _isPolling = false;

  static const Duration _pollingInterval = Duration(seconds: 1);

  /// Starts monitoring clipboard changes
  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) => _pollClipboard());
  }

  /// Polls clipboard content for changes
  Future<void> _pollClipboard() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      final reader = await _clipboard?.read();
      if (reader == null) {
        _isPolling = false;
        return;
      }

      await _processClipboardContent(reader);
    } catch (e) {
      debugPrint('Clipboard polling error: $e');
    } finally {
      _isPolling = false;
    }
  }

  /// Processes different types of clipboard content
  Future<void> _processClipboardContent(ClipboardReader reader) async {
    final sourceAppId = await AppSourceService().getFrontmostAppBundleId();
    if (await _processHtmlContent(reader, sourceAppId)) return;
    if (await _processFileContent(reader, sourceAppId)) return;
    if (await _processTextContent(reader, sourceAppId)) return;
    if (await _processImageContent(reader, sourceAppId)) return;
  }

  /// Processes HTML content from clipboard
  Future<bool> _processHtmlContent(
      ClipboardReader reader, String? sourceAppId) async {
    if (!reader.canProvide(Formats.htmlText)) return false;

    final html = await reader.readValue(Formats.htmlText);
    final htmlPlainText = await reader.readValue(Formats.plainText);

    if (html != null) {
      final processedHtml = HtmlProcessor.processHtml(html.toString());
      _handleContentChange(htmlPlainText.toString(), ClipboardType.html,
          bytes: Uint8List.fromList(utf8.encode(processedHtml)),
          sourceAppId: sourceAppId);
      return true;
    }
    return false;
  }

  /// Processes file URI content from clipboard
  Future<bool> _processFileContent(
      ClipboardReader reader, String? sourceAppId) async {
    if (!reader.canProvide(Formats.fileUri)) return false;

    final fileUri = await reader.readValue(Formats.fileUri);
    final fileUriString = await reader.readValue(Formats.plainText);

    if (fileUri != null) {
      _handleContentChange(fileUriString.toString(), ClipboardType.file,
          bytes: Uint8List.fromList(utf8.encode(fileUri.toString())),
          sourceAppId: sourceAppId);
      return true;
    }
    return false;
  }

  /// Processes plain text content from clipboard
  Future<bool> _processTextContent(
      ClipboardReader reader, String? sourceAppId) async {
    if (!reader.canProvide(Formats.plainText)) return false;

    final text = await reader.readValue(Formats.plainText);
    if (text != null) {
      _handleContentChange(text.toString(), ClipboardType.text,
          sourceAppId: sourceAppId);
      return true;
    }
    return false;
  }

  /// Processes image content from clipboard
  Future<bool> _processImageContent(
      ClipboardReader reader, String? sourceAppId) async {
    if (!reader.canProvide(Formats.png)) return false;

    try {
      final completer = Completer<bool>();

      reader.getFile(Formats.png, (file) async {
        try {
          final stream = file.getStream();
          final bytesList = await stream.toList();
          final imageData = bytesList.expand((x) => x).toList();

          if (imageData.isNotEmpty) {
            _handleContentChange('', ClipboardType.image,
                bytes: Uint8List.fromList(imageData), sourceAppId: sourceAppId);
          }
          if (!completer.isCompleted) completer.complete(true);
        } catch (e) {
          debugPrint('Error processing image: $e');
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      // 设置一个超时，防止 getFile 回调永远不执行
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint('Error accessing image file: $e');
      return false;
    }
  }

  /// Handles content changes and notifies listeners
  void _handleContentChange(String content, ClipboardType? type,
      {Uint8List? bytes, String? sourceAppId}) {
    final contentModel = _createContentModel(content, type, bytes, sourceAppId);

    if (contentModel != _lastContent) {
      _lastContent = contentModel;
      _onClipboardChanged?.call(contentModel);
    }
  }

  /// Creates a content model based on the clipboard type
  ClipboardItemModel _createContentModel(String content, ClipboardType? type,
      Uint8List? bytes, String? sourceAppId) {
    return ClipboardItemModel(
      ptype: type,
      pvalue: content,
      bytes: type == ClipboardType.text ? null : bytes,
      sourceAppId: sourceAppId,
    );
  }

  /// Sets clipboard change listener
  void setClipboardListener(ValueChanged<ClipboardItemModel?> listener) {
    _onClipboardChanged = listener;
  }

  /// Writes content to clipboard
  Future<void> setPasteboardItem(ClipboardItemModel model) => setContent(model);

  /// Writes content to clipboard with proper format
  Future<void> setContent(ClipboardItemModel model) async {
    final item = DataWriterItem();

    switch (model.ptype) {
      case ClipboardType.html:
        item.add(Formats.plainText(model.pvalue));
        item.add(
            Formats.htmlText(model.bytesToString(model.bytes ?? Uint8List(0))));
        break;
      case ClipboardType.file:
        item.add(Formats.plainText(model.pvalue));
        item.add(Formats.fileUri(
            Uri.parse(model.bytesToString(model.bytes ?? Uint8List(0)))));
        break;
      case ClipboardType.text:
        item.add(Formats.plainText(model.pvalue));
        break;
      case ClipboardType.image:
        item.add(
            Formats.png(Uint8List.fromList(model.imageBytes ?? Uint8List(0))));
        break;
      default:
        throw ArgumentError('Unsupported clipboard type: ${model.ptype}');
    }

    try {
      await _clipboard?.write([item]);
    } catch (e) {
      debugPrint('Failed to write to clipboard: $e');
      rethrow;
    }
  }

  /// Cleans up resources
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _onClipboardChanged = null;
    _lastContent = null;
  }
}
