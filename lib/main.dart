import 'dart:collection';
import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/tool/channel_mgr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

void main() {
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    chanelMgr.initChannel();
    chanelMgr.eventValueChangedCallback = (model) {
      Provider.of<PboardProvider>(context, listen: false).addPboardModel(model);
      _scrollController.animateTo(.0, duration: const Duration(milliseconds: 200), curve: Curves.ease);
    };

    Provider.of<PboardProvider>(context, listen: false).getPboardList();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UnmodifiableListView<NSPboardTypeModel> pboards = Provider.of<PboardProvider>(context).pboards;

    Widget _buildItemCard(NSPboardTypeModel model) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          model.pvalue,
        ),
      );
    }

    Widget _buildBody() {
      if (Provider.of<PboardProvider>(context).count > 0) {
        return GridView.count(
          controller: _scrollController,
          reverse: true,
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5 / 1,
          children: pboards.map((model) => _buildItemCard(model)).toList(),
        );
      }
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(fontSize: 20.0),
        ),
      );
    }

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {},
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
