import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_pasta/db/database_helper.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/clipboard_type.dart';

class ClipboardRepository {
  final DatabaseHelper _db;

  ClipboardRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  /// 分页拉取历史记录 (仅包含元数据与缩略图，不包含原始 bytes)
  Future<List<ClipboardItemModel>> getItems({
    required int limit,
    required int offset,
    DateTime? startTime,
    DateTime? endTime,
    String? searchQuery,
    String? filterType,
  }) async {
    final db = await _db.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    // 处理时间过滤
    if (startTime != null && endTime != null) {
      whereClause += ' AND ${DatabaseConfig.columnTime} BETWEEN ? AND ?';
      whereArgs.add(startTime.toString());
      whereArgs.add(endTime.toString());
    }

    // 处理类型过滤
    if (filterType != null && filterType != 'all') {
      if (filterType == 'favorite') {
        whereClause += ' AND ${DatabaseConfig.columnIsFavorite} = 1';
      } else {
        whereClause += ' AND ${DatabaseConfig.columnType} = ?';
        whereArgs.add(filterType);
      }
    }

    // 构建 SQL
    // 注意: 这里不 SELECT columnBytes，而是 SELECT columnThumbnail
    String sql;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      // 使用 FTS5 全文搜索
      sql = '''
        SELECT t.* 
        FROM ${DatabaseConfig.tableName} t
        JOIN ${DatabaseConfig.ftsTableName} f ON t.${DatabaseConfig.columnId} = f.${DatabaseConfig.columnId}
        WHERE f.${DatabaseConfig.columnValue} MATCH ? $whereClause
        ORDER BY t.${DatabaseConfig.columnTime} DESC
        LIMIT ? OFFSET ?
      ''';
      whereArgs.insert(0, '$searchQuery*'); // FTS5 通配符
    } else {
      sql = '''
        SELECT * FROM ${DatabaseConfig.tableName}
        WHERE 1=1 $whereClause
        ORDER BY ${DatabaseConfig.columnTime} DESC
        LIMIT ? OFFSET ?
      ''';
    }

    whereArgs.add(limit);
    whereArgs.add(offset);

    final results = await db.rawQuery(sql, whereArgs);
    return results.map((map) => ClipboardItemModel.fromMapObject(map)).toList();
  }

  /// 根据 ID 精确读取原始完整字节 (用于预览或重新复制)
  Future<Uint8List?> getFullBytes(String id) async {
    final db = await _db.database;
    final results = await db.query(
      DatabaseConfig.tableName,
      columns: [DatabaseConfig.columnBytes],
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first[DatabaseConfig.columnBytes] as Uint8List?;
    }
    return null;
  }

  /// 插入新项 (Repository 层暂不处理图片压缩，由 Service 处理)
  Future<String?> insertItem(ClipboardItemModel item) async {
    debugPrint('🟠 ClipboardRepository.insertItem called for ${item.id}');
    final result = await _db.insertPboardItem(item);
    debugPrint('🟠 insertPboardItem returned: $result');
    return result;
  }

  /// 删除项
  Future<void> deleteItem(ClipboardItemModel item) async {
    await _db.deletePboardItem(item);
  }

  /// 收藏/取消收藏
  Future<void> toggleFavorite(ClipboardItemModel item) async {
    await _db.setFavorite(item);
  }
}
