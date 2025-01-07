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

          if (provider.error != null) {
            return Center(
              child: Text(
                provider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return PasteboardGridView(
            pboards: provider.items,
            selectedId: _selectedId,
            onItemTap: _handleItemTap,
            onItemDoubleTap: _setPasteboardItem,
            onCopy: _setPasteboardItem,
            onFavorite: _handleFavorite,
            onDelete: _handleDelete,
          );
        },
      ),
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
    WindowService().hideWindow();
  }

  @override
  void dispose() {
    _searchController.dispose();
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() => WindowService().showWindow();

  @override
  void onWindowBlur() => WindowService().hideWindow();
}
