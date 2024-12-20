import 'dart:convert';
import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/tool/channel_mgr.dart';
import 'package:easy_pasta/widget/item_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/page/settings_page.dart';
import 'package:easy_pasta/db/constanst_helper.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:easy_pasta/page/app_bar_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await hotKeyManager.unregisterAll();
  runApp(const MyApp());
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
  // 常量定义
  static const double _kSpacing = 16.0;
  static const double _kGridSpacing = 10.0;
  static const int _kCrossAxisCount = 3;
  static const Duration _kScrollDuration = Duration(milliseconds: 200);

  // Controller 定义
  final _chanelMgr = ChannelManager();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  // State
  int _selectedId = 0;

  // Grid Layout 配置
  final _gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: _kCrossAxisCount,
    mainAxisSpacing: _kGridSpacing,
    crossAxisSpacing: _kGridSpacing,
    childAspectRatio: 1.5,
  );

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
    _chanelMgr.eventValueChangedCallback = _handlePboardUpdate;
  }

  void _handlePboardUpdate(NSPboardTypeModel model) {
    context.read<PboardProvider>().addPboardModel(model);
    _scrollToBottom();
  }

  Future<void> _scrollToBottom() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: _kScrollDuration,
      curve: Curves.easeOut,
    );
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
      body: _buildBody(),
      floatingActionButton: _buildScrollButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: _buildSearchField(),
      actions: [
        _buildSettingsButton(),
        const SizedBox(width: _kSpacing),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _handleSearch,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        hintText: '搜索',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _getAllPboardList();
                },
              )
            : null,
      ),
    );
  }

  Widget _buildSettingsButton() {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SettingsPage()),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(_kSpacing),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final pboards = context.watch<PboardProvider>().pboards;

    if (pboards.isEmpty) {
      return const EmptyStateView();
    }

    return GridView.builder(
      reverse: true,
      physics: const BouncingScrollPhysics(),
      controller: _scrollController,
      gridDelegate: _gridDelegate,
      itemCount: pboards.length,
      itemBuilder: (_, index) => _buildPboardItem(pboards[index]),
    );
  }

  Widget _buildPboardItem(NSPboardTypeModel model) {
    return GestureDetector(
      onTap: () => setState(() => _selectedId = model.id!.toInt()),
      onDoubleTap: () => _chanelMgr.setPasteboardItem(model),
      child: ItemCard(
        model: model,
        selectedId: _selectedId,
      ),
    );
  }

  Widget _buildScrollButton() {
    return FloatingActionButton(
      onPressed: _scrollToBottom,
      backgroundColor: Colors.blue,
      elevation: 2,
      child: const Icon(Icons.arrow_upward, color: Colors.white),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.content_paste, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
