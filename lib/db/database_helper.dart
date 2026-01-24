import 'dart:io';
import 'dart:developer' as developer;
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
  static const int version = 3;

  // Table columns
  static const String columnId = 'id';
  static const String columnTime = 'time';
  static const String columnType = 'type';
  static const String columnValue = 'value';
  static const String columnIsFavorite = 'isFavorite';
  static const String columnBytes = 'bytes';
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
  Future<int> getCount();
  Future<int> deleteAll();
}

/// Implementation of database operations for clipboard management
class DatabaseHelper implements IDatabaseHelper {
  // Singleton implementation
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;
  bool _isInitializing = false;

  /// Returns database instance, initializing if necessary
  Future<Database> get database async {
    if (_db != null) return _db!;

    // 如果正在初始化，等待完成
    while (_isInitializing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // 再次检查，可能已初始化完成
    if (_db != null) return _db!;

    _db ??= await _initDatabase();
    return _db!;
  }

  /// Initializes the database
  Future<Database> _initDatabase() async {
    if (_isInitializing) {
      developer.log('数据库正在初始化中...');
      throw DatabaseException('数据库正在初始化中');
    }

    _isInitializing = true;

    try {
      sqfliteFfiInit();
      final path = await _getDatabasePath();
      developer.log('db path: $path');
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
    final db = await database;
    final maxCount = await getMaxCount();
    return await db.transaction((txn) async {
      try {
        await txn.insert(DatabaseConfig.tableName, model.toMap());
        final count = await _getCountInTransaction(txn);

        if (count > maxCount) {
          final itemId = await _deleteOldestNonFavoriteItemInTransaction(txn);
          if (itemId != null) {
            return itemId;
          }
        }
        return null;
      } catch (e) {
        throw DatabaseException('Failed to insert item', e);
      }
    });
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
      throw DatabaseException('Failed to delete database', e);
    }
  }
}
