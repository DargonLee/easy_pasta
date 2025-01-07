import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/page/home_page_view.dart';
import 'package:easy_pasta/core/tray_service.dart';
import 'package:easy_pasta/core/window_service.dart';
import 'package:easy_pasta/core/hotkey_service.dart';
import 'package:easy_pasta/core/startup_service.dart';
import 'package:easy_pasta/providers/theme_provider.dart';
import 'package:easy_pasta/model/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final windowService = WindowService();
  await windowService.init();

  final trayService = TrayService();
  await trayService.init();

  await HotkeyService().init();

  final startupService = StartupService();
  await startupService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PboardProvider>(create: (_) => PboardProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Easy Pasta',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const MyHomePage(),
      ),
    );
  }
}
