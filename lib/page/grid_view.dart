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
  }) : super(key: key);

  @override
  State<PasteboardGridView> createState() => _PasteboardGridViewState();
}

class _PasteboardGridViewState extends State<PasteboardGridView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  ClipboardItemModel? _hoveredItem;
  final FocusNode _focusNode = FocusNode();
  bool _isInitialLoad = true;
  bool _hasFocus = false;
  bool _isScrolling = false;
  Timer? _scrollEndTimer;

  @override
  void initState() {
    super.initState();
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
  }

  void _showPreviewDialog(BuildContext context, ClipboardItemModel model) {
    PreviewDialog.show(context, model);
  }

  ClipboardItemModel? _getActiveItem() {
    if (_hoveredItem != null) return _hoveredItem;
    if (widget.selectedId.isEmpty) return null;
    for (final item in widget.pboards) {
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
      widget.onDelete(activeItem);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.pboards.isEmpty) {
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
            final totalSpacing =
                (maxColumns - 1) * spec.gridSpacing + (spec.gridPadding * 2);
            final aspectRatio = _calculateAspectRatio();

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spec.gridPadding),
              child: GridView.builder(
                key: const PageStorageKey<String>('pasteboard_grid'),
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
                cacheExtent: 1000,
                itemCount: widget.pboards.length,
                itemBuilder: (context, index) {
                  return _buildGridItem(context, index);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建网格项
  Widget _buildGridItem(BuildContext context, int index) {
    final model = widget.pboards[index];
    if (_isInitialLoad && index < 20) {
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
        child: _buildCard(model),
      );
    }

    return _buildCard(model);
  }

  /// 构建卡片
  Widget _buildCard(ClipboardItemModel model) {
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
        onDelete: widget.onDelete,
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
