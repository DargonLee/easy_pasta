import 'dart:collection';
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
        ChangeNotifierProvider<PboardProvider>(
          create: (_) => PboardProvider(),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final chanelMgr = ChannelManager();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _editingController = TextEditingController();
  final SliverGridDelegateWithFixedCrossAxisCount gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.5 / 1,
  );
  int _selectedId = 0;

  void _getAllPboardList() {
    Provider.of<PboardProvider>(context, listen: false).getPboardList();
  }

  void _quaryAllPboardList(String string) {
    Provider.of<PboardProvider>(context, listen: false).getPboardListWithString(string);
  }

  void _setHotKey() async {
    String hotkey = await SharedPreferenceHelper.getShortcutKey();
    if (hotkey.isNotEmpty) {
      Map<String, dynamic> jsonMap = json.decode(hotkey);
      HotKey hotKey = HotKey.fromJson(jsonMap);
      await hotKeyManager.unregisterAll();
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (_) {
          chanelMgr.showMainPasteboardWindow();
          setState(() {});
        },
      );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    _setHotKey();
    super.initState();
    chanelMgr.initChannel();
    chanelMgr.eventValueChangedCallback = (model) {
      Provider.of<PboardProvider>(context, listen: false).addPboardModel(model);
      Future.delayed(const Duration(milliseconds: 1000), () {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.ease);
      });
    };
    // _scrollController.addListener(()=>print(_scrollController.offset));
    _getAllPboardList();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    _editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UnmodifiableListView<NSPboardTypeModel> pboards = Provider.of<PboardProvider>(context).pboards;

    Widget _buildItemCard(NSPboardTypeModel model, int index) {
      return GestureDetector(
        onTap:() {
          setState(() {
            _selectedId = model.id!.toInt();
          });
        },
        onDoubleTap: () {
          // print('onDoubleTap ${model.id}');
          // Future.delayed(const Duration(milliseconds: 800), () {
            chanelMgr.setPasteboardItem(model);
          // });
        },
        child: ItemCard(
          model: model,
          selectedId: _selectedId,
        ),
      );
    }

    Widget _buildBody() {
      if (Provider.of<PboardProvider>(context).count > 0) {
        return GridView.builder(
          reverse: true,
          itemCount: pboards.length,
          controller: _scrollController,
          shrinkWrap: true,
          gridDelegate: gridDelegate,
          itemBuilder: (context, index) {
            return _buildItemCard(pboards[index], index);
          },
        );
      }
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(fontSize: 20.0),
        ),
      );
    }

    AppBar _buildAppbar() {
      return AppBar(
        title: TextField(
          onChanged: (value) {
            if (value.isNotEmpty) {
              _quaryAllPboardList(value);
            }else {
              _getAllPboardList();
            }
          },
          controller: _editingController,
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: const Icon(Icons.search),
            hintText: 'Search',
            suffixIcon: _editingController.text.isNotEmpty ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _editingController.clear();
                _getAllPboardList();
              },
            ) : null,
          ),
        ),
        actions: [
          IconButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return SettingsPage();
              }),
            );
          }, icon: const Icon(Icons.settings)),
          const SizedBox(
            width: 10,
          )
        ],
      );
    }

    return Scaffold(
      appBar: _buildAppbar(),
      body: Container(
        color: Colors.grey[300],
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.arrow_upward),
        onPressed: () async {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.ease);
        },
      ),
    );
  }
}
