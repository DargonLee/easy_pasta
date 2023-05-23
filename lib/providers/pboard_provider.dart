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
    var result = await _databaseHelper.insertPboardItem(model);
    if (result != 0) {
      print('addPboardModel Success');
    } else {
      print('addPboardModel Failed');
    }

    getPboardList();
  }

  void getPboardList() async {
    _pboards.clear();

    List<Map> result = await _databaseHelper.getPboardItemList();
    if (result.length != 0) {
      _count = await _databaseHelper.getCount();

      for (Map map in result) {
        final NSPboardTypeModel model = NSPboardTypeModel.fromMapObject(map as Map<String, dynamic>);
        _pboards.add(model);
      }
    }

    notifyListeners();
  }
}
