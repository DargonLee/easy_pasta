import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_pasta/widget/counter.dart';
import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/db/constanst_helper.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:easy_pasta/tool/channel_mgr.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _switchSelected = false;
  final chanelMgr = ChannelManager();
  HotKey? _hotKey;
  _alertDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('是否清除所有剪贴版记录'),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '取消',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.pop(context, "取消");
              },
            ),
            TextButton(
              child: const Text(
                '确定',
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                Provider.of<PboardProvider>(context, listen: false).removePboardList();
                Navigator.pop(context, "确定");
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _getLoginInLaunch() async {
    String hotkey = await SharedPreferenceHelper.getShortcutKey();
    if (hotkey.isNotEmpty) {
      Map<String, dynamic> jsonMap = json.decode(hotkey);
      _hotKey = HotKey.fromJson(jsonMap);
    }

    _switchSelected = await SharedPreferenceHelper.getLoginInLaunchKey();

    setState(() {});
  }

  void _setHotKey(HotKey hotKey) async {
    _hotKey = hotKey;
    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (_) {
        chanelMgr.showMainPasteboardWindow();
        setState(() {});
      },
    );
  }

  @override
  void initState() {
    _getLoginInLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(40, 30, 30, 30),
        child: Column(
          children: [
            ListTile(
              title: const Text("快捷键"),
              trailing: Container(
                width: 100,
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    HotKeyRecorder(
                      onHotKeyRecorded: (hotKey) {
                        _setHotKey(hotKey);
                        print(hotKey.toJson().toString());
                        SharedPreferenceHelper.setShortcutKey(json.encode(hotKey.toJson()));
                        setState(() {});
                      },
                    ),
                    _hotKey != null ? HotKeyVirtualView(hotKey: _hotKey!) : const Text('None'),
                  ],
                ),
              ),
            ),
            ListTile(
              title: const Text("登录启动"),
              trailing: Switch(
                value: _switchSelected,
                onChanged: (bool value) {
                  setState(() {
                    _switchSelected = value;
                  });
                  SharedPreferenceHelper.setLoginInLaunchKey(_switchSelected);
                },
              ),
            ),
            const ListTile(
              title: Text("最大存储"),
              trailing: Counter(),
            ),
            ListTile(
              title: const Text("清除记录"),
              trailing: OutlinedButton(
                onPressed: () {
                  _alertDialog();
                },
                child: const Icon(
                  Icons.clear,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
