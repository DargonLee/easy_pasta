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
import 'package:easy_pasta/model/design_tokens.dart';
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
    _pboardProvider.loadItems();
  }

  void _handleSearch(String value) {
    if (value.isEmpty) {
      _pboardProvider.loadItems();
    } else {
      _pboardProvider.search(value);
    }
  }

  void _handleTypeChanged(NSPboardSortType type) {
    setState(() => _selectedType = type);
    _pboardProvider.filterByType(type);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        onSearch: _handleSearch,
        searchController: _searchController,
        onClear: _handleClear,
        onTypeChanged: _handleTypeChanged,
        selectedType: _selectedType,
        onSettingsTap: () => _navigateToSettings(),
      ),
      body: Consumer<PboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
      
          // 使用 AnimatedSwitcher 实现切换动画
          return AnimatedSwitcher(
            duration: AppDurations.normal,
            switchInCurve: AppCurves.standard,
            switchOutCurve: AppCurves.standard,
            transitionBuilder: (Widget child, Animation<double> animation) {
              // 渐变 + 缩放 + 微妙位移动画
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.95,
                    end: 1.0,
                  ).animate(animation),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.02),
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
              key: ValueKey('${_selectedType.toString()}_${provider.items.length}'),
            ),
          );
        },
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
      currentCategory: _selectedType,
      selectedId: _selectedId,
      onItemTap: _handleItemTap,
      onItemDoubleTap: _setPasteboardItem,
      onCopy: _setPasteboardItem,
      onFavorite: _handleFavorite,
      onDelete: _handleDelete,
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  void _setPasteboardItem(ClipboardItemModel model) {
    _superClipboard.setPasteboardItem(model);
    WindowService().closeWindow();
  }

  @override
  void dispose() {
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
