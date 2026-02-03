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
    final typeIconSize = compact ? 12.0 : 14.0;
    final actionIconSize = compact ? 12.0 : 14.0;
    final spacing = compact ? AppSpacing.xs / 2 : AppSpacing.xs;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          // 类型图标 (高性能版: 依赖预计算分类)
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

          // 时间戳
          Text(
            _formatTimestamp(DateTime.parse(model.time)),
            style: (isDark
                    ? AppTypography.darkCaption
                    : AppTypography.lightCaption)
                .copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),

          const Spacer(),

          // 操作按钮组 (带滑入滑出动画)
          AnimatedOpacity(
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
                    _ActionButton(
                      icon: Icons.copy,
                      tooltip: '复制',
                      iconSize: actionIconSize,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onCopy(model);
                        onSuccess?.call();
                      },
                    ),
                    SizedBox(width: spacing),
                    _ActionButton(
                      icon: model.isFavorite ? Icons.star : Icons.star_border,
                      tooltip: model.isFavorite ? '取消收藏' : '收藏',
                      iconSize: actionIconSize,
                      color: model.isFavorite ? AppColors.favorite : null,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onFavorite(model);
                      },
                    ),
                    SizedBox(width: spacing),
                    _ActionButton(
                      icon: Icons.delete_outline,
                      tooltip: '删除',
                      iconSize: actionIconSize,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onDelete(model);
                      },
                    ),
                    SizedBox(width: spacing),
                    _ActionButton(
                      icon: Icons.mobile_screen_share,
                      tooltip: '同步到手机',
                      iconSize: actionIconSize,
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        try {
                          // 检查是否有活跃的手机连接
                          if (!SyncPortalService
                              .instance.hasActiveConnections) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('请先在手机浏览器中打开同步页面'),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  duration: const Duration(seconds: 3),
                                  action: SnackBarAction(
                                    label: '查看帮助',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('请在主界面点击「同步到手机」图标查看二维码'),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }
                            return;
                          }

                          final pboardProvider = context.read<PboardProvider>();
                          final fullModel =
                              await pboardProvider.ensureBytes(model);
                          SyncPortalService.instance.pushItem(fullModel);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('已发送到手机 Portal'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('发送失败: $e'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                    ),

                    // 智能 URL
                    if (model.classification?.kind == ContentKind.url) ...[
                      SizedBox(width: spacing),
                      _ActionButton(
                        icon: Icons.open_in_new,
                        tooltip: '打开链接',
                        iconSize: actionIconSize,
                        color: AppColors.primary,
                        onPressed: () async {
                          final url = model.classification
                                  ?.metadata?['normalizedUrl'] as String? ??
                              model.pvalue;
                          final uri = Uri.tryParse(url);
                          if (uri != null) await launchUrl(uri);
                        },
                      ),
                    ],

                    // 智能 JSON
                    if (model.classification?.kind == ContentKind.json) ...[
                      SizedBox(width: spacing),
                      _ActionButton(
                        icon: Icons.format_align_left,
                        tooltip: '格式化 JSON',
                        iconSize: actionIconSize,
                        color: AppColors.primary,
                        onPressed: () {
                          try {
                            final decoded = jsonDecode(model.pvalue);
                            final formatted = const JsonEncoder.withIndent('  ')
                                .convert(decoded);
                            Clipboard.setData(ClipboardData(text: formatted));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('已格式化并复制到剪贴板'),
                                    duration: Duration(seconds: 1)),
                              );
                            }
                          } catch (_) {}
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inHours < 1) return '${difference.inMinutes}分钟前';
    if (difference.inDays < 1) return '${difference.inHours}小时前';
    if (difference.inDays < 30) return '${difference.inDays}天前';
    return '${timestamp.month}月${timestamp.day}日';
  }
}

/// 轻量级操作按钮 - 无 Ripple，无 Material 消耗
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
