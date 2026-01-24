import 'dart:async';
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
import 'package:easy_pasta/model/app_typography.dart';

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
  final Map<String, List<ClipboardItemModel>> groups;
  final String? highlight;

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
    required this.groups,
    this.highlight,
  }) : super(key: key);

  @override
  State<PasteboardGridView> createState() => _PasteboardGridViewState();
}

class _PasteboardGridViewState extends State<PasteboardGridView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  ClipboardItemModel? _hoveredItem;
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;
  bool _isScrolling = false;
  Timer? _scrollEndTimer;
  double _lastWidth = 0;
  final Map<String, GlobalKey> _cardKeys = {};
  bool _lastInteractionWasKeyboard = false; // 幽灵 Hover 锁
  int _firstVisibleIndex = 0; // 当前视口第一条数据的全局索引

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
    _scrollController.addListener(() {
      _handleScroll();
      _updateVisibleItems();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateVisibleItems();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollEndTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_isScrolling || _hoveredItem != null) {
      if (mounted) {
        setState(() {
          _isScrolling = true;
          _hoveredItem = null;
        });
      }
    }
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() => _isScrolling = false);
      RendererBinding.instance.mouseTracker.updateAllDevices();
    });

    if (widget.onLoadMore != null && _scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll * 0.8) {
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
    for (final item in widget.pboards) {
      if (item.id == widget.selectedId) return item;
    }
    return null;
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    // 只要有键盘操作，立即开启鼠标锁
    if (!_lastInteractionWasKeyboard) {
      if (mounted) {
        setState(() {
          _lastInteractionWasKeyboard = true;
          _hoveredItem = null; // [FIXED] 切换为键盘模式时清除悬停状态
        });
      }
    }

    final activeItem = _getActiveItem();
    final logicalKey = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    final isCommand = keyboard.isMetaPressed || keyboard.isControlPressed;

    if (activeItem != null) {
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
        return;
      }
    }

    if (logicalKey == LogicalKeyboardKey.arrowUp ||
        logicalKey == LogicalKeyboardKey.arrowDown ||
        logicalKey == LogicalKeyboardKey.arrowLeft ||
        logicalKey == LogicalKeyboardKey.arrowRight) {
      _handleGridNavigation(logicalKey);
      return;
    }

    if (isCommand &&
        logicalKey.keyId >= LogicalKeyboardKey.digit1.keyId &&
        logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
      final relativeIndex = logicalKey.keyId - LogicalKeyboardKey.digit1.keyId;
      final targetGlobalIndex = _firstVisibleIndex + relativeIndex;

      if (targetGlobalIndex < widget.pboards.length) {
        widget.onCopy(widget.pboards[targetGlobalIndex]);
      }
      return;
    }
  }

  void _updateVisibleItems() {
    if (!_scrollController.hasClients) return;

    final gridBox = context.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    // 获取所有可见卡片中位置最靠前的一个
    String? topId;
    double minTop = double.infinity;

    for (var entry in _cardKeys.entries) {
      final context = entry.value.currentContext;
      if (context == null) continue;

      final rb = context.findRenderObject() as RenderBox?;
      if (rb != null) {
        final position = rb.localToGlobal(Offset.zero, ancestor: gridBox);
        // 如果卡片在视口内（上方溢出不超过 1/2 高度，且在底部以上）
        if (position.dy >= -100 && position.dy < minTop) {
          minTop = position.dy;
          topId = entry.key;
        }
      }
    }

    if (topId != null) {
      final newFirst = widget.pboards.indexWhere((item) => item.id == topId);
      if (newFirst != -1 && newFirst != _firstVisibleIndex) {
        setState(() => _firstVisibleIndex = newFirst);
      }
    }
  }

  void _handleGridNavigation(LogicalKeyboardKey key) {
    if (widget.pboards.isEmpty) return;

    final currentIndex =
        widget.pboards.indexWhere((item) => item.id == widget.selectedId);
    if (currentIndex == -1) {
      _selectIndex(0);
      return;
    }

    final maxColumns = _calculateMaxColumns(_lastWidth);
    int nextIndex = currentIndex;

    if (key == LogicalKeyboardKey.arrowLeft) {
      nextIndex = currentIndex - 1;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      nextIndex = currentIndex + 1;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      nextIndex = currentIndex - maxColumns;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      nextIndex = currentIndex + maxColumns;
    }

    if (nextIndex >= 0 && nextIndex < widget.pboards.length) {
      _selectIndex(nextIndex);
    }
  }

  void _selectIndex(int index) {
    final model = widget.pboards[index];
    widget.onItemTap(model);
    _scrollToItem(model.id);
  }

  void _scrollToItem(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _cardKeys[id]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: 0.35,
        );
      }
    });
  }

  int _calculateMaxColumns(double maxWidth) {
    final spec = widget.density.spec;
    final effectiveWidth = maxWidth - (spec.gridPadding * 2);
    return (effectiveWidth / spec.minCrossAxisExtent)
        .floor()
        .clamp(1, PasteboardGridView._kMaxColumns);
  }

  double _calculateAspectRatio() => widget.density.spec.aspectRatio;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.pboards.isEmpty) {
      return EmptyStateView(category: widget.currentCategory);
    }

    return Listener(
      onPointerMove: (_) {
        if (_lastInteractionWasKeyboard) {
          setState(() => _lastInteractionWasKeyboard = false);
        }
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _lastWidth = constraints.maxWidth;
            final spec = widget.density.spec;
            final maxColumns = _calculateMaxColumns(constraints.maxWidth);
            final aspectRatio = _calculateAspectRatio();

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                for (final entry in widget.groups.entries) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          spec.gridPadding + AppSpacing.sm,
                          AppSpacing.xl,
                          spec.gridPadding,
                          AppSpacing.md),
                      child: Text(
                        entry.key,
                        style: (Theme.of(context).brightness == Brightness.dark
                                ? AppTypography.darkHeadline
                                : AppTypography.lightHeadline)
                            .copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary.withValues(alpha: 0.9)
                              : AppColors.lightTextPrimary
                                  .withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: spec.gridPadding),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: maxColumns,
                        mainAxisSpacing: spec.gridSpacing,
                        crossAxisSpacing: spec.gridSpacing,
                        childAspectRatio: aspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildCardContent(entry.value[index]),
                        childCount: entry.value.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxxl)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent(ClipboardItemModel model) {
    final key = _cardKeys.putIfAbsent(model.id, () => GlobalKey());
    final globalIndex = widget.pboards.indexOf(model);

    // [REFINED] 动态计算相对于当前第一个可见项的偏移
    final relativeIndex = globalIndex - _firstVisibleIndex;
    final badgeIndex =
        (relativeIndex >= 0 && relativeIndex < 9) ? relativeIndex : null;

    return MouseRegion(
      onEnter: (_) {
        if (_isScrolling || _lastInteractionWasKeyboard) return;
        _updateHoveredItem(model, true);
      },
      onHover: (_) {
        if (_isScrolling || _lastInteractionWasKeyboard) return;
        if (_hoveredItem?.id != model.id) _updateHoveredItem(model, true);
      },
      onExit: (_) {
        if (_lastInteractionWasKeyboard) return;
        _updateHoveredItem(null, false);
      },
      child: NewPboardItemCard(
        key: key,
        model: model,
        selectedId: widget.selectedId,
        highlight: widget.highlight,
        density: widget.density,
        // 并行锁定：禁止 hover，且内部状态也会在 didUpdateWidget 中强制清空
        enableHover: !_isScrolling && !_lastInteractionWasKeyboard,
        showFocus: _hasFocus && widget.selectedId == model.id,
        badgeIndex: badgeIndex,
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

  void _updateHoveredItem(ClipboardItemModel? model, bool isHovered) {
    if (!mounted) return;
    setState(() {
      _hoveredItem = isHovered ? model : null;
      if (isHovered) _focusNode.requestFocus();
    });
  }

  @override
  bool get wantKeepAlive => true;
}
