import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:easy_pasta/db/database_helper.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';
import 'package:easy_pasta/model/time_filter.dart';

@immutable
class PboardState {
  final List<ClipboardItemModel> allItems; // 存储所有项目
  final List<ClipboardItemModel> filteredItems; // 存储过滤后的项目
  final NSPboardSortType filterType;
  final bool isLoading;
  final String? error;
  final int maxItems;
  final String searchQuery;
  final int currentPage;
  final bool hasMore;
  final int pageSize;
  final Map<String, List<ClipboardItemModel>> groupedItems; // 新增预计算分组

  const PboardState({
    required this.allItems,
    required this.filteredItems,
    required this.filterType,
    required this.isLoading,
    this.error,
    required this.maxItems,
    this.searchQuery = '',
    this.currentPage = 0,
    this.hasMore = true,
    this.pageSize = 50,
    this.timeFilter = TimeFilter.all,
    this.groupedItems = const {},
  });

  PboardState copyWith({
    List<ClipboardItemModel>? allItems,
    List<ClipboardItemModel>? filteredItems,
    NSPboardSortType? filterType,
    bool? isLoading,
    String? error,
    int? maxItems,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
    int? pageSize,
    TimeFilter? timeFilter,
    Map<String, List<ClipboardItemModel>>? groupedItems,
  }) {
    return PboardState(
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      filterType: filterType ?? this.filterType,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      maxItems: maxItems ?? this.maxItems,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      pageSize: pageSize ?? this.pageSize,
      timeFilter: timeFilter ?? this.timeFilter,
      groupedItems: groupedItems ?? this.groupedItems,
    );
  }

  final TimeFilter timeFilter;
}

class PboardProvider extends ChangeNotifier {
  final DatabaseHelper _db;

  PboardState _state;

  // Getters
  UnmodifiableListView<ClipboardItemModel> get items =>
      UnmodifiableListView(_state.filteredItems);
  Map<String, List<ClipboardItemModel>> get groupedItems => _state.groupedItems;
  int get count => _state.filteredItems.length;
  NSPboardSortType get filterType => _state.filterType;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;
  String get searchQuery => _state.searchQuery;
  TimeFilter get timeFilter => _state.timeFilter;

  bool _isInitialized = false;

