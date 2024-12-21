import 'dart:convert';
import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/tool/channel_mgr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/page/settings_page.dart';
import 'package:easy_pasta/db/constanst_helper.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:easy_pasta/page/app_bar_widget.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:easy_pasta/page/grid_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await hotKeyManager.unregisterAll();
  runApp(const MyApp());
  appWindow.show();
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(600, 450);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Custom window with Flutter";
    win.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PboardProvider>(create: (_) => PboardProvider())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Easy Pasta',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Controller 定义
  final _chanelMgr = ChannelManager();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  // State
  int _selectedId = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() {
    _setHotKey();
    _initializeChannel();
    _getAllPboardList();
  }

  void _initializeChannel() {
    _chanelMgr.initChannel();
    _chanelMgr.onPasteboardChanged = _handlePboardUpdate;
  }

  void _handlePboardUpdate(NSPboardTypeModel model) {
    context.read<PboardProvider>().addPboardModel(model);
  }

  Future<void> _setHotKey() async {
    final hotkey = await SharedPreferenceHelper.getShortcutKey();
    if (hotkey.isEmpty) return;

    final hotKey = HotKey.fromJson(json.decode(hotkey));
    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (_) {
        _chanelMgr.showMainPasteboardWindow();
        setState(() {});
      },
    );
  }

  void _handleSearch(String value) {
    if (value.isEmpty) {
      _getAllPboardList();
    } else {
      _quaryAllPboardList(value);
    }
  }

  void _getAllPboardList() {
    context.read<PboardProvider>().getPboardList();
  }

  void _quaryAllPboardList(String query) {
    context.read<PboardProvider>().getPboardListWithString(query);
  }

  // 在 _MyHomePageState 中添加处理分类的方法
  void _handleTypeChanged(ContentType type) {
    // 根据类型筛选内容
    switch (type) {
      case ContentType.all:
        _getAllPboardList();
        break;
      case ContentType.text:
        // 实现文本过滤
        break;
      case ContentType.image:
        // 实现图片过滤
        break;
      case ContentType.file:
        // 实现文件过滤
        break;
      case ContentType.favorite:
        // 实现收藏过滤
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        searchController: _searchController,
        onSearch: _handleSearch,
        onTypeChanged: _handleTypeChanged,
        onClear: () {
          _searchController.clear();
          _getAllPboardList();
        },
        onSettingsTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingsPage()),
        ),
      ),
      body: WindowBorder(
        color: const Color(0xFF805306),
        width: 1,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      color: Colors.grey[100],
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final pboards = context.watch<PboardProvider>().pboards;
    return PasteboardGridView(
      pboards: pboards,
      scrollController: _scrollController,
      selectedId: _selectedId,
      onItemTap: (model) => setState(() => _selectedId = model.id!.toInt()),
      onItemDoubleTap: (model) => _chanelMgr.setPasteboardItem(model),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
