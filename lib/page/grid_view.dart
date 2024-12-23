import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/page/new_pboard_card_view.dart';
import 'package:easy_pasta/page/empty_view.dart';

class PasteboardGridView extends StatefulWidget {
  static const double _kGridSpacing = 8.0;
  static const int _kCrossAxisCount = 3;

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
  void didUpdateWidget(PasteboardGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.pboards.isEmpty) {
      return const EmptyStateView();
    }

    return ScrollConfiguration(
      behavior: CustomScrollBehavior(),
      child: Scrollbar(
        child: GridView.builder(
          key: const PageStorageKey<String>('pasteboard_grid'),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: PasteboardGridView._kCrossAxisCount,
            mainAxisSpacing: PasteboardGridView._kGridSpacing,
            crossAxisSpacing: PasteboardGridView._kGridSpacing,
            childAspectRatio: 1.2,
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