  PboardProvider({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance,
        _state = const PboardState(
          allItems: [],
          filteredItems: [],
          filterType: NSPboardSortType.all,
          isLoading: false,
          maxItems: 50,
        ) {
    // 延迟初始化，避免与其他服务冲突
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isInitialized) {
        _initializeState();
      }
    });
  }

  Future<void> _initializeState() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final maxCount = await _db.getMaxCount();
      _updateState(_state.copyWith(maxItems: maxCount));

      // 使用分页加载初始数据
      final range = _state.timeFilter.range;
      final result = await _db.getPboardItemListPaginated(
        limit: _state.pageSize,
        offset: 0,
        startTime: range.start,
        endTime: range.end,
      );
      final items =
          result.map((map) => ClipboardItemModel.fromMapObject(map)).toList();

      _updateState(_state.copyWith(
        allItems: items,
        filteredItems: items,
        filterType: NSPboardSortType.all,
        searchQuery: '',
        currentPage: 0,
        hasMore: items.length >= _state.pageSize,
      ));
    } catch (e) {
      developer.log('初始化失败: $e', error: e);
      _isInitialized = false; // 允许重试
    }
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
    if (_state.isLoading) {
      developer.log('操作已在进行中，等待完成...');
      // 等待一小段时间后重试，而不是直接抛出错误
      await Future.delayed(const Duration(milliseconds: 100));
      if (_state.isLoading) {
        developer.log('操作仍在进行中，跳过此次请求');
        throw '操作正在进行中';
      }
    }

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
    bool hasSearch = _state.searchQuery.isNotEmpty;
    bool hasFilter = _state.filterType != NSPboardSortType.all;

    // 应用类型过滤
    if (hasFilter) {
      if (_state.filterType == NSPboardSortType.favorite) {
        filteredItems = filteredItems.where((item) => item.isFavorite).toList();
      } else {
        final typeStr = _state.filterType.toString().split('.').last;
        filteredItems = filteredItems
            .where((item) => item.ptype.toString().split('.').last == typeStr)
            .toList();
      }
    }

    // 应用搜索过滤与权重排序
    if (hasSearch) {
      final query = _state.searchQuery.toLowerCase();
      filteredItems = filteredItems.where((item) {
        return item.pvalue.toLowerCase().contains(query);
      }).toList();

      // 精准/相关度排序:
      // 1. 如果搜索项以搜索词开头, 权重最高 (Prefix match)
      // 2. 否则按时间排序
      filteredItems.sort((a, b) {
        final aVal = a.pvalue.toLowerCase();
        final bVal = b.pvalue.toLowerCase();
        final aStarts = aVal.startsWith(query);
        final bStarts = bVal.startsWith(query);

        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;

        // 如果都是前缀匹配或都不是，则保持时间倒序
        return b.time.compareTo(a.time);
      });
    }

    // 区分两种空状态：
    // 1. 有搜索条件但无结果 -> error = '未找到相关内容'
    // 2. 无数据或筛选后无数据 -> error = null（显示分类空状态）
    String? errorMessage;
    if (filteredItems.isEmpty && hasSearch) {
      errorMessage = '未找到相关内容';
    }

    _updateState(_state.copyWith(
      filteredItems: filteredItems,
      groupedItems: _performGrouping(filteredItems), // 触发预计算
      error: errorMessage,
    ));
  }

  Map<String, List<ClipboardItemModel>> _performGrouping(
      List<ClipboardItemModel> items) {
    final groups = <String, List<ClipboardItemModel>>{};
    for (final item in items) {
      try {
        final date = DateTime.parse(item.time);
        final header = TimeFilter.formatDateHeader(date);
        groups.putIfAbsent(header, () => []).add(item);
      } catch (e) {
        groups.putIfAbsent('未知时间', () => []).add(item);
      }
    }
    return groups;
  }

  Future<Result<void>> addItem(ClipboardItemModel model) async {
    try {
      // 检查重复
      final duplicate = await _db.checkDuplicate(model);
      if (duplicate != null) {
        // 更新现有项的时间戳
        final updatedModel =
            duplicate.copyWith(time: DateTime.now().toString());
        await _db.setFavorite(updatedModel); // 使用 setFavorite 来更新时间戳

        // 更新内存中的数据
        final newAllItems = _state.allItems.map((item) {
          if (item.id == duplicate.id) {
            return updatedModel;
          }
          return item;
        }).toList();

        // 重新排序,将更新的项移到最前面
        newAllItems.removeWhere((item) => item.id == duplicate.id);
        newAllItems.insert(0, updatedModel);

        _updateState(_state.copyWith(allItems: newAllItems));
        _applyFiltersAndSearch();

        return const Result.success(null);
      }

      // 更新内存中的数据（预先插入到列表顶部）
      List<ClipboardItemModel> nextAllItems = [model, ..._state.allItems];

      // 保存到数据库，并获取由于达到上限而被删除的非收藏项 ID
      final deletedItemId = await _db.insertPboardItem(model);

      if (deletedItemId != null) {
        nextAllItems =
            nextAllItems.where((item) => item.id != deletedItemId).toList();
      }

      _updateState(_state.copyWith(allItems: nextAllItems));
      _applyFiltersAndSearch();

      return const Result.success(null);
    } catch (e) {
      _handleError('添加', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> loadItems() async {
    return await _withLoading(() async {
      try {
        final range = _state.timeFilter.range;
        // Use pagination even for full load to keep it consistent
        final result = await _db.getPboardItemListPaginated(
          limit: _state.pageSize,
          offset: 0,
          startTime: range.start,
          endTime: range.end,
        );
        final items =
            result.map((map) => ClipboardItemModel.fromMapObject(map)).toList();

        _updateState(_state.copyWith(
          allItems: items,
          filteredItems: items,
          currentPage: 0,
          hasMore: items.length >= _state.pageSize,
        ));

        _applyFiltersAndSearch();

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

  /// 切换时间过滤
  Future<void> filterByTime(TimeFilter filter) async {
    if (_state.timeFilter == filter) return;

    _updateState(_state.copyWith(
      timeFilter: filter,
      currentPage: 0,
    ));

    await loadItems();
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
        currentPage: 0,
        hasMore: false,
      ));
      return const Result.success(null);
    } catch (e) {
      _handleError('清空', e);
      return Result.failure(e.toString());
    }
  }

  // 加载更多数据(懒加载)
  Future<Result<void>> loadMore() async {
    if (!_state.hasMore || _state.isLoading) {
      return const Result.success(null);
    }

    try {
      final nextPage = _state.currentPage + 1;
      final offset = nextPage * _state.pageSize;
      final range = _state.timeFilter.range;

      final result = await _db.getPboardItemListPaginated(
        limit: _state.pageSize,
        offset: offset,
        startTime: range.start,
        endTime: range.end,
      );

      if (result.isEmpty) {
        _updateState(_state.copyWith(hasMore: false));
        return const Result.success(null);
      }

      final newItems =
          result.map((map) => ClipboardItemModel.fromMapObject(map)).toList();

      final updatedAllItems = [..._state.allItems, ...newItems];

      _updateState(_state.copyWith(
        allItems: updatedAllItems,
        currentPage: nextPage,
        hasMore: newItems.length >= _state.pageSize,
      ));

      _applyFiltersAndSearch();

      return const Result.success(null);
    } catch (e) {
      _handleError('加载更多', e);
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
