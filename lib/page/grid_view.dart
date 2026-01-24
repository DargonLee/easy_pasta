import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';
import 'package:easy_pasta/model/grid_density.dart';
import 'package:easy_pasta/page/pboard_card_view.dart';
import 'package:easy_pasta/page/empty_view.dart';
import 'package:easy_pasta/widget/preview_dialog.dart';
import 'package:easy_pasta/model/design_tokens.dart';

class PasteboardGridView extends StatefulWidget {
  static const int _kMaxColumns = 4;

  final List<ClipboardItemModel> pboards;
  final NSPboardSortType currentCategory;
  final String selectedId;
  final Function(ClipboardItemModel) onItemTap;
  final Function(ClipboardItemModel) onItemDoubleTap;
  final Function(ClipboardItemModel) onCopy;
  final Function(ClipboardItemModel) onFavorite;
  final Function(ClipboardItemModel) onDelete;
  final GridDensity density;
  final VoidCallback? onLoadMore;

  const PasteboardGridView({
    Key? key,
    required this.pboards,
    this.currentCategory = NSPboardSortType.all,
    required this.selectedId,
    required this.onItemTap,
    required this.onItemDoubleTap,
    required this.onCopy,
    required this.onFavorite,
    required this.onDelete,
    required this.density,
    this.onLoadMore,
  }) : super(key: key);

  @override
  State<PasteboardGridView> createState() => _PasteboardGridViewState();
}

