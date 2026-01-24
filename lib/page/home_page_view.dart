import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/page/settings_page.dart';
import 'package:easy_pasta/page/grid_view.dart';
import 'package:easy_pasta/page/app_bar_view.dart';
import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/core/super_clipboard.dart';
import 'package:easy_pasta/core/window_service.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';
import 'package:easy_pasta/core/settings_service.dart';
import 'package:easy_pasta/core/auto_paste_service.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/grid_density.dart';
import 'package:easy_pasta/model/time_filter.dart';
import 'package:easy_pasta/widget/search_empty_state.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TrayListener, WindowListener {
  late final PboardProvider _pboardProvider;
  final _searchController = TextEditingController();
  final _superClipboard = SuperClipboard.instance;

  NSPboardSortType _selectedType = NSPboardSortType.all;
  String _selectedId = '';
  TimeFilter _selectedTimeFilter = TimeFilter.all;
  GridDensity _density = GridDensity.comfortable;
  Timer? _searchDebounce; // 搜索防抖定时器

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PboardProvider>().loadItems();
    });
    trayManager.addListener(this);
    windowManager.addListener(this);
    _setupClipboardListener();
    _pboardProvider = context.read<PboardProvider>();
  }

  void _setupClipboardListener() {
    _superClipboard.setClipboardListener((value) {
      if (value != null) {
        _handlePboardUpdate(value);
      }
    });
  }

  void _handlePboardUpdate(ClipboardItemModel model) {
    _pboardProvider.addItem(model);
  }

  void _handleClear() {
    _searchDebounce?.cancel();
    _pboardProvider.search(''); // 重置 Provider 内部搜索状态
    _pboardProvider.loadItems(); // 重新加载完整列表
  }

  void _handleSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
      if (value.isEmpty) {
        _pboardProvider.search('');
        _pboardProvider.loadItems();
      } else {
        _pboardProvider.search(value);
      }
    });
  }

  void _handleTypeChanged(NSPboardSortType type) {
    setState(() => _selectedType = type);
    _pboardProvider.filterByType(type);
  }

  void _handleTimeFilterChanged(TimeFilter filter) {
    setState(() => _selectedTimeFilter = filter);
    _pboardProvider.filterByTime(filter);
  }

  void _handleDensityChanged(GridDensity density) {
    setState(() => _density = density);
  }

  void _handleItemTap(ClipboardItemModel model) {
    if (!mounted) return;
    setState(() => _selectedId = model.id);
  }

  void _handleFavorite(ClipboardItemModel model) {
    _pboardProvider.toggleFavorite(model);
  }

  void _handleDelete(ClipboardItemModel model) {
    _pboardProvider.delete(model);
  }

  void _handleLoadMore() {
    _pboardProvider.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        onSearch: _handleSearch,
        searchController: _searchController,
        onClear: _handleClear,
        onTypeChanged: _handleTypeChanged,
        selectedType: _selectedType,
        selectedTimeFilter: _selectedTimeFilter,
        onTimeFilterChanged: _handleTimeFilterChanged,
        onSettingsTap: () => _navigateToSettings(),
        density: _density,
        onDensityChanged: _handleDensityChanged,
      ),
      body: Stack(
        children: [
          const _HomeBackground(),
          Padding(
            padding: const EdgeInsets.only(
              top: CustomAppBar.height + AppSpacing.sm,
            ),
            child: Consumer<PboardProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 使用 AnimatedSwitcher 实现切换动画
                return AnimatedSwitcher(
                  duration: AppDurations.normal,
                  switchInCurve: AppCurves.standard,
                  switchOutCurve: AppCurves.standard,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    // 渐变 + 缩放 + 微妙位移动画
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.97,
                          end: 1.0,
                        ).animate(animation),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.015),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _buildContent(
                    provider,
                    // 使用分类作为 key，确保切换时触发动画
                    key: ValueKey(
                      '${_selectedType.toString()}_$_density',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(PboardProvider provider, {Key? key}) {
    // 显示搜索空状态（有搜索条件但无结果）
    if (provider.error != null) {
      return SearchEmptyState(
        key: key,
        searchQuery: _searchController.text,
        onClear: () {
          _searchController.clear();
          setState(() => _selectedType = NSPboardSortType.all);
          _pboardProvider.loadItems();
        },
      );
    }

    // 显示网格视图（包括分类空状态）
    return PasteboardGridView(
      key: key,
      pboards: provider.items,
      groups: provider.groupedItems,
      highlight: provider.searchQuery,
      currentCategory: _selectedType,
      selectedId: _selectedId,
      onItemTap: _handleItemTap,
      onItemDoubleTap: _setPasteboardItem,
      onCopy: _setPasteboardItem,
      onFavorite: _handleFavorite,
      onDelete: _handleDelete,
      density: _density,
      onLoadMore: _handleLoadMore,
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  Future<void> _setPasteboardItem(ClipboardItemModel model) async {
    await _superClipboard.setPasteboardItem(model);

    final isAutoPasteEnabled = await SettingsService().getAutoPaste();
    if (isAutoPasteEnabled) {
      // 执行自动粘贴前先关闭窗口
      await WindowService().closeWindow();
      // 延迟一丁点执行 native 粘贴，确保窗口已经失去焦点且前代应用已被激活
      Future.delayed(const Duration(milliseconds: 100), () {
        AutoPasteService().paste();
      });
    } else {
      WindowService().closeWindow();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    WindowService().showWindow();
  }

  @override
  void onWindowBlur() => WindowService().closeWindow();
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.darkPaperBackground
              : AppGradients.lightPaperBackground,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _Glow(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.08),
                radius: 220,
              ),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: _Glow(
                color: isDark
                    ? AppColors.primaryLight.withValues(alpha: 0.08)
                    : AppColors.primaryLight.withValues(alpha: 0.12),
                radius: 260,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double radius;

  const _Glow({
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
