import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:easy_pasta/model/settings_constants.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/providers/theme_provider.dart';
import 'package:easy_pasta/widget/setting_tiles.dart' hide ThemeTile, HotkeyTile;
import 'package:easy_pasta/core/settings_service.dart';
import 'package:easy_pasta/page/confirm_dialog_view.dart';
import 'package:easy_pasta/widget/settting_page_widgets.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/core/animation_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = SettingsService();
  bool _autoLaunch = false;
  bool _bonjourEnabled = false;
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
          ? AppColors.darkBackground 
          : AppColors.lightSecondaryBackground,
      appBar: AppBar(
        title: Text(
          '设置',
          style: isDark 
              ? AppTypography.darkHeadline 
              : AppTypography.lightHeadline,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark 
            ? AppColors.darkBackground 
            : AppColors.lightBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: AnimationHelper.fadeIn(
        duration: AppDurations.normal,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            _buildSection(
              context: context,
              title: SettingsConstants.basicSettingsTitle,
              items: _basicSettings,
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildSection(
              context: context,
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
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<SettingItem> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: (isDark 
                ? AppTypography.darkCaption 
                : AppTypography.lightCaption
            ).copyWith(
              color: isDark 
                  ? AppColors.darkTextSecondary 
                  : AppColors.lightTextSecondary,
              fontWeight: AppFontWeights.semiBold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        // 设置项卡片
        Container(
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.darkCardBackground 
                : AppColors.lightCardBackground,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isDark 
                  ? AppColors.darkBorder.withOpacity(0.3) 
                  : AppColors.lightBorder.withOpacity(0.5),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...
                [
                  Column(
                    children: [
                      _buildSettingTile(items[i]),
                      if (i < items.length - 1)
                        Divider(
                          height: 1,
                          indent: AppSpacing.xxxl + AppSpacing.lg,
                          color: isDark 
                              ? AppColors.darkDivider 
                              : AppColors.lightDivider,
                        ),
                    ],
                  ),
                ],
            ],
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
      case SettingType.bonjour:  // Handle the new Bonjour setting type
        return SwitchListTile(
          title: Text(item.title),
          subtitle: Text(item.subtitle),
          value: _bonjourEnabled,
          onChanged: (bool value) async {
            setState(() {
              _bonjourEnabled = value;
            });
            // Here you could add logic to start or stop Bonjour service
            // For example: _startBonjourService(value);
          },
          secondary: Icon(item.icon),
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
