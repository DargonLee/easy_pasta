import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';
import 'package:easy_pasta/model/time_filter.dart';
import 'package:easy_pasta/service/clipboard_service.dart';
import 'package:easy_pasta/core/sync_portal_service.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:uuid/uuid.dart';

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
  final ClipboardService _service;

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

  PboardProvider({ClipboardService? service})
      : _service = service ?? ClipboardService(),
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

    // 监听移动端同步推送
    _mobileUploadSubscription =
        SyncPortalService.instance.receivedItemsStream.listen((text) {
      _handleMobileUpload(text);
    });
  }

  StreamSubscription? _mobileUploadSubscription;

  @override
  void dispose() {
    _mobileUploadSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleMobileUpload(String text) async {
    final model = ClipboardItemModel(
      id: const Uuid().v4(),
      pvalue: text,
      ptype: ClipboardType.text,
      time: DateTime.now().toIso8601String(),
      isFavorite: false,
    );
    await addItem(model);
  }

  Future<void> _initializeState() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // 1. 加载分页项 (服务层会自动处理 FTS 或普通拉取，并仅拉取缩略图)
      final items = await _service.getFilteredItems(
        limit: _state.pageSize,
        offset: 0,
        filterType: _state.filterType.toString().split('.').last,
      );

      _updateState(_state.copyWith(
        allItems: items,
        filteredItems: items,
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

  /// 确保项具有完整 bytes (Lazy Loading)
  Future<ClipboardItemModel> ensureBytes(ClipboardItemModel model) async {
    if (model.bytes != null) return model;

    final updated = await _service.ensureBytes(model);

    // 更新内存状态
    final index = _state.allItems.indexWhere((item) => item.id == model.id);
    if (index != -1) {
      final newItems = List<ClipboardItemModel>.from(_state.allItems);
      newItems[index] = updated;
      _updateState(_state.copyWith(allItems: newItems));
      _applyFiltersAndSearch();
    }

    return updated;
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
  // 应用过滤和搜索
  void _applyFiltersAndSearch() {
    var filteredItems = List<ClipboardItemModel>.from(_state.allItems);
    bool hasSearch = _state.searchQuery.isNotEmpty;
    bool hasFilter = _state.filterType != NSPboardSortType.all;

    // 应用内存级别基础过滤 (提升 UI 响应深度)
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

    // 对于搜索，我们在加载时已经利用了 FTS5
    // 这里做最后的权重微调排序
    if (hasSearch) {
      final query = _state.searchQuery.toLowerCase();
      filteredItems.sort((a, b) {
        final aVal = a.pvalue.toLowerCase();
        final bVal = b.pvalue.toLowerCase();
        final aStarts = aVal.startsWith(query);
        final bStarts = bVal.startsWith(query);

        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;

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
    debugPrint(
        '🔵 PboardProvider.addItem called: ${model.ptype}, id: ${model.id}');
    try {
      // 插入逻辑移交给 Service (自动处理缩略图生成)
      debugPrint('🔵 Calling service.processAndInsert...');
      final deletedItemId = await _service.processAndInsert(model);
      debugPrint(
          '🔵 processAndInsert completed, deletedItemId: $deletedItemId');

      // 更新内存状态 (内存中可以保留 bytes 减少重复拉取)
      List<ClipboardItemModel> nextAllItems = [model, ..._state.allItems];
      debugPrint(
          '🔵 Current allItems count: ${_state.allItems.length}, new count will be: ${nextAllItems.length}');

      if (deletedItemId != null) {
        nextAllItems =
            nextAllItems.where((item) => item.id != deletedItemId).toList();
        debugPrint(
            '🔵 Removed deleted item, final count: ${nextAllItems.length}');
      }

      _updateState(_state.copyWith(allItems: nextAllItems));
      debugPrint('🔵 State updated with new allItems');
      _applyFiltersAndSearch();
      debugPrint(
          '✅ addItem completed successfully, filteredItems count: ${_state.filteredItems.length}');

      return const Result.success(null);
    } catch (e) {
      debugPrint('❌ addItem failed: $e');
      _handleError('添加', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> loadItems() async {
    return await _withLoading(() async {
      try {
        final items = await _service.getFilteredItems(
          limit: _state.pageSize,
          offset: 0,
          searchQuery:
              _state.searchQuery.isNotEmpty ? _state.searchQuery : null,
          filterType: _state.filterType.toString().split('.').last,
        );

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

      await _service.toggleFavorite(newModel);
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

      await _service.delete(model);
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

  // 搜索方法 - 触发重新加载 (利用 FTS5)
  Future<Result<void>> search(String query) async {
    query = query.trim();
    _updateState(_state.copyWith(searchQuery: query));
    return await loadItems();
  }

  Future<Result<void>> clearAll() async {
    try {
      // 暂保留直接 DB 调用用于清空，或由 Service 扩展
      await _service.clearAll();
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

      final newItems = await _service.getFilteredItems(
        limit: _state.pageSize,
        offset: offset,
        searchQuery: _state.searchQuery.isNotEmpty ? _state.searchQuery : null,
        filterType: _state.filterType.toString().split('.').last,
      );

      if (newItems.isEmpty) {
        _updateState(_state.copyWith(hasMore: false));
        return const Result.success(null);
      }

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
