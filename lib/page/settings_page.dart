import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_pasta/tool/counter.dart';
import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/db/constanst_helper.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:easy_pasta/tool/channel_mgr.dart';
import 'package:easy_pasta/core/record_hotkey_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoLaunch = false;
  HotKey? _hotKey;
  final _channelMgr = ChannelManager();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hotkey = await SharedPreferenceHelper.getShortcutKey();
    if (hotkey.isNotEmpty) {
      _hotKey = HotKey.fromJson(json.decode(hotkey));
    }

    _autoLaunch = await SharedPreferenceHelper.getLoginInLaunchKey();
    setState(() {});
  }

  Future<void> _showClearConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('是否清除所有剪贴板记录？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      context.read<PboardProvider>().removePboardList();
      Navigator.pop(context);
    }
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
            children: [
              _buildHotKeyTile(),
              _buildAutoLaunchTile(),
              _buildMaxStorageTile(),
              _buildClearDataTile(),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: '关于',
            children: [
              _buildAboutTile(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildHotKeyTile() {
    return ListTile(
      leading: const Icon(Icons.keyboard),
      title: const Text('快捷键'),
      subtitle: _hotKey != null
          ? HotKeyVirtualView(hotKey: _hotKey!)
          : const Text('点击设置快捷键'),
      trailing: TextButton(
        onPressed: _showHotKeyDialog,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        child: Text(
          _hotKey != null ? '修改' : '设置',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _handleHotKeyRegister(HotKey hotKey) async {
    await hotKeyManager.register(
      hotKey,
    );
    setState(() {
      _hotKey = hotKey;
    });
    SharedPreferenceHelper.setShortcutKey(json.encode(hotKey.toJson()));
  }

  Future<void> _showHotKeyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RecordHotKeyDialog(
          onHotKeyRecorded: (newHotKey) => _handleHotKeyRegister(newHotKey),
        );
      },
    );
  }

  Widget _buildAutoLaunchTile() {
    return ListTile(
      leading: const Icon(Icons.launch),
      title: const Text('开机自启'),
      subtitle: const Text('系统启动时自动运行'),
      trailing: Switch(
        value: _autoLaunch,
        onChanged: (value) {
          setState(() => _autoLaunch = value);
          SharedPreferenceHelper.setLoginInLaunchKey(value);
          _channelMgr.setLaunchCtl(value);
        },
      ),
    );
  }

  Widget _buildMaxStorageTile() {
    return const ListTile(
      leading: Icon(Icons.storage),
      title: Text('最大存储'),
      subtitle: Text('设置最大存储条数'),
      trailing: Counter(),
    );
  }

  Widget _buildClearDataTile() {
    return ListTile(
      leading: const Icon(Icons.delete_outline, color: Colors.red),
      title: const Text('清除记录', style: TextStyle(color: Colors.red)),
      subtitle: const Text('删除所有剪贴板记录'),
      onTap: _showClearConfirmDialog,
    );
  }

  Widget _buildAboutTile() {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('版本信息'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('当前版本：v1.0.0'),
          const SizedBox(height: 4),
          SelectableText(
            'https://github.com/DargonLee/easy_pasta',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
