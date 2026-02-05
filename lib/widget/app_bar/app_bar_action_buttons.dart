import 'package:flutter/material.dart';
import 'package:easy_pasta/core/bonsoir_service.dart';
import 'package:easy_pasta/widget/app_bar/app_bar_buttons.dart';
import 'package:easy_pasta/widget/mobile_sync_dialog.dart';

class AppBarSettingsButton extends StatelessWidget {
  final VoidCallback onTap;

  const AppBarSettingsButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppBarIconButton(
      icon: Icons.settings,
      tooltip: '设置',
      onTap: onTap,
    );
  }
}

class AppBarSyncButton extends StatelessWidget {
  const AppBarSyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBarIconButton(
      icon: Icons.mobile_screen_share,
      tooltip: '手机同步',
      onTap: () => MobileSyncDialog.show(context),
      badge: ValueListenableBuilder<bool>(
        valueListenable: BonjourManager.instance.isRunningNotifier,
        builder: (context, isRunning, _) {
          return StatusIndicator(isActive: isRunning);
        },
      ),
    );
  }
}

class AppBarAnalyticsButton extends StatelessWidget {
  final VoidCallback onTap;

  const AppBarAnalyticsButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppBarIconButton(
      icon: Icons.insights,
      tooltip: '数据分析',
      onTap: onTap,
    );
  }
}
