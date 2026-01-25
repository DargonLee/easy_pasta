import 'package:flutter/foundation.dart';
import 'package:easy_pasta/db/database_helper.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/repository/clipboard_repository.dart';
import 'package:image/image.dart' as img;

class ClipboardService {
  final ClipboardRepository _repository;

  ClipboardService({ClipboardRepository? repository})
      : _repository = repository ?? ClipboardRepository();

  /// 插入新项，自动处理图片压缩与缩略图生成
  Future<String?> processAndInsert(ClipboardItemModel item) async {
    ClipboardItemModel processedItem = item;

    if (item.ptype == ClipboardType.image && item.bytes != null) {
      // 直接在主线程处理图片，不使用 Isolate
      final thumbnail = await _generateThumbnail(item.bytes!);
      processedItem = item.copyWith(thumbnail: thumbnail);
    }

    return await _repository.insertItem(processedItem);
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
    return await _repository.getItems(
      limit: limit,
      offset: offset,
      startTime: startTime,
      endTime: endTime,
      searchQuery: searchQuery,
      filterType: filterType,
    );
  }

  /// 生成缩略图逻辑 (在 Isolate 中执行)
  static Uint8List? _generateThumbnailSync(Uint8List original) {
    try {
      final image = img.decodeImage(original);
      if (image == null) return null;

      final thumbnail = img.copyResize(
        image,
        width: image.width > image.height ? 200 : null,
        height: image.height >= image.width ? 200 : null,
        interpolation: img.Interpolation.linear,
      );

      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 75));
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
