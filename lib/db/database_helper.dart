import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/db/constanst_helper.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static late final DatabaseHelper _instance = DatabaseHelper._internal();

  Future<int> MAX_COUNT() async {
     int result = await SharedPreferenceHelper.getMaxItemStoreKey();
     return result;
  }

  static Database? _database;
  Future<Database> get database async {
    if (_database == null) {
      Directory directory = await getApplicationDocumentsDirectory();
      String path = '${directory.path}${_dbName}';
      print("db path is $path");
      _database = await openDatabase(path, version: 1, onCreate: _createDb);
    }
    return _database!;
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute('CREATE TABLE IF NOT EXISTS $_pboardTable($colId INTEGER PRIMARY KEY AUTOINCREMENT, $colTime TEXT, $colType TEXT, $colValue TEXT, $colJson TEXT, $colTiff BLOB)');
  }

  String _dbName = "pboards.db";
  String _pboardTable = "pboards";

  String colId = 'id';
  String colTime = 'time';
  String colType = 'type';
  String colValue = 'value';
  String colJson = 'jsonstr';
  String colTiff = 'tiffbytes';

  // Public Methods
  Future<List<Map>> getPboardItemListWithString(String string) async {
    Database db = await database;
    String sql = 'SELECT * FROM $_pboardTable WHERE value LIKE ?';
    var result = await db.rawQuery(sql, ['%$string%']);
    return result;
  }

  Future<List<Map>> getPboardItemList() async {
    Database db = await database;
    var result = await db.query(_pboardTable);
    return result;
  }

  Future<int> insertPboardItem(NSPboardTypeModel model) async {
    Database db = await database;
    var result = await db.insert(_pboardTable, model.toMap());
    int count = await getCount();
    int MAXCOUNT = await MAX_COUNT();
    if (count > MAXCOUNT) {
      deleteLastRaw();
    }
    return result;
  }

  Future<int> getCount() async {
    Database db = await database;
    List<Map<String, dynamic>> list = await db.rawQuery('SELECT COUNT (*) FROM $_pboardTable');
    int result = Sqflite.firstIntValue(list) ?? 0;
    return result;
  }

  Future<int> deleteLastRaw() async {
    Database db = await database;
    List<Map<String, dynamic>> list = await db.rawQuery('SELECT * FROM $_pboardTable ORDER BY $colId ASC LIMIT 1');
    String id = list.first['id'].toString();
    int result = await db.rawDelete('DELETE FROM $_pboardTable WHERE $colId = $id');
    return result;
  }

  Future<int> deleteAll() async {
    Database db = await database;
    int result = await db.delete(_pboardTable);
    return result;
  }
}
