import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/db/shared_preference_helper.dart';

/// Exception thrown when database operations fail
class DatabaseException implements Exception {
  final String message;
  final dynamic error;

  DatabaseException(this.message, [this.error]);

  @override
  String toString() =>
      'DatabaseException: $message${error != null ? ' ($error)' : ''}';
}

/// Configuration for the database
class DatabaseConfig {
  static const String dbName = 'easy_pasta.db';
  static const String tableName = 'clipboard_items';
  static const String ftsTableName = 'clipboard_items_fts'; // FTS5 虚拟表
  static const int version = 1;

  // Table columns
  static const String columnId = 'id';
  static const String columnTime = 'time';
  static const String columnType = 'type';
  static const String columnValue = 'value';
  static const String columnIsFavorite = 'isFavorite';
  static const String columnBytes = 'bytes';
  static const String columnThumbnail = 'thumbnail'; // 新增缩略图字段
  static const String columnSourceAppId = 'sourceAppId';
}

/// Abstract interface for database operations
abstract class IDatabaseHelper {
  Future<List<Map<String, dynamic>>> getPboardItemListByType(String type);
  Future<List<Map<String, dynamic>>> getPboardItemListWithString(String query);
  Future<List<Map<String, dynamic>>> getFavoritePboardItemList();
  Future<List<Map<String, dynamic>>> getPboardItemList();
  Future<List<Map<String, dynamic>>> getPboardItemListPaginated(
      {int limit, int offset, DateTime? startTime, DateTime? endTime});
  Future<ClipboardItemModel?> checkDuplicate(ClipboardItemModel model);
  Future<void> setFavorite(ClipboardItemModel model);
  Future<void> cancelFavorite(ClipboardItemModel model);
  Future<void> deletePboardItem(ClipboardItemModel model);
  Future<String?> insertPboardItem(ClipboardItemModel model);
  Future<void> cleanupExpiredItems();
  Future<int> getCount();
  Future<int> deleteAll();
  Future<int> getMaxCount();
  Future<int> getRetentionDays();
  Future<double> getDatabaseSize(); // 获取物理文件大小(MB)
  Future<void> optimizeDatabase(); // 执行合并与压缩
}

/// Implementation of database operations for clipboard management
class DatabaseHelper implements IDatabaseHelper {
  // Singleton implementation
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;
  bool _isInitializing = false;
  Future<Database>? _initFuture;

  /// Returns database instance, initializing if necessary
  Future<Database> get database async {
    // 如果已初始化，直接返回
    if (_db != null) {
      return _db!;
    }

    // 如果正在初始化，等待完成
    if (_isInitializing && _initFuture != null) {
      return _initFuture!;
    }

    // 开始初始化
    _isInitializing = true;
    _initFuture = _initDatabase();

    try {
      final result = await _initFuture!;
      _db = result; // 关键：保存初始化结果
      return result;
    } finally {
      _isInitializing = false;
      _initFuture = null;
    }
  }

  @override
  Future<int> getRetentionDays() async {
    final prefs = await SharedPreferenceHelper.instance;
    return prefs.getRetentionDays();
  }

  /// Initializes the database
  Future<Database> _initDatabase() async {
    // Log using debugPrint for visibility
    debugPrint('🟡 _initDatabase called');

    try {
      sqfliteFfiInit();
      final path = await _getDatabasePath();
      debugPrint('🟡 db path: $path');
      final databaseFactory = databaseFactoryFfi;

      final db = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: DatabaseConfig.version,
          onCreate: _createDb,
          onUpgrade: _onUpgrade,
        ),
      );

