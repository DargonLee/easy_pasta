import 'dart:ui';

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
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/core/animation_helper.dart';
import 'package:easy_pasta/page/bonsoir_page.dart';
import 'package:easy_pasta/core/auto_paste_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = SettingsService();
  bool _autoLaunch = false;
  bool _bonjourEnabled = false;
  bool _autoPasteEnabled = false;
  bool _isAccessibilityTrusted = false;
  int _maxItems = 500;
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
    _bonjourEnabled = await _settingsService.getBonjourEnabled();
    _autoPasteEnabled = await _settingsService.getAutoPaste();
    _isAccessibilityTrusted = await AutoPasteService().checkAccessibility();
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
          const _SettingsBackground(),
          Column(
            children: [
              _SettingsHeader(
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
              ),
            ],
          ),
        ],
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
                    : AppTypography.lightCaption)
                .copyWith(
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
            gradient: isDark
                ? AppGradients.darkCardSheen
                : AppGradients.lightCardSheen,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isDark
                  ? AppColors.darkFrostedBorder
                  : AppColors.lightFrostedBorder,
            ),
            boxShadow: isDark ? AppShadows.darkSm : AppShadows.sm,
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
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
      case SettingType.bonjour:
        return ToggleSettingTile(
          item: item,
          value: _bonjourEnabled,
          onChanged: (bool value) async {
            await _settingsService.setBonjourEnabled(value);
            setState(() => _bonjourEnabled = value);
          },
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BonjourTestPage()),
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

class _SettingsHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _SettingsHeader({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkFrostedSurface : AppColors.lightFrostedSurface;
    final borderColor =
        isDark ? AppColors.darkFrostedBorder : AppColors.lightFrostedBorder;

    return SafeArea(
      bottom: false,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppBlur.frosted,
            sigmaY: AppBlur.frosted,
          ),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _HeaderButton(
                  icon: Icons.arrow_back,
                  onTap: onBack,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: isDark
                          ? AppTypography.darkHeadline
                          : AppTypography.lightHeadline,
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSecondaryBackground.withOpacity(0.7)
        : AppColors.lightSecondaryBackground.withOpacity(0.7);
    final hoverColor = isDark
        ? AppColors.darkTertiaryBackground.withOpacity(0.7)
        : AppColors.lightTertiaryBackground.withOpacity(0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppCurves.standard,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _isHovered ? hoverColor : baseColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder.withOpacity(0.4)
                    : AppColors.lightBorder.withOpacity(0.4),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.darkPaperBackground
              : AppGradients.lightPaperBackground,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -140,
              left: -80,
              child: _SettingsGlow(
                color: isDark
                    ? AppColors.primary.withOpacity(0.12)
                    : AppColors.primary.withOpacity(0.08),
                radius: 220,
              ),
            ),
            Positioned(
              bottom: -160,
              right: -90,
              child: _SettingsGlow(
                color: isDark
                    ? AppColors.primaryLight.withOpacity(0.08)
                    : AppColors.primaryLight.withOpacity(0.12),
                radius: 260,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGlow extends StatelessWidget {
  final Color color;
  final double radius;

  const _SettingsGlow({
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }
}
