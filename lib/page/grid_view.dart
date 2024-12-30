import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/page/new_pboard_card_view.dart';
import 'package:easy_pasta/page/empty_view.dart';

class PasteboardGridView extends StatefulWidget {
  static const double _kGridSpacing = 8.0;
  static const double _kMinCrossAxisExtent = 250.0;

  final List<NSPboardTypeModel> pboards;
  final int selectedId;
  final Function(NSPboardTypeModel) onItemTap;
  final Function(NSPboardTypeModel) onItemDoubleTap;

  const PasteboardGridView({
    Key? key,
    required this.pboards,
    required this.selectedId,
    required this.onItemTap,
    required this.onItemDoubleTap,
  }) : super(key: key);

  @override
  State<PasteboardGridView> createState() => _PasteboardGridViewState();
}

class _PasteboardGridViewState extends State<PasteboardGridView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.pboards.isEmpty) {
      return const EmptyStateView();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算每行最多能显示多少列
        final maxColumns =
            (constraints.maxWidth / PasteboardGridView._kMinCrossAxisExtent)
                .floor();
        // 限制列数在1-3之间
        final columns = maxColumns.clamp(1, 3);

        // 根据列数计算实际的item宽度
        final itemWidth = (constraints.maxWidth -
                (columns - 1) * PasteboardGridView._kGridSpacing) /
            columns;
        // 设置宽高比
        final aspectRatio = itemWidth / (itemWidth / 1.2);

        return ScrollConfiguration(
          behavior: CustomScrollBehavior(),
          child: Scrollbar(
            child: GridView.builder(
              key: const PageStorageKey<String>('pasteboard_grid'),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: PasteboardGridView._kGridSpacing,
                crossAxisSpacing: PasteboardGridView._kGridSpacing,
                childAspectRatio: aspectRatio,
              ),
              cacheExtent: 1000,
              itemCount: widget.pboards.length,
              itemBuilder: (context, index) {
                final model = widget.pboards[index];
                return NewPboardItemCard(
                  key: ValueKey(model.id),
                  model: model,
                  selectedId: widget.selectedId,
                  onTap: widget.onItemTap,
                  onDoubleTap: widget.onItemDoubleTap,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class CustomScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
