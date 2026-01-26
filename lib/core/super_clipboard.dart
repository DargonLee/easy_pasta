import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/model/content_classification.dart';
import 'package:easy_pasta/core/app_source_service.dart';
import 'package:easy_pasta/core/content_classifier.dart';

/// A singleton class that manages system clipboard operations and monitoring
class SuperClipboard {
  // Singleton implementation
  static final SuperClipboard _instance = SuperClipboard._internal();
  static SuperClipboard get instance => _instance;
  SuperClipboard._internal();

  final SystemClipboard? _clipboard = SystemClipboard.instance;
  ValueChanged<ClipboardItemModel?>? _onClipboardChanged;
  String? _lastContentHash; // 改为存储哈希值，而不是完整的 model
  String? _lastFastHash;
  DateTime? _lastImageAttemptAt;
  Timer? _pollingTimer;
  bool _isPolling = false;

  static const Duration _pollingInterval = Duration(seconds: 1);
  static const Duration _imageAttemptCooldown = Duration(seconds: 6);

  /// Starts monitoring clipboard changes
  void _startPollingTimer() {
    if (_pollingTimer != null) return;
    _pollingTimer = Timer.periodic(_pollingInterval, (_) => _pollClipboard());
  }

  void _stopPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Polls clipboard content for changes
  Future<void> _pollClipboard() async {
    if (_onClipboardChanged == null) {
      _stopPollingTimer();
      return;
    }
    if (_isPolling) return;
    _isPolling = true;

    try {
      final reader = await _clipboard?.read();
      if (reader == null) {
        return;
      }

      final fastHash = await _computeFastHash(reader);
      if (fastHash != null &&
          fastHash == _lastFastHash &&
          _lastContentHash != null) {
        return;
      }

      // 如果只有图片且近期已尝试过，延迟重试以避免重度重复解码
      final isImageOnly = reader.canProvide(Formats.png) &&
          !reader.canProvide(Formats.plainText) &&
          !reader.canProvide(Formats.htmlText) &&
          !reader.canProvide(Formats.fileUri);
      if (isImageOnly &&
          _lastImageAttemptAt != null &&
          DateTime.now().difference(_lastImageAttemptAt!) <
              _imageAttemptCooldown) {
        return;
      }

      await _processClipboardContent(reader, fastHash: fastHash);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Clipboard polling failed: $e');
      }
    } finally {
      _isPolling = false;
    }
  }

  /// Processes different types of clipboard content
  Future<void> _processClipboardContent(
    ClipboardReader reader, {
    String? fastHash,
  }) async {
    // 极致简方案：仅处理文本，且限制最大长度
    if (!reader.canProvide(Formats.plainText)) return;

    final text = await reader.readValue(Formats.plainText);
    if (text == null) return;

    final content = text.toString();
    // 超过 50KB 的内容不进入后续识别，直接作为普通文本
    if (content.length > 50000) {
      await _handleContentChange(
          content.substring(0, 50000), ClipboardType.text,
          fastHash: fastHash);
      return;
    }

    await _handleContentChange(content, ClipboardType.text, fastHash: fastHash);
  }

  /// Handles content changes and notifies listeners
  Future<void> _handleContentChange(String content, ClipboardType? type,
      {Uint8List? bytes, String? fastHash}) async {
    // 为内容生成哈希值 - 移动到 background isolate 如果字节较大
    final bytesToHash = bytes ?? Uint8List.fromList(utf8.encode(content));

    String contentHash;
    if (bytesToHash.length > 1024 * 10) {
      // 大于 10KB 则在 isolate 中计算哈希
      contentHash = await compute(
          (Uint8List b) => sha256.convert(b).toString(), bytesToHash);
    } else {
      contentHash = sha256.convert(bytesToHash).toString();
    }

    if (contentHash != _lastContentHash) {
      _lastContentHash = contentHash;
      // 复用 contentHash 作为 fastHash，避免重复计算
      _lastFastHash = fastHash ?? contentHash;

      // 确认变化后，才获取一次 sourceAppId (最省性能)
      final sourceAppId = await AppSourceService().getFrontmostAppBundleId();

      final baseModel = ClipboardItemModel(
        ptype: type ?? ClipboardType.text,
        pvalue: content,
        bytes: bytes,
        sourceAppId: sourceAppId,
      );

      // 智能识别：获取分类结果 (不包含图片，因为 classifier 只处理文本/HTML)
      ContentClassification? classification;
      if (baseModel.ptype == ClipboardType.text ||
          baseModel.ptype == ClipboardType.html) {
        classification = await baseModel.classify();
      }

      final contentModel = baseModel.copyWith(classification: classification);
      _onClipboardChanged?.call(contentModel);
    }
  }

  /// Sets clipboard change listener
  void setClipboardListener(ValueChanged<ClipboardItemModel?>? listener) {
    _onClipboardChanged = listener;
    if (listener == null) {
      _stopPollingTimer();
      return;
    }
    _startPollingTimer();
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
    _stopPollingTimer();
    _onClipboardChanged = null;
    _lastContentHash = null;
    _lastFastHash = null;
    _lastImageAttemptAt = null;
  }

  Future<String?> _computeFastHash(ClipboardReader reader) async {
    try {
      if (reader.canProvide(Formats.plainText)) {
        final text = await reader.readValue(Formats.plainText);
        if (text != null) {
          final str = text.toString();
          // 限制最大 10KB，避免超大文本阻塞
          final limitedStr = str.length > 10240 ? str.substring(0, 10240) : str;
          return _hashString(limitedStr);
        }
      }
      if (reader.canProvide(Formats.htmlText)) {
        final html = await reader.readValue(Formats.htmlText);
        if (html != null) {
          final str = html.toString();
          final limitedStr = str.length > 10240 ? str.substring(0, 10240) : str;
          return _hashString(limitedStr);
        }
      }
      if (reader.canProvide(Formats.fileUri)) {
        final fileUri = await reader.readValue(Formats.fileUri);
        if (fileUri != null) {
          return _hashString(fileUri.toString());
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to compute clipboard fast hash: $e');
      }
    }
    return null;
  }

  /// 计算字符串哈希（同步，但已限制长度）
  String _hashString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
