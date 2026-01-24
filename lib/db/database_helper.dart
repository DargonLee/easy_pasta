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
  static const int version = 5;

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
      // Create main table
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
    });
  }

  /// Handles database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_favorite ON ${DatabaseConfig.tableName} (${DatabaseConfig.columnIsFavorite})');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_favorite_time ON ${DatabaseConfig.tableName} (${DatabaseConfig.columnIsFavorite}, ${DatabaseConfig.columnTime})');
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE ${DatabaseConfig.tableName} ADD COLUMN ${DatabaseConfig.columnSourceAppId} TEXT');
    }
    if (oldVersion < 4) {
      await _upgradeToV4(db);
    }
    if (oldVersion < 5) {
      await _upgradeToV5(db);
    }
  }

  Future<void> _upgradeToV4(Database db) async {
    await db.transaction((txn) async {
      // 1. 添加缩略图列
      try {
        await txn.execute(
            'ALTER TABLE ${DatabaseConfig.tableName} ADD COLUMN ${DatabaseConfig.columnThumbnail} BLOB');
      } catch (e) {
        debugPrint('Column thumbnail might already exist (v4 upgrade): $e');
      }

      // 2. 创建 FTS5 虚拟表
      await txn.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS ${DatabaseConfig.ftsTableName} USING fts5(
          ${DatabaseConfig.columnId} UNINDEXED, 
          ${DatabaseConfig.columnValue}
        )
      ''');

      // 3. 初始同步存量数据到 FTS5
      await txn.execute('''
        INSERT INTO ${DatabaseConfig.ftsTableName}(${DatabaseConfig.columnId}, ${DatabaseConfig.columnValue})
        SELECT ${DatabaseConfig.columnId}, ${DatabaseConfig.columnValue} FROM ${DatabaseConfig.tableName}
      ''');

      // 4. 创建触发器保持同步
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

  Future<void> _upgradeToV5(Database db) async {
    debugPrint('🟡 Upgrading database to v5...');
    await db.transaction((txn) async {
      // Ensure thumbnail column exists
      try {
        await txn.execute(
            'ALTER TABLE ${DatabaseConfig.tableName} ADD COLUMN ${DatabaseConfig.columnThumbnail} BLOB');
        debugPrint('✅ Added missing thumbnail column in v5 upgrade');
      } catch (e) {
        debugPrint('Thumbnail column already exists (v5 checked): $e');
      }
    });
  }

  /// Returns the maximum number of items to store
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
      return await db.query(
        DatabaseConfig.tableName,
        where: 'LOWER(${DatabaseConfig.columnValue}) LIKE LOWER(?)',
        whereArgs: ['%$query%'],
        orderBy: '${DatabaseConfig.columnTime} DESC',
      );
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
        orderBy: '${DatabaseConfig.columnTime} DESC',
      );
    } catch (e) {
      throw DatabaseException('Failed to get all items', e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPboardItemListPaginated({
    int limit = 50,
    int offset = 0,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final db = await database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (startTime != null && endTime != null) {
        whereClause = ' WHERE ${DatabaseConfig.columnTime} BETWEEN ? AND ?';
        whereArgs = [startTime.toString(), endTime.toString()];
      } else if (startTime != null) {
        whereClause = ' WHERE ${DatabaseConfig.columnTime} >= ?';
        whereArgs = [startTime.toString()];
      } else if (endTime != null) {
        whereClause = ' WHERE ${DatabaseConfig.columnTime} < ?';
        whereArgs = [endTime.toString()];
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM ${DatabaseConfig.tableName}$whereClause '
        'ORDER BY ${DatabaseConfig.columnTime} DESC LIMIT ? OFFSET ?',
        [...whereArgs, limit, offset],
      );
      return maps;
    } catch (e) {
      throw DatabaseException('Failed to get paginated items', e);
    }
  }

  @override
  Future<ClipboardItemModel?> checkDuplicate(ClipboardItemModel model) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> results;

      // For text: check by trimmed lowercase value
      if (model.ptype == ClipboardType.text) {
        final normalizedValue = model.pvalue.trim().toLowerCase();
        results = await db.query(
          DatabaseConfig.tableName,
          where:
              'LOWER(TRIM(${DatabaseConfig.columnValue})) = ? AND ${DatabaseConfig.columnType} = ?',
          whereArgs: [normalizedValue, model.ptype.toString()],
          limit: 1,
        );
      }
      // For images: check by bytes hash
      else if (model.ptype == ClipboardType.image && model.bytes != null) {
        final hash = sha256.convert(model.bytes!).toString();
        results = await db.query(
          DatabaseConfig.tableName,
          where: '${DatabaseConfig.columnType} = ?',
          whereArgs: [model.ptype.toString()],
        );

        // Check hash match in memory (more efficient than storing hash in DB)
        for (final result in results) {
          final existingBytes =
              result[DatabaseConfig.columnBytes] as List<int>?;
          if (existingBytes != null) {
            final existingHash = sha256.convert(existingBytes).toString();
            if (existingHash == hash) {
              return ClipboardItemModel.fromMapObject(result);
            }
          }
        }
        return null;
      }
      // For files: check by value (file path)
      else if (model.ptype == ClipboardType.file) {
        results = await db.query(
          DatabaseConfig.tableName,
          where:
              '${DatabaseConfig.columnValue} = ? AND ${DatabaseConfig.columnType} = ?',
          whereArgs: [model.pvalue, model.ptype.toString()],
          limit: 1,
        );
      } else {
        return null;
      }

      if (results.isNotEmpty) {
        return ClipboardItemModel.fromMapObject(results.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to check duplicate', e);
    }
  }

  @override
  Future<void> setFavorite(ClipboardItemModel model) async {
    try {
      final db = await database;
      await db.update(
        DatabaseConfig.tableName,
        {DatabaseConfig.columnIsFavorite: model.isFavorite ? 1 : 0},
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
        // 1. 先执行时间清理: 删除超过 retentionDays 且非收藏的项
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

        // 2. 插入新项
        debugPrint('🟡 Inserting item into database...');
        await txn.insert(DatabaseConfig.tableName, model.toMap());
        debugPrint('✅ Item inserted successfully');

        // 3. 检查总量限制: 如果超过 maxCount, 删除最旧的非收藏项
        final count = await _getCountInTransaction(txn);
        debugPrint('🟡 Current item count: $count');
        if (count > maxCount) {
          final itemId = await _deleteOldestNonFavoriteItemInTransaction(txn);
          debugPrint('🟡 Deleted oldest item: $itemId');
          return itemId;
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

  Future<int> _getCountInTransaction(Transaction txn) async {
    final result = await txn
        .rawQuery('SELECT COUNT(*) as count FROM ${DatabaseConfig.tableName}');
    return result.first['count'] as int;
  }

  Future<String?> _deleteOldestNonFavoriteItemInTransaction(
      Transaction txn) async {
    try {
      final oldestItems = await txn.query(
        DatabaseConfig.tableName,
        columns: [DatabaseConfig.columnId],
        where: '${DatabaseConfig.columnIsFavorite} = 0',
        orderBy: '${DatabaseConfig.columnTime} ASC',
        limit: 1,
      );

      if (oldestItems.isNotEmpty) {
        final itemId = oldestItems.first[DatabaseConfig.columnId];
        await txn.delete(
          DatabaseConfig.tableName,
          where: '${DatabaseConfig.columnId} = ?',
          whereArgs: [itemId],
        );
        return itemId as String?;
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to delete oldest non-favorite item', e);
    }
  }

  @override
  Future<int> getCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableName}');
      return result.first['count'] as int;
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
        return bytes / (1024 * 1024); // 转换为 MB
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
    } catch (e) {
      debugPrint('Optimize database failed: $e');
      rethrow;
    }
  }

  /// Closes the database connection
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  /// Deletes the database file
  static Future<void> deleteDatabase() async {
    try {
      final instance = DatabaseHelper.instance;
      await instance.close();

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${DatabaseConfig.dbName}';
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to delete database: $e');
    }
  }
}
