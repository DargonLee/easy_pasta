import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:easy_pasta/db/database_helper.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';

/// 剪贴板数据状态
@immutable
class PboardState {
  final List<ClipboardItemModel> items;
  final NSPboardSortType filterType;
  final bool isLoading;
  final String? error;
  final int maxItems;

  const PboardState({
    required this.items,
    required this.filterType,
    required this.isLoading,
    this.error,
    required this.maxItems,
  });

  // 复制方法
  PboardState copyWith({
    List<ClipboardItemModel>? items,
    NSPboardSortType? filterType,
    bool? isLoading,
    String? error,
    int? maxItems,
  }) {
    return PboardState(
      items: items ?? this.items,
      filterType: filterType ?? this.filterType,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      maxItems: maxItems ?? this.maxItems,
    );
  }
}

/// 剪贴板数据管理器
class PboardProvider extends ChangeNotifier {
  final DatabaseHelper _db;

  // 状态
  PboardState _state;

  // Getters
  UnmodifiableListView<ClipboardItemModel> get items =>
      UnmodifiableListView(_state.items);
  int get count => _state.items.length;
  NSPboardSortType get filterType => _state.filterType;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;

  // 构造函数
  PboardProvider({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance,
        _state = const PboardState(
          items: [],
          filterType: NSPboardSortType.all,
          isLoading: false,
          maxItems: 100, // 默认值，后续会更新
        ) {
    _initializeState();
  }

  // 初始化状态
  Future<void> _initializeState() async {
    final maxCount = await _db.getMaxCount();
    _updateState(_state.copyWith(maxItems: maxCount));
  }

  // 状态更新方法
  void _updateState(PboardState newState) {
    _state = newState;
    notifyListeners();
  }

  // 错误处理方法
  void _handleError(String operation, dynamic error) {
    final errorMessage = '$operation失败: $error';
    developer.log(errorMessage, error: error);
    _updateState(_state.copyWith(
      error: errorMessage,
      isLoading: false,
    ));
  }

  // 加载状态控制
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

  /// 添加新的剪贴板内容
  Future<Result<void>> addItem(ClipboardItemModel model) async {
    try {
      // 更新UI
      final newItems = [model, ..._state.items];
      _updateState(_state.copyWith(items: newItems));

      // 保存到数据库
      await _db.insertPboardItem(model);

      return const Result.success(null);
    } catch (e) {
      // 回滚UI更新
      _updateState(_state.copyWith(items: _state.items));
      _handleError('添加', e);
      return Result.failure(e.toString());
    }
  }

  /// 加载所有剪贴板内容
  Future<Result<void>> loadItems() async {
    return await _withLoading(() async {
      try {
        final result = await _db.getPboardItemList();
        final items =
            result.map((map) => ClipboardItemModel.fromMapObject(map)).toList();

        _updateState(_state.copyWith(
          items: items,
          filterType: NSPboardSortType.all,
        ));

        return const Result.success(null);
      } catch (e) {
        _handleError('加载', e);
        return Result.failure(e.toString());
      }
    });
  }

  /// 切换收藏状态
  Future<Result<void>> toggleFavorite(ClipboardItemModel model) async {
    try {
      final index = _state.items.indexWhere((item) => item.id == model.id);
      if (index == -1) return const Result.failure('项目不存在');

      final newModel = model.copyWith(isFavorite: !model.isFavorite);
      final newItems = List<ClipboardItemModel>.from(_state.items);
      newItems[index] = newModel;

      _updateState(_state.copyWith(items: newItems));

      await _db.setFavorite(newModel);
      return const Result.success(null);
    } catch (e) {
      _handleError('设置收藏', e);
      return Result.failure(e.toString());
    }
  }

  /// 删除项目
  Future<Result<void>> delete(ClipboardItemModel model) async {
    try {
      final newItems =
          _state.items.where((item) => item.id != model.id).toList();
      _updateState(_state.copyWith(items: newItems));

      await _db.deletePboardItem(model);
      return const Result.success(null);
    } catch (e) {
      _handleError('删除', e);
      return Result.failure(e.toString());
    }
  }

  /// 按类型筛选
  Future<Result<void>> filterByType(NSPboardSortType type) async {
    if (type == _state.filterType) return const Result.success(null);

    return await _withLoading(() async {
      try {
        List<Map<String, dynamic>> result;

        switch (type) {
          case NSPboardSortType.all:
            result = await _db.getPboardItemList();
          case NSPboardSortType.favorite:
            result = await _db.getFavoritePboardItemList();
            break;
          default:
            result = await _db
                .getPboardItemListByType(type.toString().split('.').last);
        }

        final items =
            result.map((map) => ClipboardItemModel.fromMapObject(map)).toList();

        _updateState(_state.copyWith(
          items: items,
          filterType: type,
        ));

        return const Result.success(null);
      } catch (e) {
        _handleError('筛选', e);
        return Result.failure(e.toString());
      }
    });
  }

  /// 搜索内容
  Future<Result<void>> search(String query) async {
    query = query.trim();
    if (query.isEmpty) return await loadItems();

    return await _withLoading(() async {
      try {
        final result = await _db.getPboardItemListWithString(query);
        final items =
            result.map((map) => ClipboardItemModel.fromMapObject(map)).toList();

        _updateState(_state.copyWith(
          items: items,
          error: items.isEmpty ? '未找到相关内容' : null,
        ));

        return const Result.success(null);
      } catch (e) {
        _handleError('搜索', e);
        return Result.failure(e.toString());
      }
    });
  }

  /// 清空所有内容
  Future<Result<void>> clearAll() async {
    try {
      await _db.deleteAll();
      _updateState(_state.copyWith(
        items: [],
        error: null,
      ));
      return const Result.success(null);
    } catch (e) {
      _handleError('清空', e);
      return Result.failure(e.toString());
    }
  }

  @override
  void dispose() {
    // 清理资源
    super.dispose();
  }
}

// 新增: 用于处理操作结果的工具类
class Result<T> {
  final T? data;
  final String? error;

  const Result.success(this.data) : error = null;
  const Result.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}
