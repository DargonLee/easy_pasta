import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
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
  static const int version = 1;

  // Table columns
  static const String columnId = 'id';
  static const String columnTime = 'time';
  static const String columnType = 'type';
  static const String columnValue = 'value';
  static const String columnIsFavorite = 'isFavorite';
  static const String columnBytes = 'bytes';
}

/// Abstract interface for database operations
abstract class IDatabaseHelper {
  Future<List<Map<String, dynamic>>> getPboardItemListByType(String type);
  Future<List<Map<String, dynamic>>> getPboardItemListWithString(String query);
  Future<List<Map<String, dynamic>>> getFavoritePboardItemList();
  Future<List<Map<String, dynamic>>> getPboardItemList();
  Future<void> setFavorite(ClipboardItemModel model);
  Future<void> cancelFavorite(ClipboardItemModel model);
  Future<void> deletePboardItem(ClipboardItemModel model);
  Future<int> insertPboardItem(ClipboardItemModel model);
  Future<int> getCount();
  Future<int> deleteAll();
}

/// Implementation of database operations for clipboard management
class DatabaseHelper implements IDatabaseHelper {
  // Singleton implementation
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  /// Returns database instance, initializing if necessary
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db ??= await _initDatabase();
    return _db!;
  }

  /// Initializes the database
  Future<Database> _initDatabase() async {
    try {
      sqfliteFfiInit();
      final path = await _getDatabasePath();
      final databaseFactory = databaseFactoryFfi;

      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: DatabaseConfig.version,
          onCreate: _createDb,
          onUpgrade: _onUpgrade,
        ),
      );
    } catch (e) {
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
          ${DatabaseConfig.columnId} INTEGER PRIMARY KEY,
          ${DatabaseConfig.columnTime} TEXT NOT NULL,
          ${DatabaseConfig.columnType} TEXT NOT NULL,
          ${DatabaseConfig.columnValue} TEXT NOT NULL,
          ${DatabaseConfig.columnIsFavorite} INTEGER DEFAULT 0,
          ${DatabaseConfig.columnBytes} BLOB
        )
      ''');

      // Create indexes
      await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_time ON ${DatabaseConfig.tableName} (${DatabaseConfig.columnTime})');
      await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_type ON ${DatabaseConfig.tableName} (${DatabaseConfig.columnType})');
    });
  }

  /// Handles database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add upgrade logic here when needed
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
  Future<int> insertPboardItem(ClipboardItemModel model) async {
    final db = await database;

    return await db.transaction((txn) async {
      try {
        final result =
            await txn.insert(DatabaseConfig.tableName, model.toMap());

        final count = await _getCountInTransaction(txn);
        final maxCount = await getMaxCount();

        if (count > maxCount) {
          await _deleteOldestNonFavoriteItemInTransaction(txn);
        }

        return result;
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

  Future<void> _deleteOldestNonFavoriteItemInTransaction(
      Transaction txn) async {
    final oldestItem = await txn.query(
      DatabaseConfig.tableName,
      columns: [DatabaseConfig.columnId],
      where: '${DatabaseConfig.columnIsFavorite} = 0',
      orderBy: '${DatabaseConfig.columnTime} ASC',
      limit: 1,
    );

    if (oldestItem.isNotEmpty) {
      await txn.delete(
        DatabaseConfig.tableName,
        where: '${DatabaseConfig.columnId} = ?',
        whereArgs: [oldestItem.first[DatabaseConfig.columnId]],
      );
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