class _PasteboardGridViewState extends State<PasteboardGridView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedGridState> _gridKey = GlobalKey<AnimatedGridState>();
  late final _ListModel<ClipboardItemModel> _list;
  ClipboardItemModel? _hoveredItem;
  final FocusNode _focusNode = FocusNode();
  bool _isInitialLoad = true;
  bool _hasFocus = false;
  bool _isScrolling = false;
  Timer? _scrollEndTimer;

  @override
  void initState() {
    super.initState();
    _list = _ListModel<ClipboardItemModel>(
      listKey: _gridKey,
      initialItems: widget.pboards,
      removedItemBuilder: _buildRemovedItem,
    );
    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(AppDurations.fast, () {
        if (mounted) {
          setState(() => _isInitialLoad = false);
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _scrollEndTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PasteboardGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pboards != widget.pboards) {
      _syncList(widget.pboards);
    }
  }

  void _handleScroll() {
    if (!_isScrolling || _hoveredItem != null) {
      setState(() {
        _isScrolling = true;
        _hoveredItem = null;
      });
    }
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() {
        _isScrolling = false;
      });
      RendererBinding.instance.mouseTracker.updateAllDevices();
    });

    // 检测是否接近底部 (80% 阈值)
    if (widget.onLoadMore != null && _scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final threshold = maxScroll * 0.8;

      if (currentScroll >= threshold) {
        widget.onLoadMore!();
      }
    }
  }

  void _showPreviewDialog(BuildContext context, ClipboardItemModel model) {
    PreviewDialog.show(context, model);
  }

  ClipboardItemModel? _getActiveItem() {
    if (_hoveredItem != null) return _hoveredItem;
    if (widget.selectedId.isEmpty) return null;
    for (final item in _list.items) {
      if (item.id == widget.selectedId) {
        return item;
      }
    }
    return null;
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final activeItem = _getActiveItem();
    if (activeItem == null) return;

    final logicalKey = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    final isCommand = keyboard.isMetaPressed || keyboard.isControlPressed;

    if (logicalKey == LogicalKeyboardKey.space) {
      _showPreviewDialog(context, activeItem);
      return;
    }

    if (logicalKey == LogicalKeyboardKey.enter ||
        logicalKey == LogicalKeyboardKey.numpadEnter) {
      widget.onItemDoubleTap(activeItem);
      return;
    }

    if (logicalKey == LogicalKeyboardKey.delete ||
        logicalKey == LogicalKeyboardKey.backspace) {
      _handleDelete(activeItem);
      return;
    }

    if (logicalKey == LogicalKeyboardKey.keyC && isCommand) {
      widget.onCopy(activeItem);
      return;
    }

    if (logicalKey == LogicalKeyboardKey.keyF) {
      widget.onFavorite(activeItem);
    }
  }

  /// 计算网格列数
  int _calculateMaxColumns(double maxWidth) {
    final spec = widget.density.spec;
    // 减去左右内边距
    final effectiveWidth = maxWidth - (spec.gridPadding * 2);
    final columns = (effectiveWidth / spec.minCrossAxisExtent)
        .floor()
        .clamp(1, PasteboardGridView._kMaxColumns);
    return columns;
  }

  /// 计算网格的纵横比（宽度:高度）
  double _calculateAspectRatio() => widget.density.spec.aspectRatio;

  void _syncList(List<ClipboardItemModel> newItems) {
    final newIds = newItems.map((item) => item.id).toSet();

    for (int i = _list.length - 1; i >= 0; i--) {
      if (!newIds.contains(_list[i].id)) {
        _list.removeAt(i, duration: AppDurations.normal);
      }
    }

    for (int i = 0; i < newItems.length; i++) {
      final item = newItems[i];
      final existingIndex = _list.indexWhereId(item.id);
      if (existingIndex == -1) {
        _list.insert(i, item, duration: AppDurations.fast);
      } else {
        _list.replaceAt(existingIndex, item);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.pboards.isEmpty && _list.length == 0) {
      return EmptyStateView(category: widget.currentCategory);
    }

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            _handleScroll();
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spec = widget.density.spec;
            final maxColumns = _calculateMaxColumns(constraints.maxWidth);
            final aspectRatio = _calculateAspectRatio();

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spec.gridPadding),
              child: AnimatedGrid(
                key: _gridKey,
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xl,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: maxColumns,
                  mainAxisSpacing: spec.gridSpacing,
                  crossAxisSpacing: spec.gridSpacing,
                  childAspectRatio: aspectRatio,
                ),
                initialItemCount: _list.length,
                itemBuilder: (context, index, animation) {
                  return _buildAnimatedItem(context, index, animation);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(
      BuildContext context, int index, Animation<double> animation) {
    final model = _list[index];
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppCurves.standard,
    );

    final content = _buildCardContent(model);

    // 减少初始动画数量从 20 到 10
    if (_isInitialLoad && index < 10) {
      final delay = Duration(milliseconds: index * 25);
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: AppDurations.normal + delay,
        curve: AppCurves.standard,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - value)),
              child: child,
            ),
          );
        },
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: content,
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
        child: content,
      ),
    );
  }

  /// 构建卡片内容
  Widget _buildCardContent(ClipboardItemModel model) {
    return MouseRegion(
      onEnter: (_) {
        if (_isScrolling) return;
        _updateHoveredItem(model, true);
      },
      onHover: (_) {
        if (_isScrolling) return;
        if (_hoveredItem?.id != model.id) {
          _updateHoveredItem(model, true);
        }
      },
      onExit: (_) => _updateHoveredItem(null, false),
      child: NewPboardItemCard(
        key: ValueKey(model.id),
        model: model,
        selectedId: widget.selectedId,
        density: widget.density,
        enableHover: !_isScrolling,
        showFocus: _hasFocus && widget.selectedId == model.id,
        onTap: (item) {
          _focusNode.requestFocus();
          widget.onItemTap(item);
        },
        onDoubleTap: (item) {
          _focusNode.requestFocus();
          widget.onItemDoubleTap(item);
        },
        onCopy: widget.onCopy,
        onFavorite: widget.onFavorite,
        onDelete: _handleDelete,
      ),
    );
  }

  void _handleDelete(ClipboardItemModel item) {
    final index = _list.indexWhereId(item.id);
    if (index != -1) {
      _list.removeAt(index, duration: AppDurations.normal);
    }
    widget.onDelete(item);
  }

  Widget _buildRemovedItem(ClipboardItemModel item, BuildContext context,
      Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppCurves.emphasized,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
        child: IgnorePointer(
          child: _buildCardContent(item),
        ),
      ),
    );
  }

  /// 更新鼠标悬停的项目
  void _updateHoveredItem(ClipboardItemModel? model, bool isHovered) {
    setState(() {
      _hoveredItem = isHovered ? model : null;
      if (isHovered) {
        _focusNode.requestFocus();
      } else {
        _focusNode.unfocus();
      }
    });
  }

  @override
  bool get wantKeepAlive => true;
}

typedef _RemovedItemBuilder<T> = Widget Function(
    T item, BuildContext context, Animation<double> animation);

class _ListModel<T> {
  _ListModel({
    required this.listKey,
    required this.removedItemBuilder,
    Iterable<T>? initialItems,
  }) : _items = List<T>.from(initialItems ?? <T>[]);

  final GlobalKey<AnimatedGridState> listKey;
  final _RemovedItemBuilder<T> removedItemBuilder;
  final List<T> _items;

  AnimatedGridState? get _animatedGrid => listKey.currentState;

  int get length => _items.length;
  List<T> get items => _items;

  T operator [](int index) => _items[index];

  int indexWhereId(String id) {
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item is ClipboardItemModel && item.id == id) {
        return i;
      }
    }
    return -1;
  }

  void replaceAt(int index, T item) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = item;
  }

  void insert(int index, T item, {required Duration duration}) {
    _items.insert(index, item);
    _animatedGrid?.insertItem(index, duration: duration);
  }

  T removeAt(int index, {required Duration duration}) {
    final removedItem = _items.removeAt(index);
    _animatedGrid?.removeItem(
      index,
      (BuildContext context, Animation<double> animation) {
        return removedItemBuilder(removedItem, context, animation);
      },
      duration: duration,
    );
    return removedItem;
  }
}
