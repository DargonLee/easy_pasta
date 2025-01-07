import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/core/settings_service.dart';
import 'package:easy_pasta/widget/settting_page_widgets.dart';
import 'package:easy_pasta/page/confirm_dialog_view.dart';
import 'package:easy_pasta/model/settings_constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = SettingsService();
  bool _autoLaunch = false;
  HotKey? _hotKey;

  final List<SettingItem> _basicSettings = [
    const SettingItem(
      type: SettingType.hotkey,
      title: SettingsConstants.hotkeyTitle,
      subtitle: SettingsConstants.hotkeySubtitle,
      icon: Icons.keyboard,
    ),
    const SettingItem(
      type: SettingType.autoLaunch,
      title: SettingsConstants.autoLaunchTitle,
      subtitle: SettingsConstants.autoLaunchSubtitle,
      icon: Icons.launch,
    ),
    const SettingItem(
      type: SettingType.maxStorage,
      title: SettingsConstants.maxStorageTitle,
      subtitle: SettingsConstants.maxStorageSubtitle,
      icon: Icons.storage,
    ),
    const SettingItem(
      type: SettingType.clearData,
      title: SettingsConstants.clearDataTitle,
      subtitle: SettingsConstants.clearDataSubtitle,
      icon: Icons.delete_outline,
      iconColor: Colors.red,
      textColor: Colors.red,
    ),
    const SettingItem(
      type: SettingType.exitApp,
      title: SettingsConstants.exitAppTitle,
      subtitle: SettingsConstants.exitAppSubtitle,
      icon: Icons.exit_to_app,
      iconColor: Colors.red,
      textColor: Colors.red,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _hotKey = await _settingsService.getHotKey();
    _autoLaunch = await _settingsService.getAutoLaunch();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSection(
            title: SettingsConstants.basicSettingsTitle,
            items: _basicSettings,
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: SettingsConstants.aboutTitle,
            items: [
              const SettingItem(
                type: SettingType.about,
                title: SettingsConstants.versionInfoTitle,
                subtitle: SettingsConstants.versionInfoSubtitle,
                icon: Icons.info_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<SettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: items.map((item) => _buildSettingTile(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(SettingItem item) {
    switch (item.type) {
      case SettingType.hotkey:
        return HotkeyTile(
          item: item,
          hotKey: _hotKey,
          onHotKeyChanged: (newHotKey) async {
            await _settingsService.setHotKey(newHotKey);
            setState(() => _hotKey = newHotKey);
          },
        );
      case SettingType.autoLaunch:
        return AutoLaunchTile(
          item: item,
          value: _autoLaunch,
          onChanged: (value) async {
            await _settingsService.setAutoLaunch(value);
            setState(() => _autoLaunch = value);
          },
        );
      case SettingType.maxStorage:
        return MaxStorageTile(item: item);
      case SettingType.clearData:
        return ClearDataTile(
          item: item,
          onClear: () => _showClearConfirmDialog(),
        );
      case SettingType.exitApp:
        return ExitAppTile(item: item);
      case SettingType.about:
        return AboutTile(item: item);
    }
  }

  Future<void> _showClearConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(
        title: '确认清除',
        content: '是否清除所有剪贴板记录？此操作不可恢复。',
        confirmText: '确定',
        cancelText: '取消',
      ),
    );

    if (result == true && mounted) {
      await _settingsService.clearAllData(context);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
