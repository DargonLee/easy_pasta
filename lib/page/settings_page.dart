import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:easy_pasta/model/settings_constants.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/providers/theme_provider.dart';
import 'package:easy_pasta/core/settings_service.dart';
import 'package:easy_pasta/page/confirm_dialog_view.dart';
import 'package:easy_pasta/widget/settting_page_widgets.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/core/animation_helper.dart';
import 'package:easy_pasta/core/auto_paste_service.dart';
import 'package:easy_pasta/core/bonsoir_service.dart';
import 'package:easy_pasta/page/settings/settings_background.dart';
import 'package:easy_pasta/page/settings/settings_header.dart';
import 'package:easy_pasta/page/settings/settings_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = SettingsService();
  bool _autoLaunch = false;
  bool _autoPasteEnabled = false;
  bool _isAccessibilityTrusted = false;
  double _dbSizeMb = 0.0;
  int _maxItems = 100;
  int _retentionDays = 7;
  HotKey? _hotKey;

  final List<SettingItem> _basicSettings = [
    const SettingItem(
      type: SettingType.hotkey,
      title: SettingsConstants.hotkeyTitle,
      subtitle: SettingsConstants.hotkeySubtitle,
      icon: Icons.keyboard,
    ),
    const SettingItem(
      type: SettingType.theme,
      title: SettingsConstants.themeTitle,
      subtitle: SettingsConstants.themeSubtitle,
      icon: Icons.palette,
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
      type: SettingType.autoPaste,
      title: SettingsConstants.autoPasteTitle,
      subtitle: SettingsConstants.autoPasteSubtitle,
      icon: Icons.paste_rounded,
    ),
    const SettingItem(
      type: SettingType.retention,
      title: '保留时长',
      subtitle: '历史记录保留天数（收藏项除外）',
      icon: Icons.history,
    ),
    const SettingItem(
      type: SettingType.bonjour,
      title: SettingsConstants.bonjourTitle,
      subtitle: SettingsConstants.bonjourSubtitle,
      icon: Icons.network_wifi,
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
    _autoPasteEnabled = await _settingsService.getAutoPaste();
    _isAccessibilityTrusted = await AutoPasteService().checkAccessibility();
    _dbSizeMb = await _settingsService.getDatabaseSize();
    _maxItems = await _settingsService.getMaxItems();
    _retentionDays = await _settingsService.getRetentionDays();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const SettingsBackground(),
          Column(
            children: [
              SettingsHeader(
                title: '设置',
                onBack: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: AnimationHelper.fadeIn(
                  duration: AppDurations.normal,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      SettingsSection(
                        title: SettingsConstants.basicSettingsTitle,
                        items: _basicSettings,
                        itemBuilder: _buildSettingTile,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SettingsSection(
                        title: '存储管理',
                        items: [
                          const SettingItem(
                            type: SettingType.maxStorage,
                            title: '最大存储量',
                            subtitle: '达到上限后将自动清理最早的非收藏记录',
                            icon: Icons.storage,
                          ),
                          const SettingItem(
                            type: SettingType.dbSize,
                            title: SettingsConstants.dbSizeTitle,
                            subtitle: 'EasyPasta 数据库文件占用的总空间',
                            icon: Icons.data_usage_rounded,
                          ),
                          const SettingItem(
                            type: SettingType.dbOptimize,
                            title: SettingsConstants.dbOptimizeTitle,
                            subtitle: SettingsConstants.dbOptimizeSubtitle,
                            icon: Icons.cleaning_services_rounded,
                          ),
                          const SettingItem(
                            type: SettingType.retention,
                            title: '保留时长',
                            subtitle: '历史记录保留天数（收藏项除外）',
                            icon: Icons.history,
                          ),
                          const SettingItem(
                            type: SettingType.clearData,
                            title: '清除所有记录',
                            subtitle: '清空数据库中的所有本地剪贴板历史',
                            icon: Icons.delete_forever,
                            textColor: Colors.red,
                            iconColor: Colors.red,
                          ),
                        ],
                        itemBuilder: _buildSettingTile,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SettingsSection(
                        title: SettingsConstants.aboutTitle,
                        items: [
                          const SettingItem(
                            type: SettingType.about,
                            title: SettingsConstants.versionInfoTitle,
                            subtitle: SettingsConstants.versionInfoSubtitle,
                            icon: Icons.info_outline,
                          ),
                        ],
                        itemBuilder: _buildSettingTile,
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
      case SettingType.theme:
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return ThemeTile(
              item: item,
              currentThemeMode: themeProvider.themeMode,
              onThemeModeChanged: (ThemeMode mode) {
                themeProvider.setThemeMode(mode);
              },
            );
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
      case SettingType.bonjour:
        return ValueListenableBuilder<bool>(
          valueListenable: BonjourManager.instance.isRunningNotifier,
          builder: (context, isRunning, _) {
            // 这里我们优先使用 Service 的实际状态
            // 但如果用户手动切换了开关，UI 会先响应，Service 状态随后更新
            return ToggleSettingTile(
              item: item,
              value: isRunning,
              onChanged: (bool value) async {
                await _settingsService.setBonjourEnabled(value);
              },
            );
          },
        );
      case SettingType.maxStorage:
        return MaxStorageTile(
          item: item,
          value: _maxItems,
          onChanged: (val) async {
            await _settingsService.setMaxItems(val);
            setState(() => _maxItems = val);
          },
        );
      case SettingType.retention:
        return RetentionDaysTile(
          item: item,
          currentValue: _retentionDays,
          onChanged: (val) async {
            await _settingsService.setRetentionDays(val);
            setState(() => _retentionDays = val);
          },
        );
      case SettingType.autoPaste:
        return AutoPasteTile(
          item: item,
          value: _autoPasteEnabled,
          isPermissionOk: _isAccessibilityTrusted,
          onChanged: (val) => _handleAutoPasteToggle(val),
        );
      case SettingType.clearData:
        return ClearDataTile(
          item: item,
          onClear: _showClearConfirmDialog,
        );
      case SettingType.dbSize:
        return BaseSettingTile(
          item: item,
          trailing: Text(
            '${_dbSizeMb.toStringAsFixed(2)} MB',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        );
      case SettingType.dbOptimize:
        return BaseSettingTile(
          item: item,
          onTap: () async {
            await _settingsService.optimizeDatabase();
            final newSize = await _settingsService.getDatabaseSize();
            if (mounted) {
              setState(() => _dbSizeMb = newSize);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(SettingsConstants.dbOptimizeSuccess)),
              );
            }
          },
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

  Future<void> _handleAutoPasteToggle(bool value) async {
    final autoPasteService = context.read<AutoPasteService>();
    bool hasPermission = _isAccessibilityTrusted;

    if (value) {
      // 开启时检查权限
      hasPermission = await autoPasteService.checkAccessibility();
      if (!hasPermission) {
        // 无权限则展示提示并引导
        if (mounted) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => const ConfirmDialog(
              title: SettingsConstants.accessibilityRequiredTitle,
              content: SettingsConstants.accessibilityRequiredContent,
              confirmText: '去设置',
              cancelText: '暂时不用',
            ),
          );
          if (result == true) {
            await autoPasteService.requestAccessibility();
          }
        }
        return; // 未授权不更新状态
      }
    }

    await _settingsService.setAutoPaste(value);
    if (mounted) {
      setState(() {
        _autoPasteEnabled = value;
        _isAccessibilityTrusted = hasPermission;
      });
    }
  }
}
