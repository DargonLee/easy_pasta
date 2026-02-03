import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/page/home_page_view.dart';
import 'package:easy_pasta/core/tray_service.dart';
import 'package:easy_pasta/core/window_service.dart';
import 'package:easy_pasta/core/hotkey_service.dart';
import 'package:easy_pasta/core/startup_service.dart';
import 'package:easy_pasta/providers/theme_provider.dart';
import 'package:easy_pasta/model/app_theme.dart';
import 'package:easy_pasta/core/auto_paste_service.dart';
import 'package:easy_pasta/core/super_clipboard.dart';
import 'package:easy_pasta/core/bonsoir_service.dart';
import 'package:easy_pasta/core/sync_portal_service.dart';
import 'package:easy_pasta/db/shared_preference_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  // 修复：等待所有服务初始化完成后再启动应用
  // 这些服务的构造函数会调用 init()，但不会等待完成
  // 我们需要显式等待它们的初始化
  try {
    await WindowService().init();
    await TrayService().init();
    await HotkeyService().init();
    // StartupService 没有异步初始化，直接调用
    StartupService();
  } catch (e) {
    debugPrint('Service initialization error: $e');
  }

  // 注册应用生命周期回调，确保退出时清理资源
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver());

  runApp(const MyApp());
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

/// 应用生命周期监听器，确保应用在退出时清理资源
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // 应用即将退出，清理所有资源
      _cleanupResources();
    }
  }

  void _cleanupResources() {
    // 清理剪贴板服务
    SuperClipboard.instance.dispose();

    // 清理 Bonjour 服务
    BonjourManager.instance.dispose();

    // 清理同步 Portal 服务
    SyncPortalService.instance.dispose();

    debugPrint('应用退出，所有资源已清理');
  }
}
