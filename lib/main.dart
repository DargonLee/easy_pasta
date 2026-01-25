import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/page/home_page_view.dart';
import 'package:easy_pasta/page/bonsoir_page.dart';
import 'package:easy_pasta/core/tray_service.dart';
import 'package:easy_pasta/core/window_service.dart';
import 'package:easy_pasta/core/hotkey_service.dart';
import 'package:easy_pasta/core/startup_service.dart';
import 'package:easy_pasta/providers/theme_provider.dart';
import 'package:easy_pasta/model/app_theme.dart';
import 'package:easy_pasta/core/auto_paste_service.dart';
import 'package:easy_pasta/core/sync_portal_service.dart';
import 'package:easy_pasta/core/bonsoir_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_pasta/db/shared_preference_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 启动移动端同步服务
  await SyncPortalService.instance.start();

  // 启动 Bonjour 广播 (根据设置)
  final prefs = await SharedPreferenceHelper.instance;
  if (prefs.getBonjourEnabled()) {
    await BonjourManager.instance.startService(
        attributes: {'portal_url': SyncPortalService.instance.portalUrl ?? ''});
  }

  // 添加错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  WindowService();
  TrayService();
  HotkeyService();
  StartupService();

  runApp(const MyApp());
  // runApp(MyTextApp());
}

class MyTextApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bonsoir Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BonjourTestPage(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PboardProvider>(create: (_) => PboardProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        Provider<AutoPasteService>(create: (_) => AutoPasteService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Easy Pasta',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            home: const MyHomePage(),
          );
        },
      ),
    );
  }
}
