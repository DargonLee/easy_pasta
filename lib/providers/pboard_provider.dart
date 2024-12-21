import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:easy_pasta/db/database_helper.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/pasteboard_type.dart';

/// 剪贴板数据管理器
class PboardProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<NSPboardTypeModel> _pboards = [];
  int _count = 0;
  NSPboardSortType _queryType = NSPboardSortType.allType;

  // Getters
  int get count => _count;
  NSPboardSortType get queryType => _queryType;
  UnmodifiableListView<NSPboardTypeModel> get pboards =>
      UnmodifiableListView(_pboards);

  /// 添加新的剪贴板内容
  Future<void> addPboardModel(NSPboardTypeModel model) async {
    try {
      _pboards.insert(0, model);
      _count++;
      notifyListeners();

      await _databaseHelper.insertPboardItem(model);
      final maxCount = await _databaseHelper.getMaxCount();
      if (_count > maxCount) {
        await _databaseHelper.deleteOldestItem();
        _pboards.removeLast();
        _count--;
        notifyListeners();
      }
    } catch (e) {
      _pboards.removeAt(0);
      _count--;
      notifyListeners();
      developer.log('添加剪贴板内容失败: $e');
    }
  }

  /// 获取所有剪贴板内容
  Future<void> getPboardList() async {
    try {
      _pboards.clear();
      final result = await _databaseHelper.getPboardItemList();

      if (result.isNotEmpty) {
        _count = await _databaseHelper.getCount();
        _pboards =
            result.map((map) => NSPboardTypeModel.fromMapObject(map)).toList();
        notifyListeners();
      }
    } catch (e) {
      developer.log('获取剪贴板列表失败: $e');
    }
  }

  /// 根据类型筛选剪贴板内容
  Future<void> getPboardListByType(NSPboardSortType type) async {
    try {
      _queryType = type;
      _pboards.clear();

      if (type == NSPboardSortType.allType) {
        await getPboardList();
        return;
      }

      final result = await _databaseHelper
          .getPboardItemListByType(type.toString().split('.').last);

      if (result.isNotEmpty) {
        _count = result.length;
        _pboards =
            result.map((map) => NSPboardTypeModel.fromMapObject(map)).toList();
      }

      notifyListeners();
    } catch (e) {
      developer.log('按类型获取剪贴板列表失败: $e');
    }
  }

  /// 搜索剪贴板内容
  Future<void> getPboardListWithString(String query) async {
    try {
      _pboards.clear();
      final result = await _databaseHelper.getPboardItemListWithString(query);

      if (result.isNotEmpty) {
        _count = result.length;
        _pboards =
            result.map((map) => NSPboardTypeModel.fromMapObject(map)).toList();
      }

      notifyListeners();
    } catch (e) {
      developer.log('搜索剪贴板内容失败: $e');
    }
  }

  /// 清空剪贴板历史
  Future<void> removePboardList() async {
    try {
      await _databaseHelper.deleteAll();
      _pboards.clear();
      _count = 0;
      notifyListeners();
    } catch (e) {
      developer.log('清空剪贴板历史失败: $e');
    }
  }
}
