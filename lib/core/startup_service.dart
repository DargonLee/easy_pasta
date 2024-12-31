import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:easy_pasta/db/shared_preference_helper.dart';
import 'dart:io' show Platform;

class StartupService {
  static final StartupService _instance = StartupService._internal();
  factory StartupService() => _instance;
  StartupService._internal();

  Future<void> init() async {
    final prefs = await SharedPreferenceHelper.instance;
    final enable = prefs.getLoginInLaunch();
    setEnable(enable);
  }

  Future<void> setEnable(bool enable) async {
    final prefs = await SharedPreferenceHelper.instance;
    await prefs.setLoginInLaunch(enable);
    final packageInfo = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
      packageName: 'dev.harlans.easy_pasta',
    );
    if (enable) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
  }

  Future<void> enable() async {
    await launchAtStartup.enable();
  }

  Future<void> disable() async {
    await launchAtStartup.disable();
  }

  Future<bool> isEnabled() async {
    return await launchAtStartup.isEnabled();
  }
}
