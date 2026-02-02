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

/// 粘性分组 header 代理 - 每个分组一个，依次吸顶
class _StickyGroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final bool isDarkMode;
  final double gridPadding;
  final double extent;

  _StickyGroupHeaderDelegate({
    required this.title,
    required this.isDarkMode,
    required this.gridPadding,
    required this.extent,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final backgroundColor = isDarkMode
        ? AppColors.darkSecondaryBackground.withValues(alpha: 1.0)
        : AppColors.lightSecondaryBackground.withValues(alpha: 1.0);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(
          Radius.circular(12.0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(
        horizontal: gridPadding,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: (isDarkMode
                ? AppTypography.darkHeadline
                : AppTypography.lightHeadline)
            .copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyGroupHeaderDelegate oldDelegate) {
    return title != oldDelegate.title ||
        isDarkMode != oldDelegate.isDarkMode ||
        gridPadding != oldDelegate.gridPadding ||
        extent != oldDelegate.extent;
  }
}

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

  int _calculateMaxColumns(double maxWidth, GridDensitySpec spec) {
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = widget.density.spec;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxColumns = _calculateMaxColumns(constraints.maxWidth, spec);
        final aspectRatio = _calculateAspectRatio();

        return CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            for (final entry in widget.groups.entries)
              // 使用 SliverMainAxisGroup 包裹每个分组的 header 和内容
              // 这样 header 会依次吸顶，实现分组切换效果
              SliverMainAxisGroup(
                slivers: [
                  // 分组标题 header - 吸顶
                  SliverPersistentHeader(
                    pinned: true,
                    floating: false,
                    delegate: _StickyGroupHeaderDelegate(
                      title: entry.key,
                      isDarkMode: isDark,
                      gridPadding: spec.gridPadding,
                      extent: 52.0,
                    ),
                  ),
                  // 分组内容
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
              ),
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
