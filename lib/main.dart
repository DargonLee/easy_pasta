import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/page/home_page.dart';
import 'package:easy_pasta/core/tray_service.dart';
import 'package:easy_pasta/core/window_service.dart';
import 'package:easy_pasta/core/hotkey_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final windowService = WindowService();
  await windowService.init();

  final trayService = TrayService();
  await trayService.init();

  await HotkeyService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
