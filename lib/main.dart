import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  final EventChannel _eventChannel =
      const EventChannel('com.easy.pasteboard.event');
  final MethodChannel _methodChannel =
      const MethodChannel('com.easy.pasteboard.method');

  String _counter = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _eventChannel.receiveBroadcastStream().listen((event) {
      print('received event');
      List<Map> pItem = event;
      for (var item in pItem) {
        print(item);
      }
      Map map = event[4];
      print(map);
      Uint8List bytes = map['public.utf8-plain-text'];
      String string = String.fromCharCodes(bytes);
      setState(() {
        _counter = string;
      });
    }, onError: (dynamic error) {
      print('received error: ${error.message}');
    }, cancelOnError: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          try {
            List<int> strList1 = 'hello1'.codeUnits;
            Uint8List bytes1 = Uint8List.fromList(strList1);
            List<int> strList2 = 'hello2'.codeUnits;
            Uint8List bytes2 = Uint8List.fromList(strList2);
            List list = [
              {"1": bytes1},
              {"1": bytes2},
            ];
            final result =
                await _methodChannel.invokeMethod('setPasteboardItem', list);
            print('receive swift data ${result}');
          } on PlatformException catch (e) {
            print('${e.message}');
          }
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
