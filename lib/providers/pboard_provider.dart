import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:easy_pasta/db/database_helper.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';

@immutable
class PboardState {
  final List<ClipboardItemModel> allItems; // 存储所有项目
  final List<ClipboardItemModel> filteredItems; // 存储过滤后的项目
  final NSPboardSortType filterType;
  final bool isLoading;
  final String? error;
  final int maxItems;
  final String searchQuery;

  const PboardState({
    required this.allItems,
    required this.filteredItems,
    required this.filterType,
    required this.isLoading,
    this.error,
    required this.maxItems,
    this.searchQuery = '',
  });

  PboardState copyWith({
    List<ClipboardItemModel>? allItems,
    List<ClipboardItemModel>? filteredItems,
    NSPboardSortType? filterType,
    bool? isLoading,
    String? error,
    int? maxItems,
    String? searchQuery,
  }) {
    return PboardState(
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      filterType: filterType ?? this.filterType,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      maxItems: maxItems ?? this.maxItems,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class PboardProvider extends ChangeNotifier {
  final DatabaseHelper _db;

  PboardState _state;

  // Getters
  UnmodifiableListView<ClipboardItemModel> get items =>
      UnmodifiableListView(_state.filteredItems);
  int get count => _state.filteredItems.length;
  NSPboardSortType get filterType => _state.filterType;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;
  String get searchQuery => _state.searchQuery;

  PboardProvider({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance,
        _state = const PboardState(
          allItems: [],
          filteredItems: [],
          filterType: NSPboardSortType.all,
          isLoading: false,
          maxItems: 50,
        ) {
    _initializeState();
  }

  Future<void> _initializeState() async {
    final maxCount = await _db.getMaxCount();
    _updateState(_state.copyWith(maxItems: maxCount));
    await loadItems();
  }

  void _updateState(PboardState newState) {
    _state = newState;
    notifyListeners();
  }

  void _handleError(String operation, dynamic error) {
    final errorMessage = '$operation失败: $error';
    developer.log(errorMessage, error: error);
    _updateState(_state.copyWith(
      error: errorMessage,
      isLoading: false,
    ));
  }

  Future<T> _withLoading<T>(Future<T> Function() operation) async {
    if (_state.isLoading) return Future.error('操作正在进行中');

    _updateState(_state.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      final result = await operation();
      _updateState(_state.copyWith(isLoading: false));
      return result;
    } catch (e) {
      _updateState(_state.copyWith(isLoading: false));
      rethrow;
    }
  }

  // 应用过滤和搜索
  void _applyFiltersAndSearch() {
    var filteredItems = List<ClipboardItemModel>.from(_state.allItems);

    // 应用类型过滤
    if (_state.filterType != NSPboardSortType.all) {
      if (_state.filterType == NSPboardSortType.favorite) {
        filteredItems = filteredItems.where((item) => item.isFavorite).toList();
      } else {
        final typeStr = _state.filterType.toString().split('.').last;
        filteredItems = filteredItems
            .where((item) => item.ptype.toString().split('.').last == typeStr)
            .toList();
      }
    }

    // 应用搜索过滤
    if (_state.searchQuery.isNotEmpty) {
      filteredItems = filteredItems
          .where((item) => item.pvalue
              .toLowerCase()
              .contains(_state.searchQuery.toLowerCase()))
          .toList();
    }

    _updateState(_state.copyWith(
      filteredItems: filteredItems,
      error: filteredItems.isEmpty ? '未找到相关内容' : null,
    ));
  }

  Future<Result<void>> addItem(ClipboardItemModel model) async {
    try {
      // 更新内存中的数据
      final newAllItems = [model, ..._state.allItems];
      _updateState(_state.copyWith(
        allItems: newAllItems,
      ));
      _applyFiltersAndSearch();

      // 保存到数据库
      final deletedItemId = await _db.insertPboardItem(model);
      if (deletedItemId != 0) {
        final updatedAllItems =
            _state.allItems.where((item) => item.id != deletedItemId).toList();
        _updateState(_state.copyWith(allItems: updatedAllItems));
        _applyFiltersAndSearch();
      }

      return const Result.success(null);
    } catch (e) {
      _handleError('添加', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> loadItems() async {
    return await _withLoading(() async {
      try {
        final result = await _db.getPboardItemList();
        final items =
            result.map((map) => ClipboardItemModel.fromMapObject(map)).toList();

        _updateState(_state.copyWith(
          allItems: items,
          filteredItems: items,
          filterType: NSPboardSortType.all,
          searchQuery: '',
        ));

        return const Result.success(null);
      } catch (e) {
        _handleError('加载', e);
        return Result.failure(e.toString());
      }
    });
  }

  Future<Result<void>> toggleFavorite(ClipboardItemModel model) async {
    try {
      final index = _state.allItems.indexWhere((item) => item.id == model.id);
      if (index == -1) return const Result.failure('项目不存在');

      final newModel = model.copyWith(isFavorite: !model.isFavorite);
      final newAllItems = List<ClipboardItemModel>.from(_state.allItems);
      newAllItems[index] = newModel;

      _updateState(_state.copyWith(allItems: newAllItems));
      _applyFiltersAndSearch();

      await _db.setFavorite(newModel);
      return const Result.success(null);
    } catch (e) {
      _handleError('设置收藏', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> delete(ClipboardItemModel model) async {
    try {
      final newAllItems =
          _state.allItems.where((item) => item.id != model.id).toList();

      _updateState(_state.copyWith(allItems: newAllItems));
      _applyFiltersAndSearch();

      await _db.deletePboardItem(model);
      return const Result.success(null);
    } catch (e) {
      _handleError('删除', e);
      return Result.failure(e.toString());
    }
  }

  // 优化后的filterByType方法 - 只在内存中操作
  Future<Result<void>> filterByType(NSPboardSortType type) async {
    if (type == _state.filterType) return const Result.success(null);

    try {
      _updateState(_state.copyWith(filterType: type));
      _applyFiltersAndSearch();
      return const Result.success(null);
    } catch (e) {
      _handleError('筛选', e);
      return Result.failure(e.toString());
    }
  }

  // 优化后的search方法 - 只在内存中操作
  Future<Result<void>> search(String query) async {
    query = query.trim();

    try {
      _updateState(_state.copyWith(searchQuery: query));
      _applyFiltersAndSearch();
      return const Result.success(null);
    } catch (e) {
      _handleError('搜索', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> clearAll() async {
    try {
      await _db.deleteAll();
      _updateState(_state.copyWith(
        allItems: [],
        filteredItems: [],
        error: null,
        searchQuery: '',
      ));
      return const Result.success(null);
    } catch (e) {
      _handleError('清空', e);
      return Result.failure(e.toString());
    }
  }

}

class Result<T> {
  final T? data;
  final String? error;

  const Result.success(this.data) : error = null;
  const Result.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}
