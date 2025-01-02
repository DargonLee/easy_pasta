import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:easy_pasta/db/database_helper.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';

/// 剪贴板数据管理器
class PboardProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  // 状态
  List<ClipboardItemModel> _items = [];
  NSPboardSortType _filterType = NSPboardSortType.all;
  bool _isLoading = false;
  String? _error;

  // Getters
  UnmodifiableListView<ClipboardItemModel> get items =>
      UnmodifiableListView(_items);
  int get count => _items.length;
  NSPboardSortType get filterType => _filterType;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 添加新的剪贴板内容
  Future<void> addItem(ClipboardItemModel model) async {
    try {
      // 先更新UI
      _items.insert(0, model);
      notifyListeners();

      // 后台保存
      await _db.insertPboardItem(model);

      // 检查是否超出最大存储限制
      await _enforceStorageLimit();
    } catch (e) {
      // 回滚UI更新
      _items.removeAt(0);
      _error = '添加失败: $e';
      notifyListeners();
      developer.log('添加剪贴板内容失败: $e');
    }
  }

  /// 获取所有剪贴板内容
  Future<void> loadItems() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _db.getPboardItemList();
      _items =
          result.map((map) => ClipboardItemModel.fromMapObject(map)).toList();
    } catch (e) {
      _error = '加载失败: $e';
      developer.log('获取剪贴板列表失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 设置收藏
  Future<void> toggleFavorite(ClipboardItemModel model) async {
    try {
      final index = _items.indexWhere((item) => item.id == model.id);
      if (index != -1) {
        final newModel = model.copyWith(isFavorite: model.isFavorite ? false : true);
        _items[index] = newModel;
        notifyListeners();

        if (newModel.isFavorite) {
          await _db.cancelFavorite(model);
        } else {
          await _db.setFavorite(model);
        }
      }
    } catch (e) {
      _error = '设置收藏失败: $e';
      developer.log('设置收藏状态失败: $e');
      notifyListeners();
    }
  }

  /// 删除
  Future<void> delete(ClipboardItemModel model) async {
    try {
      _items.removeWhere((item) => item.id == model.id);
      notifyListeners();

      await _db.deletePboardItem(model);
    } catch (e) {
      _error = '删除失败: $e';
      developer.log('删除剪贴板内容失败: $e');
      notifyListeners();
    }
  }

  /// 根据类型筛选内容
  Future<void> filterByType(NSPboardSortType type) async {
    if (_isLoading || type == _filterType) return;

    try {
      _isLoading = true;
      _filterType = type;
      _error = null;
      notifyListeners();

      if (type == NSPboardSortType.all) {
        await loadItems();
        return;
      }

      final result =
          await _db.getPboardItemListByType(type.toString().split('.').last);
      _items =
          result.map((map) => ClipboardItemModel.fromMapObject(map)).toList();
    } catch (e) {
      _error = '筛选失败: $e';
      developer.log('按类型获取剪贴板列表失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 搜索内容
  Future<void> search(String query) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _db.getPboardItemListWithString(query);
      _items =
          result.map((map) => ClipboardItemModel.fromMapObject(map)).toList();
    } catch (e) {
      _error = '搜索失败: $e';
      developer.log('搜索剪贴板内容失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清空历史记录
  Future<void> clearAll() async {
    try {
      await _db.deleteAll();
      _items.clear();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = '清空失败: $e';
      developer.log('清空剪贴板历史失败: $e');
    }
  }

  /// 检查并执行存储限制
  Future<void> _enforceStorageLimit() async {
    final maxCount = await _db.getMaxCount();
    if (count > maxCount) {
      await _db.deleteOldestItem();
      _items.removeLast();
      notifyListeners();
    }
  }
}
