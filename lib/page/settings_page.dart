import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/core/settings_service.dart';
import 'package:easy_pasta/widget/settting_page_widgets.dart';
import 'package:easy_pasta/page/confirm_dialog_view.dart';

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
      title: '快捷键',
      subtitle: '设置全局快捷键',
      icon: Icons.keyboard,
    ),
    const SettingItem(
      type: SettingType.autoLaunch,
      title: '开机自启',
      subtitle: '系统启动时自动运行',
      icon: Icons.launch,
    ),
    const SettingItem(
      type: SettingType.maxStorage,
      title: '最大存储',
      subtitle: '设置最大存储条数',
      icon: Icons.storage,
    ),
    const SettingItem(
      type: SettingType.clearData,
      title: '清除记录',
      subtitle: '删除所有剪贴板记录',
      icon: Icons.delete_outline,
      iconColor: Colors.red,
      textColor: Colors.red,
    ),
    const SettingItem(
      type: SettingType.resetApp,
      title: '重置应用',
      subtitle: '重置应用设置',
      icon: Icons.settings,
    ),
    const SettingItem(
      type: SettingType.exitApp,
      title: '退出应用',
      subtitle: '完全退出应用程序',
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
            title: '基本设置',
            items: _basicSettings,
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: '关于',
            items: [
              const SettingItem(
                type: SettingType.about,
                title: '版本信息',
                subtitle: '查看版本和项目信息',
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
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
      case SettingType.resetApp:
        return ResetAppTile(item: item);
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

    if (result == true) {
      if (!mounted) return;
      await _settingsService.clearAllData(context);
      Navigator.pop(context);
    }
  }
}
