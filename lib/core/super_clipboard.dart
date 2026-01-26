import 'dart:async';
import 'dart:convert';

import 'package:easy_pasta/core/content_classifier.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:super_clipboard/super_clipboard.dart';

import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/core/app_source_service.dart';

/// Singleton clipboard manager with optimized polling and content handling
class SuperClipboard {
  SuperClipboard._internal();
  static final SuperClipboard _instance = SuperClipboard._internal();
  static SuperClipboard get instance => _instance;

  final SystemClipboard? _clipboard = SystemClipboard.instance;

  ValueChanged<ClipboardItemModel?>? _onClipboardChanged;

  String? _lastContentHash;
  String? _lastFastHash;
  DateTime? _lastImageAttemptAt;

  Timer? _pollingTimer;
  bool _isPolling = false;
  bool _isDisposed = false;

  static const Duration _pollingInterval = Duration(seconds: 1);
  static const Duration _imageAttemptCooldown = Duration(seconds: 6);
  static const int _maxContentLength = 50000;
  static const int _fastHashLength = 10240;
  static const int _largeDataThreshold = 10 * 1024; // 10KB

  /* ================================
   * Polling lifecycle
   * ================================ */

  void _startPollingTimer() {
    if (_pollingTimer != null || _isDisposed) return;
    _pollingTimer = Timer.periodic(_pollingInterval, (_) => _pollClipboard());
  }

  void _stopPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /* ================================
   * Clipboard polling
   * ================================ */

  Future<void> _pollClipboard() async {
    if (_isDisposed || _onClipboardChanged == null) {
      _stopPollingTimer();
      return;
    }

    if (_isPolling) return;
    _isPolling = true;

    try {
      // Check clipboard availability
      if (_clipboard == null) {
        _logError('Clipboard API is not supported on this platform', null);
        return;
      }

      final reader = await _clipboard!.read();

      // Fast hash check for early exit
      final fastHash = await _computeFastHash(reader);
      if (_shouldSkipProcessing(fastHash, reader)) {
        return;
      }

      await _processClipboardContent(reader, fastHash: fastHash);
    } catch (e) {
      _logError('Clipboard polling failed', e);
    } finally {
      _isPolling = false;
    }
  }

  bool _shouldSkipProcessing(String? fastHash, ClipboardReader reader) {
    // Skip if content hasn't changed
    if (fastHash != null &&
        fastHash == _lastFastHash &&
        _lastContentHash != null) {
      return true;
    }

    // Skip image-only content if in cooldown period
    if (_isImageOnlyContent(reader) && _isImageCooldownActive()) {
      return true;
    }

    return false;
  }

  bool _isImageOnlyContent(ClipboardReader reader) {
    return reader.canProvide(Formats.png) &&
        !reader.canProvide(Formats.plainText) &&
        !reader.canProvide(Formats.htmlText) &&
        !reader.canProvide(Formats.fileUri);
  }

  bool _isImageCooldownActive() {
    return _lastImageAttemptAt != null &&
        DateTime.now().difference(_lastImageAttemptAt!) < _imageAttemptCooldown;
  }

  /* ================================
   * Content processing (核心逻辑)
   * ================================ */

  Future<void> _processClipboardContent(
    ClipboardReader reader, {
    String? fastHash,
  }) async {
    // Priority order: Image > HTML > File > Text
    // Process only the highest priority format available

    if (reader.canProvide(Formats.png)) {
      await _processImage(reader, fastHash);
      return;
    }

    if (reader.canProvide(Formats.htmlText)) {
      final html = await reader.readValue(Formats.htmlText);
      if (html != null && !_isDisposed) {
        await _handleContentChange(
          html,
          ClipboardType.html,
          fastHash: fastHash,
        );
      }
      return;
    }

    if (reader.canProvide(Formats.fileUri)) {
      final uri = await reader.readValue(Formats.fileUri);
      if (uri != null && !_isDisposed) {
        await _handleContentChange(
          uri.toFilePath(),
          ClipboardType.file,
          fastHash: fastHash,
        );
      }
      return;
    }

    if (reader.canProvide(Formats.plainText)) {
      await _processText(reader, fastHash);
    }
  }

  Future<void> _processImage(ClipboardReader reader, String? fastHash) async {
    _lastImageAttemptAt = DateTime.now();

    try {
      // Binary formats need to be read as streams
      reader.getFile(Formats.png, (file) async {
        try {
          final stream = file.getStream();
          final bytes = await _readStreamBytes(stream);

          if (_isDisposed) return;

          await _handleContentChange(
            '', // Image has no text content
            ClipboardType.image,
            bytes: bytes,
            fastHash: fastHash,
          );
        } catch (e) {
          _logError('Failed to read image stream', e);
        }
      });
    } catch (e) {
      _logError('Image processing failed', e);
    }
  }

  Future<void> _processText(ClipboardReader reader, String? fastHash) async {
    final text = await reader.readValue(Formats.plainText);
    if (text == null || _isDisposed) return;

    final limited = _limitContentLength(text);

    await _handleContentChange(
      limited,
      ClipboardType.text,
      fastHash: fastHash,
    );
  }

  Future<Uint8List> _readStreamBytes(Stream<List<int>> stream) async {
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }

