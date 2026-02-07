import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/model/content_classification.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/core/icon_service.dart';
import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/core/sync_portal_service.dart';

class FooterContent extends StatelessWidget {
  final ClipboardItemModel model;
  final Function(ClipboardItemModel) onCopy;
  final Function(ClipboardItemModel) onFavorite;
  final Function(ClipboardItemModel) onDelete;
  final bool showActions;
  final bool compact;
  final VoidCallback? onSuccess;

  const FooterContent({
    super.key,
    required this.model,
    required this.onCopy,
    required this.onFavorite,
    required this.onDelete,
    this.showActions = false,
    this.compact = false,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spacing = compact ? AppSpacing.xs / 2 : AppSpacing.xs;
    final timeColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final typeIconSize = compact ? 12.0 : 14.0;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            TypeIconHelper.getTypeIcon(
              model.ptype ?? ClipboardType.unknown,
              pvalue: model.pvalue,
              model: model,
            ),
            size: typeIconSize,
            color: AppColors.primary,
          ),
          SizedBox(width: spacing),
          Text(
            _formatTimestamp(model.parsedTime),
            style: (isDark
                    ? AppTypography.darkCaption
                    : AppTypography.lightCaption)
                .copyWith(color: timeColor),
          ),
          const Spacer(),
          _ActionButtons(
            model: model,
            showActions: showActions,
            compact: compact,
            spacing: spacing,
            onCopy: onCopy,
            onFavorite: onFavorite,
            onDelete: onDelete,
            onSuccess: onSuccess,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    return switch (diff) {
      Duration(inMinutes: < 1) => '刚刚',
      Duration(inHours: < 1) => '${diff.inMinutes}分钟前',
      Duration(inDays: < 1) => '${diff.inHours}小时前',
      Duration(inDays: < 30) => '${diff.inDays}天前',
      _ => '${timestamp.month}月${timestamp.day}日',
    };
  }
}

class _ActionButtons extends StatelessWidget {
  final ClipboardItemModel model;
  final bool showActions;
  final bool compact;
  final double spacing;
  final Function(ClipboardItemModel) onCopy;
  final Function(ClipboardItemModel) onFavorite;
  final Function(ClipboardItemModel) onDelete;
  final VoidCallback? onSuccess;

  const _ActionButtons({
    required this.model,
    required this.showActions,
    required this.compact,
    required this.spacing,
    required this.onCopy,
    required this.onFavorite,
    required this.onDelete,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: showActions ? 1 : 0,
      duration: AppDurations.fast,
      curve: AppCurves.standard,
      child: IgnorePointer(
        ignoring: !showActions,
        child: AnimatedSlide(
          duration: AppDurations.fast,
          curve: AppCurves.standard,
          offset: showActions ? Offset.zero : const Offset(0.1, 0),
          child: Row(
            children: [
              _buildIconButton(
                icon: Icons.copy,
                tooltip: '复制',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onCopy(model);
                  onSuccess?.call();
                },
              ),
              _spacer,
              _buildIconButton(
                icon: model.isFavorite ? Icons.star : Icons.star_border,
                tooltip: model.isFavorite ? '取消收藏' : '收藏',
                color: model.isFavorite ? AppColors.favorite : null,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onFavorite(model);
                },
              ),
              _spacer,
              _buildIconButton(
                icon: Icons.delete_outline,
                tooltip: '删除',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onDelete(model);
                },
              ),
              _spacer,
              _MobileSyncButton(model: model),
              if (model.classification?.kind == ContentKind.url) ...[
                _spacer,
                _UrlButton(model: model),
              ],
              if (model.classification?.kind == ContentKind.json) ...[
                _spacer,
                _JsonButton(model: model),
              ],
            ],
          ),
        ),
      ),
    );
  }

  SizedBox get _spacer => SizedBox(width: spacing);

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return _ActionButton(
      icon: icon,
      tooltip: tooltip,
      iconSize: compact ? 12.0 : 14.0,
      color: color,
      onPressed: onPressed,
    );
  }
}

class _MobileSyncButton extends StatelessWidget {
  final ClipboardItemModel model;
  const _MobileSyncButton({required this.model});

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      icon: Icons.mobile_screen_share,
      tooltip: '同步到手机',
      onPressed: () => _handleSync(context),
    );
  }

  Future<void> _handleSync(BuildContext context) async {
    HapticFeedback.selectionClick();

    if (!SyncPortalService.instance.hasActiveConnections) {
      _showNoConnectionSnack(context);
      return;
    }

    try {
      final fullModel = await context.read<PboardProvider>().ensureBytes(model);
      SyncPortalService.instance.pushItem(fullModel);
      if (context.mounted) {
        _showSnack(context, '已发送到手机 Portal');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnack(context, '发送失败: $e');
      }
    }
  }

  void _showNoConnectionSnack(BuildContext context) {
    _showSnack(
      context,
      '请点击右上角「同步」按钮，使用手机扫描二维码打开同步页面后 [再次点击]',
      duration: const Duration(seconds: 3),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _showSnack(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
        action: action,
      ),
    );
  }

  void _showErrorSnack(BuildContext context, String message) {
    _showSnack(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }
}

class _UrlButton extends StatelessWidget {
  final ClipboardItemModel model;
  const _UrlButton({required this.model});

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      icon: Icons.open_in_new,
      tooltip: '打开链接',
      color: AppColors.primary,
      onPressed: () async {
        final url =
            model.classification?.metadata?['normalizedUrl'] as String? ??
                model.pvalue;
        final uri = Uri.tryParse(url);
        if (uri != null) await launchUrl(uri);
      },
    );
  }
}

class _JsonButton extends StatelessWidget {
  final ClipboardItemModel model;
  const _JsonButton({required this.model});

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      icon: Icons.format_align_left,
      tooltip: '格式化 JSON',
      color: AppColors.primary,
      onPressed: () => _formatAndCopy(context),
    );
  }

  void _formatAndCopy(BuildContext context) {
    try {
      final decoded = jsonDecode(model.pvalue);
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      Clipboard.setData(ClipboardData(text: formatted));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已格式化并复制到剪贴板'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  final double iconSize;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.iconSize = 14,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.color ??
        (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
    final activeColor = widget.color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _isHovered ? activeColor : baseColor,
          ),
        ),
      ),
    );
  }
}