      _isInitializing = false;
      return db;
    } catch (e) {
      _isInitializing = false;
      throw DatabaseException('Failed to initialize database', e);
    }
  }

  /// Gets the database file path
  Future<String> _getDatabasePath() async {
    try {
      final directory = await getApplicationSupportDirectory();
      return '${directory.path}/${DatabaseConfig.dbName}';
    } catch (e) {
      throw DatabaseException('Failed to get database path', e);
    }
  }

  /// Creates database tables and indexes
  Future<void> _createDb(Database db, int version) async {
    await db.transaction((txn) async {
      // Create main table with all columns including thumbnail
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableName}(
          ${DatabaseConfig.columnId} TEXT PRIMARY KEY,
          ${DatabaseConfig.columnTime} TEXT NOT NULL,
          ${DatabaseConfig.columnType} TEXT NOT NULL,
          ${DatabaseConfig.columnValue} TEXT NOT NULL,
          ${DatabaseConfig.columnIsFavorite} INTEGER DEFAULT 0,
          ${DatabaseConfig.columnBytes} BLOB,
          ${DatabaseConfig.columnThumbnail} BLOB,
          ${DatabaseConfig.columnSourceAppId} TEXT
        )
      ''');

      // Create indexes
      await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_time ON ${DatabaseConfig.tableName} (${DatabaseConfig.columnTime})');
      await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_type ON ${DatabaseConfig.tableName} (${DatabaseConfig.columnType})');
      await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_favorite ON ${DatabaseConfig.tableName} (${DatabaseConfig.columnIsFavorite})');
      await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_favorite_time ON ${DatabaseConfig.tableName} (${DatabaseConfig.columnIsFavorite}, ${DatabaseConfig.columnTime})');

      // Create FTS5 virtual table
      await txn.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS ${DatabaseConfig.ftsTableName} USING fts5(
          ${DatabaseConfig.columnId} UNINDEXED, 
          ${DatabaseConfig.columnValue}
        )
      ''');

      // Create Triggers for FTS5 synchronization
      await txn.execute('''
        CREATE TRIGGER IF NOT EXISTS trg_pboard_insert AFTER INSERT ON ${DatabaseConfig.tableName}
        BEGIN
          INSERT INTO ${DatabaseConfig.ftsTableName}(${DatabaseConfig.columnId}, ${DatabaseConfig.columnValue})
          VALUES (new.${DatabaseConfig.columnId}, new.${DatabaseConfig.columnValue});
        END
      ''');

      await txn.execute('''
        CREATE TRIGGER IF NOT EXISTS trg_pboard_delete AFTER DELETE ON ${DatabaseConfig.tableName}
        BEGIN
          DELETE FROM ${DatabaseConfig.ftsTableName} WHERE ${DatabaseConfig.columnId} = old.${DatabaseConfig.columnId};
        END
      ''');

      await txn.execute('''
        CREATE TRIGGER IF NOT EXISTS trg_pboard_update AFTER UPDATE OF ${DatabaseConfig.columnValue} ON ${DatabaseConfig.tableName}
        BEGIN
          UPDATE ${DatabaseConfig.ftsTableName} 
          SET ${DatabaseConfig.columnValue} = new.${DatabaseConfig.columnValue}
          WHERE ${DatabaseConfig.columnId} = old.${DatabaseConfig.columnId};
        END
      ''');
    });
  }

  /// Handles database upgrades (No-op since we reset to v1)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint(
        'Database upgrade from $oldVersion to $newVersion requested, but treated as fresh due to dev reset.');
  }

  @override
  Future<int> getMaxCount() async {
    try {
      final prefs = await SharedPreferenceHelper.instance;
      return prefs.getMaxItemStore();
    } catch (e) {
      throw DatabaseException('Failed to get max count', e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPboardItemListByType(
      String type) async {
    try {
      final db = await database;
      return await db.query(
        DatabaseConfig.tableName,
        where: '${DatabaseConfig.columnType} = ?',
        whereArgs: [type],
        orderBy: '${DatabaseConfig.columnTime} DESC',
      );
    } catch (e) {
      throw DatabaseException('Failed to get items by type', e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPboardItemListWithString(
      String query) async {
    try {
      final db = await database;
      // 使用 FTS5 全文检索 (如果 FTS5 失败，回退到 LIKE)
      try {
        final results = await db.rawQuery('''
          SELECT t.* 
          FROM ${DatabaseConfig.tableName} t
          JOIN ${DatabaseConfig.ftsTableName} f ON t.${DatabaseConfig.columnId} = f.${DatabaseConfig.columnId}
          WHERE f.${DatabaseConfig.columnValue} MATCH ?
          ORDER BY t.${DatabaseConfig.columnTime} DESC
        ''', [query]);
        return results;
      } catch (e) {
        debugPrint('FTS5 search failed, falling back to LIKE: $e');
        return await db.query(
          DatabaseConfig.tableName,
          where: '${DatabaseConfig.columnValue} LIKE ?',
          whereArgs: ['%$query%'],
          orderBy: '${DatabaseConfig.columnTime} DESC',
        );
      }
    } catch (e) {
      throw DatabaseException('Failed to search items', e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFavoritePboardItemList() async {
    try {
      final db = await database;
      return await db.query(
        DatabaseConfig.tableName,
        where: '${DatabaseConfig.columnIsFavorite} = 1',
        orderBy: '${DatabaseConfig.columnTime} DESC',
      );
    } catch (e) {
      throw DatabaseException('Failed to get favorite items', e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPboardItemList() async {
    try {
      final db = await database;
      return await db.query(
        DatabaseConfig.tableName,
        columns: [
          DatabaseConfig.columnId,
          DatabaseConfig.columnTime,
          DatabaseConfig.columnType,
          DatabaseConfig.columnValue,
          DatabaseConfig.columnIsFavorite,
          DatabaseConfig.columnThumbnail,
          DatabaseConfig.columnSourceAppId,
          // Exclude bytes for list view performance
        ],
        orderBy: '${DatabaseConfig.columnTime} DESC',
      );
    } catch (e) {
      throw DatabaseException('Failed to get items', e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPboardItemListPaginated({
    int limit = 20,
    int offset = 0,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final db = await database;
      String? whereClause;
      List<dynamic>? whereArgs;

      if (startTime != null && endTime != null) {
        whereClause = '${DatabaseConfig.columnTime} BETWEEN ? AND ?';
        whereArgs = [startTime.toString(), endTime.toString()];
      }

      return await db.query(
        DatabaseConfig.tableName,
        columns: [
          DatabaseConfig.columnId,
          DatabaseConfig.columnTime,
          DatabaseConfig.columnType,
          DatabaseConfig.columnValue,
          DatabaseConfig.columnIsFavorite,
          DatabaseConfig.columnThumbnail,
          DatabaseConfig.columnSourceAppId,
        ],
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '${DatabaseConfig.columnTime} DESC',
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw DatabaseException('Failed to get paginated items', e);
    }
  }

  @override
  Future<ClipboardItemModel?> checkDuplicate(ClipboardItemModel model) async {
    try {
      final db = await database;
      final results = await db.query(
        DatabaseConfig.tableName,
        where:
            '${DatabaseConfig.columnValue} = ? AND ${DatabaseConfig.columnType} = ?',
        whereArgs: [model.pvalue, model.ptype.toString()],
        limit: 1,
        orderBy: '${DatabaseConfig.columnTime} DESC',
      );

      if (results.isNotEmpty) {
        return ClipboardItemModel.fromMapObject(results.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> setFavorite(ClipboardItemModel model) async {
    try {
      final db = await database;
      await db.update(
        DatabaseConfig.tableName,
        {DatabaseConfig.columnIsFavorite: 1},
        where: '${DatabaseConfig.columnId} = ?',
        whereArgs: [model.id],
      );
    } catch (e) {
      throw DatabaseException('Failed to set favorite', e);
    }
  }

  @override
  Future<void> cancelFavorite(ClipboardItemModel model) async {
    try {
      final db = await database;
      await db.update(
        DatabaseConfig.tableName,
        {DatabaseConfig.columnIsFavorite: 0},
        where: '${DatabaseConfig.columnId} = ?',
        whereArgs: [model.id],
      );
    } catch (e) {
      throw DatabaseException('Failed to cancel favorite', e);
    }
  }

  @override
  Future<void> deletePboardItem(ClipboardItemModel model) async {
    try {
      final db = await database;
      await db.delete(
        DatabaseConfig.tableName,
        where: '${DatabaseConfig.columnId} = ?',
        whereArgs: [model.id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete item', e);
    }
  }

  @override
  Future<String?> insertPboardItem(ClipboardItemModel model) async {
    debugPrint('🟡 DatabaseHelper.insertPboardItem called for ${model.id}');
    final db = await database;
    debugPrint('🟡 Database instance obtained');
    final maxCount = await getMaxCount();
    final retentionDays = await getRetentionDays();
    debugPrint('🟡 maxCount: $maxCount, retentionDays: $retentionDays');

    return await db.transaction((txn) async {
      try {
        if (retentionDays > 0) {
          final expirationDate =
              DateTime.now().subtract(Duration(days: retentionDays));
          await txn.delete(
            DatabaseConfig.tableName,
            where:
                '${DatabaseConfig.columnIsFavorite} = 0 AND ${DatabaseConfig.columnTime} < ?',
            whereArgs: [expirationDate.toString()],
          );
        }

        debugPrint('🟡 Inserting item into database...');
        await txn.insert(DatabaseConfig.tableName, model.toMap());
        debugPrint('✅ Item inserted successfully');

        final result = await txn
            .rawQuery('SELECT COUNT(*) FROM ${DatabaseConfig.tableName}');
        final count = result.isNotEmpty ? result.first.values.first as int : 0;
        debugPrint('🟡 Current item count: $count');
        if (count > maxCount) {
          final oldestItems = await txn.query(
            DatabaseConfig.tableName,
            columns: [DatabaseConfig.columnId],
            where: '${DatabaseConfig.columnIsFavorite} = 0',
            orderBy: '${DatabaseConfig.columnTime} ASC',
            limit: 1,
          );

          if (oldestItems.isNotEmpty) {
            final id = oldestItems.first[DatabaseConfig.columnId] as String;
            await txn.delete(
              DatabaseConfig.tableName,
              where: '${DatabaseConfig.columnId} = ?',
              whereArgs: [id],
            );
            debugPrint('🟡 Deleted oldest item: $id');
            return id;
          }
        }
        return null;
      } catch (e) {
        debugPrint('❌ Database insert failed: $e');
        throw DatabaseException('Failed to insert item', e);
      }
    });
  }

  @override
  Future<void> cleanupExpiredItems() async {
    try {
      final db = await database;
      final retentionDays = await getRetentionDays();
      if (retentionDays <= 0) return;

      final expirationDate =
          DateTime.now().subtract(Duration(days: retentionDays));
      await db.delete(
        DatabaseConfig.tableName,
        where:
            '${DatabaseConfig.columnIsFavorite} = 0 AND ${DatabaseConfig.columnTime} < ?',
        whereArgs: [expirationDate.toString()],
      );
    } catch (e) {
      debugPrint('Cleanup expired items failed: $e');
    }
  }

  @override
  Future<int> getCount() async {
    try {
      final db = await database;
      final result =
          await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConfig.tableName}');
      return result.isNotEmpty ? result.first.values.first as int : 0;
    } catch (e) {
      throw DatabaseException('Failed to get count', e);
    }
  }

  @override
  Future<int> deleteAll() async {
    try {
      final db = await database;
      return await db.delete(DatabaseConfig.tableName);
    } catch (e) {
      throw DatabaseException('Failed to delete all items', e);
    }
  }

  @override
  Future<double> getDatabaseSize() async {
    try {
      final path = await _getDatabasePath();
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.length();
        return bytes / (1024 * 1024);
      }
      return 0.0;
    } catch (e) {
      debugPrint('Get database size failed: $e');
      return 0.0;
    }
  }

  @override
  Future<void> optimizeDatabase() async {
    try {
      final db = await database;
      await db.execute('VACUUM');
      debugPrint('Database optimized');
    } catch (e) {
      debugPrint('Optimize database failed: $e');
      rethrow;
    }
  }

  /// Closes the database connection
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  /// Helper to delete the database file (for development reset)
  Future<void> deleteDatabaseFile() async {
    try {
      await close();
      final path = await _getDatabasePath();
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('✅ Database file deleted successfully');
      }
    } catch (e) {
      debugPrint('❌ Failed to delete database: $e');
    }
  }
}