  String _limitContentLength(String content) {
    return content.length > _maxContentLength
        ? content.substring(0, _maxContentLength)
        : content;
  }

  /* ================================
   * Content handling
   * ================================ */

  Future<void> _handleContentChange(
    String content,
    ClipboardType type, {
    Uint8List? bytes,
    String? fastHash,
  }) async {
    if (_isDisposed) return;

    final dataToHash = bytes ?? Uint8List.fromList(utf8.encode(content));
    final contentHash = await _computeContentHash(dataToHash);

    // Avoid duplicate processing
    if (contentHash == _lastContentHash) return;

    _lastContentHash = contentHash;
    _lastFastHash = fastHash ?? contentHash;

    final model = await _createClipboardModel(content, type, bytes);

    if (!_isDisposed) {
      _onClipboardChanged?.call(model);
    }
  }

  Future<String> _computeContentHash(Uint8List data) async {
    // Use isolate for large data to avoid blocking UI
    if (data.length > _largeDataThreshold) {
      return await compute(
        _computeSha256,
        data,
      );
    }
    return _computeSha256(data);
  }

  static String _computeSha256(Uint8List data) {
    return sha256.convert(data).toString();
  }

  Future<ClipboardItemModel> _createClipboardModel(
    String content,
    ClipboardType type,
    Uint8List? bytes,
  ) async {
    final sourceAppId = await AppSourceService().getFrontmostAppBundleId();

    final baseModel = ClipboardItemModel(
      ptype: type,
      pvalue: content,
      bytes: bytes,
      sourceAppId: sourceAppId,
    );

    // Classify text and HTML content asynchronously
    if (_shouldClassifyContent(type)) {
      final classification = await baseModel.classify();
      return baseModel.copyWith(classification: classification);
    }

    return baseModel;
  }

  bool _shouldClassifyContent(ClipboardType type) {
    return type == ClipboardType.text || type == ClipboardType.html;
  }

  /* ================================
   * Public API
   * ================================ */

  void setClipboardListener(ValueChanged<ClipboardItemModel?>? listener) {
    if (_isDisposed) {
      _logError('Cannot set listener on disposed clipboard', null);
      return;
    }

    _onClipboardChanged = listener;

    if (listener == null) {
      _stopPollingTimer();
    } else {
      _startPollingTimer();
    }
  }

  Future<void> setPasteboardItem(ClipboardItemModel model) => setContent(model);

  Future<void> setContent(ClipboardItemModel model) async {
    if (_isDisposed) {
      throw StateError('Cannot write to disposed clipboard');
    }

    if (_clipboard == null) {
      throw UnsupportedError('Clipboard API is not supported on this platform');
    }

    final item = _createDataWriterItem(model);
    await _clipboard!.write([item]);

    // Update internal state to reflect what we just wrote
    final dataToHash =
        model.bytes ?? Uint8List.fromList(utf8.encode(model.pvalue));
    _lastContentHash = await _computeContentHash(dataToHash);
  }

  DataWriterItem _createDataWriterItem(ClipboardItemModel model) {
    final item = DataWriterItem();

    switch (model.ptype) {
      case ClipboardType.text:
        item.add(Formats.plainText(model.pvalue));
        break;

      case ClipboardType.html:
        item.add(Formats.plainText(model.pvalue));
        final htmlContent = model.bytesToString(model.bytes ?? Uint8List(0));
        item.add(Formats.htmlText(htmlContent));
        break;

      case ClipboardType.file:
        item.add(Formats.plainText(model.pvalue));
        final uriString = model.bytesToString(model.bytes ?? Uint8List(0));
        item.add(Formats.fileUri(Uri.parse(uriString)));
        break;

      case ClipboardType.image:
        item.add(Formats.png(model.bytes ?? Uint8List(0)));
        break;

      default:
        throw ArgumentError('Unsupported clipboard type: ${model.ptype}');
    }

    return item;
  }

  /* ================================
   * Utilities
   * ================================ */

  Future<String?> _computeFastHash(ClipboardReader reader) async {
    try {
      // Try text first (most common case)
      if (reader.canProvide(Formats.plainText)) {
        final text = await reader.readValue(Formats.plainText);
        if (text != null) {
          return _hashLimitedString(text);
        }
      }

      // Try HTML
      if (reader.canProvide(Formats.htmlText)) {
        final html = await reader.readValue(Formats.htmlText);
        if (html != null) {
          return _hashLimitedString(html);
        }
      }

      // Try file URI
      if (reader.canProvide(Formats.fileUri)) {
        final uri = await reader.readValue(Formats.fileUri);
        if (uri != null) {
          return _hashString(uri.toFilePath());
        }
      }
    } catch (e) {
      _logError('Fast hash computation failed', e);
    }

    return null;
  }

  String _hashLimitedString(String input) {
    final length = input.length.clamp(0, _fastHashLength);
    final limited = input.substring(0, length);
    return _hashString(limited);
  }

  String _hashString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  void _logError(String message, Object? error) {
    if (kDebugMode) {
      debugPrint('[$runtimeType] $message${error != null ? ': $error' : ''}');
    }
  }

  /* ================================
   * Lifecycle
   * ================================ */

  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _stopPollingTimer();
    _onClipboardChanged = null;
    _lastContentHash = null;
    _lastFastHash = null;
    _lastImageAttemptAt = null;
  }
}
