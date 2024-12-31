import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/db/shared_preference_helper.dart';

/// 数据库帮助类,用于管理剪贴板数据的存储和查询
class DatabaseHelper {
  // 单例模式
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  // 数据库相关常量
  static const String _dbName = 'pboards.db';
  static const String _tableName = 'pboards';
  static const int _version = 1;

  // 表字段名
  static const String columnId = 'id';
  static const String columnTime = 'time';
  static const String columnType = 'type';
  static const String columnValue = 'value';
  static const String columnTiff = 'tiffbytes';

  Database? _db;

  /// 获取数据库实例,如果未初始化则先初始化
  Future<Database> get database async => _db ??= await _initDatabase();

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}$_dbName';
    return openDatabase(
      path,
      version: _version,
      onCreate: _createDb,
    );
  }

  /// 创建数据表
  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName(
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTime TEXT NOT NULL,
        $columnType TEXT NOT NULL,
        $columnValue TEXT,
        $columnTiff BLOB,
      )
    ''');
  }

  /// 获取最大存储数量
  Future<int> getMaxCount() async {
    final prefs = await SharedPreferenceHelper.instance;
    return prefs.getMaxItemStore();
  }

  /// 根据类型查询剪贴板内容
  Future<List<Map<String, dynamic>>> getPboardItemListByType(String type) async {
    final db = await database;
    return db.query(
      _tableName,
      where: '$columnType = ?',
      whereArgs: [type],
      orderBy: '$columnTime DESC',
    );
  }

  /// 根据关键字搜索剪贴板内容
  Future<List<Map<String, dynamic>>> getPboardItemListWithString(String query) async {
    final db = await database;
    return db.query(
      _tableName,
      where: '$columnValue LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: '$columnTime DESC',
    );
  }

  /// 获取所有剪贴板内容
  Future<List<Map<String, dynamic>>> getPboardItemList() async {
    final db = await database;
    return db.query(
      _tableName,
      orderBy: '$columnTime DESC',
    );
  }

  /// 插入新的剪贴板内容
  /// 如果超出最大存储限制,会自动删除最早的记录
  Future<int> insertPboardItem(NSPboardTypeModel model) async {
    final db = await database;
    
    // 开启事务以确保数据一致性
    return await db.transaction((txn) async {
      final result = await txn.insert(_tableName, model.toMap());
      
      final count = await getCount();
      final maxCount = await getMaxCount();
      if (count > maxCount) {
        await deleteOldestItem();
      }
      
      return result;
    });
  }

  /// 获取记录总数
  Future<int> getCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return result.first['count'] as int;
  }

  /// 删除最早的记录
  Future<int> deleteOldestItem() async {
    final db = await database;
    
    // 使用事务确保操作的原子性
    return await db.transaction((txn) async {
      final oldestItem = await txn.query(
        _tableName,
        columns: [columnId],
        orderBy: '$columnTime ASC',
        limit: 1,
      );
      
      if (oldestItem.isEmpty) return 0;
      
      return await txn.delete(
        _tableName,
        where: '$columnId = ?',
        whereArgs: [oldestItem.first[columnId]],
      );
    });
  }

  /// 删除所有记录
  Future<int> deleteAll() async {
    final db = await database;
    return db.delete(_tableName);
  }
}
