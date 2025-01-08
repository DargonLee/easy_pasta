import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/page/pboard_card_view.dart';
import 'package:easy_pasta/page/empty_view.dart';
import 'package:easy_pasta/widget/preview_dialog.dart';

class PasteboardGridView extends StatefulWidget {
  static const double _kGridSpacing = 8.0;
  static const double _kMinCrossAxisExtent = 250.0;

  final List<ClipboardItemModel> pboards;
  final String selectedId;
  final Function(ClipboardItemModel) onItemTap;
  final Function(ClipboardItemModel) onItemDoubleTap;
  final Function(ClipboardItemModel) onCopy;
  final Function(ClipboardItemModel) onFavorite;
  final Function(ClipboardItemModel) onDelete;

  const PasteboardGridView({
    Key? key,
    required this.pboards,
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
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showPreviewDialog(BuildContext context, ClipboardItemModel model) {
    PreviewDialog.show(context, model);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.pboards.isEmpty) {
      return const EmptyStateView();
    }

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKeyboardKey.space &&
            _hoveredItem != null) {
          _showPreviewDialog(context, _hoveredItem!);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxColumns =
              (constraints.maxWidth / PasteboardGridView._kMinCrossAxisExtent)
                  .floor()
                  .clamp(1, 3);

          final itemWidth = (constraints.maxWidth -
                  (maxColumns - 1) * PasteboardGridView._kGridSpacing) /
              maxColumns;
          final aspectRatio = itemWidth / (itemWidth / 1.2);

          return Scrollbar(
            controller: _scrollController,
            child: GridView.builder(
              key: const PageStorageKey<String>('pasteboard_grid'),
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
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
                final model = widget.pboards[index];
                return MouseRegion(
                  onEnter: (_) {
                    setState(() => _hoveredItem = model);
                    _focusNode.requestFocus();
                  },
                  onExit: (_) {
                    setState(() => _hoveredItem = null);
                    _focusNode.unfocus();
                  },
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
              },
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
