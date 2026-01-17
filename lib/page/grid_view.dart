import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';
import 'package:easy_pasta/page/pboard_card_view.dart';
import 'package:easy_pasta/page/empty_view.dart';
import 'package:easy_pasta/widget/preview_dialog.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/core/animation_helper.dart';

class PasteboardGridView extends StatefulWidget {
  static const double _kGridSpacing = AppSpacing.gridSpacing;
  static const double _kGridPadding = AppSpacing.gridPadding;
  static const double _kMinCrossAxisExtent = 240.0;
  static const int _kMaxColumns = 4;

  final List<ClipboardItemModel> pboards;
  final NSPboardSortType currentCategory;
  final String selectedId;
  final Function(ClipboardItemModel) onItemTap;
  final Function(ClipboardItemModel) onItemDoubleTap;
  final Function(ClipboardItemModel) onCopy;
  final Function(ClipboardItemModel) onFavorite;
  final Function(ClipboardItemModel) onDelete;

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
  }) : super(key: key);

  @override
  State<PasteboardGridView> createState() => _PasteboardGridViewState();
}

class _PasteboardGridViewState extends State<PasteboardGridView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  ClipboardItemModel? _hoveredItem;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showPreviewDialog(BuildContext context, ClipboardItemModel model) {
    PreviewDialog.show(context, model);
  }

  /// 计算网格列数
  int _calculateMaxColumns(double maxWidth) {
    // 减去左右内边距
    final effectiveWidth = maxWidth - (PasteboardGridView._kGridPadding * 2);
    final columns = (effectiveWidth / PasteboardGridView._kMinCrossAxisExtent)
        .floor()
        .clamp(1, PasteboardGridView._kMaxColumns);
    return columns;
  }

  /// 计算网格的纵横比（宽度:高度）
  double _calculateAspectRatio(double itemWidth) {
    // 调整为更紧凑的纵横比
    return itemWidth / (itemWidth * 0.85); // 约 1:0.85
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.pboards.isEmpty) {
      return EmptyStateView(category: widget.currentCategory);
    }

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.space &&
            _hoveredItem != null) {
          _showPreviewDialog(context, _hoveredItem!);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxColumns = _calculateMaxColumns(constraints.maxWidth);
          final totalSpacing = (maxColumns - 1) * PasteboardGridView._kGridSpacing +
              (PasteboardGridView._kGridPadding * 2);
          final itemWidth = (constraints.maxWidth - totalSpacing) / maxColumns;
          final aspectRatio = _calculateAspectRatio(itemWidth);

          return Scrollbar(
            controller: _scrollController,
            thickness: 6,
            radius: const Radius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PasteboardGridView._kGridPadding,
              ),
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
                  mainAxisSpacing: PasteboardGridView._kGridSpacing,
                  crossAxisSpacing: PasteboardGridView._kGridSpacing,
                  childAspectRatio: aspectRatio,
                ),
                cacheExtent: 1000,
                itemCount: widget.pboards.length,
                itemBuilder: (context, index) {
                  return _buildGridItem(context, index);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建网格项
  Widget _buildGridItem(BuildContext context, int index) {
    final model = widget.pboards[index];
    return _buildCard(model);
  }

  /// 构建卡片
  Widget _buildCard(ClipboardItemModel model) {
    return MouseRegion(
      onEnter: (_) => _updateHoveredItem(model, true),
      onExit: (_) => _updateHoveredItem(null, false),
      child: NewPboardItemCard(
        key: ValueKey(model.id),
        model: model,
        selectedId: widget.selectedId,
        onTap: widget.onItemTap,
        onDoubleTap: widget.onItemDoubleTap,
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
