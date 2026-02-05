import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/core/app_exit_service.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/model/settings_constants.dart';
import 'package:easy_pasta/widget/settings/base_setting_tile.dart';

class ExitAppTile extends StatelessWidget {
  final SettingItem item;

  const ExitAppTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return BaseSettingTile(
      item: item,
      onTap: () {
        HapticFeedback.mediumImpact();
        _showConfirmDialog(
          context: context,
          title: SettingsConstants.exitConfirmTitle,
          content: SettingsConstants.exitConfirmContent,
          onConfirm: () => AppExitService.instance.requestExit(),
        );
      },
    );
  }

  Future<void> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(SettingsConstants.cancelText,
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text(SettingsConstants.confirmText,
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
