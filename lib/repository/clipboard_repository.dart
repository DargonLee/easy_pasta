import 'dart:typed_data';
import 'package:easy_pasta/db/database_helper.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

class ClipboardRepository {
  final DatabaseHelper _db;

  ClipboardRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  /// 分页拉取历史记录 (包含完整 bytes 以提升图片清晰度)
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
      // 同时有开始和结束时间
      whereClause += ' AND ${DatabaseConfig.columnTime} BETWEEN ? AND ?';
      whereArgs.add(startTime.toString());
      whereArgs.add(endTime.toString());
    } else if (startTime != null) {
      // 只有开始时间（开始时间之后的数据）
      whereClause += ' AND ${DatabaseConfig.columnTime} >= ?';
      whereArgs.add(startTime.toString());
    } else if (endTime != null) {
      // 只有结束时间（结束时间之前的数据）
      whereClause += ' AND ${DatabaseConfig.columnTime} < ?';
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
    // 注意: 这里不 SELECT columnBytes，而是 SELECT 必要的元数据与 columnThumbnail
    const columns =
        't.id, t.time, t.type, t.value, t.isFavorite, t.bytes, t.thumbnail, t.sourceAppId, t.classification';
    String sql;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      // 使用 FTS5 全文搜索
      sql = '''
        SELECT $columns
        FROM ${DatabaseConfig.tableName} t
        JOIN ${DatabaseConfig.ftsTableName} f ON t.${DatabaseConfig.columnId} = f.${DatabaseConfig.columnId}
        WHERE f.${DatabaseConfig.columnValue} MATCH ? $whereClause
        ORDER BY t.${DatabaseConfig.columnTime} DESC
        LIMIT ? OFFSET ?
      ''';
      whereArgs.insert(0, '$searchQuery*'); // FTS5 通配符
    } else {
      sql = '''
        SELECT ${columns.replaceAll('t.', '')} FROM ${DatabaseConfig.tableName}
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
    return await _db.insertPboardItem(item);
  }

  /// 回填分类结果，避免后续重复分类
  Future<void> updateItemClassification(
      String id, String classificationJson) async {
    await _db.setClassification(id, classificationJson);
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
