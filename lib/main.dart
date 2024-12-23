import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white38),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}
