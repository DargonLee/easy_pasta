import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';
import 'package:easy_pasta/model/grid_density.dart';
import 'package:easy_pasta/page/pboard_card_view.dart';
import 'package:easy_pasta/page/empty_view.dart';
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
    super.key,
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
  });

  @override
  State<PasteboardGridView> createState() => _PasteboardGridViewState();
}

class _PasteboardGridViewState extends State<PasteboardGridView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;
  Timer? _scrollEndTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollEndTimer?.cancel();
    super.dispose();
  }

  void _handleScroll() {
    if (!_isScrolling) {
      setState(() => _isScrolling = true);
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

    return LayoutBuilder(
      builder: (context, constraints) {
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
                  padding: EdgeInsets.fromLTRB(spec.gridPadding + AppSpacing.sm,
                      AppSpacing.xl, spec.gridPadding, AppSpacing.md),
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
                          : AppColors.lightTextPrimary.withValues(alpha: 0.9),
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
                    (context, index) => _buildCardContent(entry.value[index]),
                    childCount: entry.value.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        );
      },
    );
  }

  Widget _buildCardContent(ClipboardItemModel model) {
    return NewPboardItemCard(
      model: model,
      selectedId: widget.selectedId,
      highlight: widget.highlight,
      density: widget.density,
      enableHover: !_isScrolling,
      showFocus: false,
      badgeIndex: null,
      onTap: widget.onItemTap,
      onDoubleTap: widget.onItemDoubleTap,
      onCopy: widget.onCopy,
      onFavorite: widget.onFavorite,
      onDelete: widget.onDelete,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
