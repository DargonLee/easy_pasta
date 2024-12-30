import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/page/home_page.dart';
import 'package:easy_pasta/core/tray_service.dart';
import 'package:easy_pasta/core/window_service.dart';
import 'package:easy_pasta/core/hotkey_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:bitsdojo_window/bitsdojo_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final windowService = WindowService();
  final hotkeyService = HotkeyService();
  final trayService = TrayService();

  await windowService.init();
  await hotkeyService.init();
  await trayService.init();

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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white38),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}
