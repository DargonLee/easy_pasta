import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_pasta/core/bonsoir_service.dart';
import 'package:easy_pasta/core/sync_portal_service.dart';
import 'package:easy_pasta/core/super_clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 应用退出与资源清理的统一入口
class AppExitService {
  AppExitService._internal();
  static final AppExitService instance = AppExitService._internal();

  Completer<void>? _cleanupCompleter;

  /// 退出应用（推荐路径）
  Future<void> requestExit() async {
    await cleanupIfNeeded();
    await ServicesBinding.instance.exitApplication(ui.AppExitType.required);
  }

  /// 处理系统退出请求
  Future<ui.AppExitResponse> handleExitRequest() async {
    await cleanupIfNeeded();
    return ui.AppExitResponse.exit;
  }

  /// 幂等清理，确保只执行一次
  Future<void> cleanupIfNeeded() {
    if (_cleanupCompleter != null) {
      return _cleanupCompleter!.future;
    }

    final completer = Completer<void>();
    _cleanupCompleter = completer;

    _runCleanup().whenComplete(() => completer.complete());
    return completer.future;
  }

  Future<void> _runCleanup() async {
    try {
      SuperClipboard.instance.dispose();
    } catch (e) {
      debugPrint('Cleanup error (SuperClipboard): $e');
    }

    try {
      await BonjourManager.instance.dispose();
    } catch (e) {
      debugPrint('Cleanup error (Bonjour): $e');
    }

    try {
      await SyncPortalService.instance.dispose();
    } catch (e) {
      debugPrint('Cleanup error (SyncPortal): $e');
    }
  }
}
