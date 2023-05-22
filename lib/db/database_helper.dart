import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class  DatabaseHelper {
  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static late final DatabaseHelper _instance = DatabaseHelper._internal();

  static late Database _database;
  Future<Database> get database async {
    if (_database == null) {
      Directory directory = await getApplicationDocumentsDirectory();
      String path = '${directory.path}${_dbName}';
      _database = await openDatabase(path, version: 1, onCreate: _createDb);
    }
    return _database;
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute('CREATE TABLE IF NOT EXISTS $_pboardTable(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, age INTEGER)');
  }

  String _dbName = "pboards.db";
  String _pboardTable = "pboards";

  // Public Methods


}