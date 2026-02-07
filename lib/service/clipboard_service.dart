import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:easy_pasta/db/database_helper.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/content_classification.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/repository/clipboard_repository.dart';
import 'package:easy_pasta/core/content_classifier.dart';
import 'package:image/image.dart' as img;

class ClipboardService {
  static const int _classificationConcurrency = 4;
  static const int _classificationCacheMaxEntries = 5000;

  final ClipboardRepository _repository;
  final _insertWriteQueue = _AsyncWriteQueue();
  final _metadataWriteQueue = _AsyncWriteQueue();
  final LinkedHashMap<String, ContentClassification> _classificationCache =
      LinkedHashMap<String, ContentClassification>();
  final Map<String, Future<ContentClassification>> _classificationInFlight =
      <String, Future<ContentClassification>>{};

  ClipboardService({ClipboardRepository? repository})
      : _repository = repository ?? ClipboardRepository();

  /// 插入新项，保留原始图片，不生成缩略图（优先清晰度）
  Future<String?> processAndInsert(ClipboardItemModel item) async {
    final processedItem = item.ptype == ClipboardType.image
        ? item.copyWith(thumbnail: null)
        : item;

    // 串行化写入，避免高频并发写入放大 UI 抖动。
    // 若后续 profiling 显示仍有卡顿，可升级为独立 isolate + 专属 DB 连接。
    return _insertWriteQueue.run(() => _repository.insertItem(processedItem));
  }

  /// 获取带完整 bytes 的项 (Lazy Fetch)
  Future<ClipboardItemModel> ensureBytes(ClipboardItemModel item) async {
    if (item.bytes != null) return item;

    final fullBytes = await _repository.getFullBytes(item.id);
    return item.copyWith(bytes: fullBytes);
  }

  /// 搜索与过滤 (桥接 Repository)
  Future<List<ClipboardItemModel>> getFilteredItems({
    required int limit,
    required int offset,
    DateTime? startTime,
    DateTime? endTime,
    String? searchQuery,
    String? filterType,
  }) async {
    final rawItems = await _repository.getItems(
      limit: limit,
      offset: offset,
      startTime: startTime,
      endTime: endTime,
      searchQuery: searchQuery,
      filterType: filterType,
    );

    if (rawItems.isEmpty) return rawItems;
    return _applyClassificationWithLimit(rawItems);
  }

  Future<List<ClipboardItemModel>> _applyClassificationWithLimit(
      List<ClipboardItemModel> rawItems) async {
    final items = List<ClipboardItemModel>.from(rawItems);
    final pendingIndices = <int>[];

    for (var i = 0; i < rawItems.length; i++) {
      final item = rawItems[i];
      final existing = item.classification;
      if (existing != null) {
        _cacheClassification(item.id, existing);
        continue;
      }

      final cached = _touchClassificationCache(item.id);
      if (cached != null) {
        items[i] = item.copyWith(classification: cached);
        continue;
      }

      pendingIndices.add(i);
    }

    if (pendingIndices.isEmpty) {
      return items;
    }

    var cursor = 0;
    Future<void> worker() async {
      while (true) {
        if (cursor >= pendingIndices.length) return;
        final index = pendingIndices[cursor++];
        final source = rawItems[index];
        final classification = await _resolveClassification(source);
        items[index] = source.copyWith(classification: classification);
      }
    }

    final workerCount = pendingIndices.length < _classificationConcurrency
        ? pendingIndices.length
        : _classificationConcurrency;
    await Future.wait(List.generate(workerCount, (_) => worker()));

    return items;
  }

  ContentClassification? _touchClassificationCache(String id) {
    final cached = _classificationCache.remove(id);
    if (cached == null) return null;
    _classificationCache[id] = cached;
    return cached;
  }

  void _cacheClassification(String id, ContentClassification classification) {
    _classificationCache.remove(id);
    _classificationCache[id] = classification;
    while (_classificationCache.length > _classificationCacheMaxEntries) {
      _classificationCache.remove(_classificationCache.keys.first);
    }
  }

  Future<ContentClassification> _resolveClassification(
      ClipboardItemModel item) async {
    final cached = _touchClassificationCache(item.id);
    if (cached != null) return cached;

    final inFlight = _classificationInFlight[item.id];
    if (inFlight != null) return inFlight;

    final future = item.classify().then((classification) {
      _cacheClassification(item.id, classification);
      _queueClassificationPersistence(item.id, classification);
      return classification;
    }).whenComplete(() {
      _classificationInFlight.remove(item.id);
    });

    _classificationInFlight[item.id] = future;
    return future;
  }

  void _queueClassificationPersistence(
      String id, ContentClassification classification) {
    if (classification.kind == ContentKind.text) return;

    final payload = jsonEncode(classification.toMap());
    _metadataWriteQueue.runDetached(() async {
      await _repository.updateItemClassification(id, payload);
    });
  }

  /// 生成缩略图逻辑 (在 Isolate 中执行)
  static Uint8List? _generateThumbnailSync(Uint8List original) {
    try {
      final image = img.decodeImage(original);
      if (image == null) return null;

      final thumbnail = img.copyResize(
        image,
        width: image.width > image.height ? 400 : null,
        height: image.height >= image.width ? 400 : null,
        interpolation: img.Interpolation.cubic,
      );

      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 90));
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> _generateThumbnail(Uint8List original) async {
    return compute(_generateThumbnailSync, original);
  }

  // 代理 Repository 的简单方法
  Future<void> delete(ClipboardItemModel item) => _repository.deleteItem(item);
  Future<void> toggleFavorite(ClipboardItemModel item) =>
      _repository.toggleFavorite(item);
  Future<void> clearAll() async {
    await DatabaseHelper.instance.deleteAll();
  }
}

class _AsyncWriteQueue {
  Future<void> _queue = Future<void>.value();

  Future<T> run<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _queue = _queue.catchError((_) {}).then((_) async {
      try {
        completer.complete(await task());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  void runDetached(Future<void> Function() task) {
    _queue = _queue.catchError((_) {}).then((_) async {
      try {
        await task();
      } catch (_) {}
    });
  }
}
