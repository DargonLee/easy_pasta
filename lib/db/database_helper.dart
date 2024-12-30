import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/db/shared_preference_helper.dart';

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
  static const String columnPlainText = 'plaintext';
  static const String columnJson = 'jsonstr';
  static const String columnTiff = 'tiffbytes';
  static const String columnAppName = 'appname';
  static const String columnAppId = 'appid';
  static const String columnAppIcon = 'appicon';

  Database? _db;

  // 获取数据库实例
  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}$_dbName';
    return openDatabase(
      path,
      version: _version,
      onCreate: _createDb,
    );
  }

  // 创建数据表
  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName(
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTime TEXT,
        $columnType TEXT,
        $columnValue TEXT,
        $columnPlainText TEXT,
        $columnJson TEXT,
        $columnTiff BLOB,
        $columnAppName TEXT,
        $columnAppId TEXT,
        $columnAppIcon BLOB
      )
    ''');
  }

  // 获取最大存储数量
  Future<int> getMaxCount() async => 
      await SharedPreferenceHelper.getMaxItemStoreKey();

  // 根据类型查询剪贴板内容
  Future<List<Map<String, dynamic>>> getPboardItemListByType(String type) async {
    final db = await database;
    return db.query(
      _tableName,
      where: '$columnType = ?',
      whereArgs: [type],
      orderBy: '$columnTime DESC'
    );
  }

  // 查询操作
  Future<List<Map<String, dynamic>>> getPboardItemListWithString(String query) async {
    final db = await database;
    return db.rawQuery(
      'SELECT * FROM $_tableName WHERE $columnValue LIKE ?',
      ['%$query%'],
    );
  }

  Future<List<Map<String, dynamic>>> getPboardItemList() async {
    final db = await database;
    return db.query(_tableName);
  }

  // 插入操作
  Future<int> insertPboardItem(NSPboardTypeModel model) async {
    final db = await database;
    final result = await db.insert(_tableName, model.toMap());
    
    final count = await getCount();
    final maxCount = await getMaxCount();
    if (count > maxCount) {
      await deleteOldestItem();
    }
    
    return result;
  }

  // 计数操作
  Future<int> getCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 删除操作最早的记录
  Future<int> deleteOldestItem() async {
    final db = await database;
    final oldestItem = await db.rawQuery(
      'SELECT * FROM $_tableName ORDER BY $columnTime ASC LIMIT 1'
    );
    
    if (oldestItem.isEmpty) return 0;
    
    final id = oldestItem.first[columnId];
    return await db.delete(
      _tableName,
      where: '$columnId = ?', 
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await database;
    return db.delete(_tableName);
  }
}

// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:easy_pasta/model/pasteboard_model.dart';
// import 'package:easy_pasta/db/constanst_helper.dart';

// class DatabaseHelper {
//   DatabaseHelper._internal();
//   factory DatabaseHelper() => _instance;
//   static late final DatabaseHelper _instance = DatabaseHelper._internal();

//   Future<int> MAX_COUNT() async {
//     int result = await SharedPreferenceHelper.getMaxItemStoreKey();
//     return result;
//   }

//   static Database? _database;
//   Future<Database> get database async {
//     if (_database == null) {
//       Directory directory = await getApplicationDocumentsDirectory();
//       String path = '${directory.path}${_dbName}';
//       print("db path is $path");
//       _database = await openDatabase(path, version: 1, onCreate: _createDb);
//     }
//     return _database!;
//   }

//   void _createDb(Database db, int newVersion) async {
//     await db.execute(
//         'CREATE TABLE IF NOT EXISTS $_pboardTable($colId INTEGER PRIMARY KEY AUTOINCREMENT, '
//             '$colTime TEXT, $colType TEXT, $colValue TEXT, $colJson TEXT, '
//             '$colTiff BLOB, $colAppName TEXT, $colAppId TEXT, $colAppIcon BLOB)');
//   }

//   String _dbName = "pboards.db";
//   String _pboardTable = "pboards";

//   String colId = 'id';
//   String colTime = 'time';
//   String colType = 'type';
//   String colValue = 'value';
//   String colJson = 'jsonstr';
//   String colTiff = 'tiffbytes';
//   String colAppName = 'appname';
//   String colAppId = 'appid';
//   String colAppIcon = 'appicon';

//   // Public Methods
//   Future<List<Map>> getPboardItemListWithString(String string) async {
//     Database db = await database;
//     String sql = 'SELECT * FROM $_pboardTable WHERE value LIKE ?';
//     var result = await db.rawQuery(sql, ['%$string%']);
//     return result;
//   }

//   Future<List<Map>> getPboardItemList() async {
//     Database db = await database;
//     var result = await db.query(_pboardTable);
//     return result;
//   }

//   Future<int> insertPboardItem(NSPboardTypeModel model) async {
//     Database db = await database;
//     var result = await db.insert(_pboardTable, model.toMap());
//     int count = await getCount();
//     int MAXCOUNT = await MAX_COUNT();
//     if (count > MAXCOUNT) {
//       deleteLastRaw();
//     }
//     return result;
//   }

//   Future<int> getCount() async {
//     Database db = await database;
//     List<Map<String, dynamic>> list = await db.rawQuery('SELECT COUNT (*) FROM $_pboardTable');
//     int result = Sqflite.firstIntValue(list) ?? 0;
//     return result;
//   }

//   Future<int> deleteLastRaw() async {
//     Database db = await database;
//     List<Map<String, dynamic>> list = await db.rawQuery('SELECT * FROM $_pboardTable ORDER BY $colId ASC LIMIT 1');
//     String id = list.first['id'].toString();
//     int result = await db.rawDelete('DELETE FROM $_pboardTable WHERE $colId = $id');
//     return result;
//   }

//   Future<int> deleteAll() async {
//     Database db = await database;
//     int result = await db.delete(_pboardTable);
//     return result;
//   }
// }
