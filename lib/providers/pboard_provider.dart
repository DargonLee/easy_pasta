import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:easy_pasta/db/database_helper.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

class PboardProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<NSPboardTypeModel> _pboards = [];
  int _count = 0;

  int get count => _count;
  UnmodifiableListView<NSPboardTypeModel> get pboards => UnmodifiableListView(_pboards as List<NSPboardTypeModel>);

  void addPboardModel(NSPboardTypeModel model) async {
    await _databaseHelper.insertPboardItem(model);
    getPboardList();
  }

  void getPboardList() async {
    _pboards.clear();

    List<Map> result = await _databaseHelper.getPboardItemList();
    if (result.isNotEmpty) {
      _count = await _databaseHelper.getCount();

      for (Map map in result) {
        final NSPboardTypeModel model = NSPboardTypeModel.fromMapObject(map as Map<String, dynamic>);
        _pboards.add(model);
      }
    }

    notifyListeners();
  }

  void getPboardListWithString(String string) async {
    _pboards.clear();

    List<Map> result = await _databaseHelper.getPboardItemListWithString(string);
    if (result.isNotEmpty) {
      _count = result.length;
      for (Map map in result) {
        final NSPboardTypeModel model = NSPboardTypeModel.fromMapObject(map as Map<String, dynamic>);
        _pboards.add(model);
      }
    }

    notifyListeners();
  }

  void removePboardList() async {
    _pboards.clear();
    _count = 0;
    await _databaseHelper.deleteAll();
    notifyListeners();
  }
}
