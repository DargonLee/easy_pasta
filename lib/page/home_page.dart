import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/page/settings_page.dart';
import 'package:easy_pasta/page/grid_view.dart';
import 'package:easy_pasta/page/app_bar_widget.dart';
import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/core/super_clipboard.dart';
import 'package:easy_pasta/core/window_service.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:developer' as developer;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TrayListener, WindowListener {
  // Controller 定义
  final _searchController = TextEditingController();
  final _superClipboard = SuperClipboard.instance;

  // 选中类型
  ItemType _selectedType = ItemType.all;

  // State
  int _selectedId = 0;

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
    windowManager.addListener(this);
    _initializeApp();
  }

  void _initializeApp() {
    _getAllPboardList();
    _superClipboard.setClipboardListener((value) {
      if (value != null) {
        _handlePboardUpdate(value);
      }
    });
  }

  void _handlePboardUpdate(NSPboardTypeModel model) {
    context.read<PboardProvider>().addPboardModel(model);
  }

  void _setPasteboardItem(NSPboardTypeModel model) {
    _superClipboard.setPasteboardItem(model);
    WindowService().hideWindow();
  }

  void _handleSearch(String value) {
    if (value.isEmpty) {
      _getAllPboardList();
    } else {
      _quaryAllPboardList(value);
    }
  }

  void _handleTypeChanged(ItemType type) {
    setState(() {
      _selectedType = type;
    });
    developer.log('选中类型: $type');
  }

  void _handleClear() {
    setState(() {
      _searchController.clear();
    });
  }

  void _getAllPboardList() {
    context.read<PboardProvider>().getPboardList();
  }

  void _quaryAllPboardList(String query) {
    context.read<PboardProvider>().getPboardListWithString(query);
  }

  void _handleSettingsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        searchController: _searchController,
        onSearch: _handleSearch,
        onTypeChanged: _handleTypeChanged,
        onClear: _handleClear,
        onSettingsTap: _handleSettingsTap,
        selectedType: _selectedType,
      ),
      body: Container(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final pboards = context.watch<PboardProvider>().pboards;
    return PasteboardGridView(
      pboards: pboards,
      selectedId: _selectedId,
      onItemTap: (model) => setState(() => _selectedId = model.id!.toInt()),
      onItemDoubleTap: (model) => _setPasteboardItem(model),
      onCopy: (model) => _setPasteboardItem(model),
    );
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
  void onWindowBlur() {
    WindowService().hideWindow();
  }
}
