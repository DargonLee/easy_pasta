import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/core/icon_service.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_pasta/providers/pboard_provider.dart';
import 'package:easy_pasta/core/sync_portal_service.dart';

class FooterContent extends StatelessWidget {
  final ClipboardItemModel model;
  final Function(ClipboardItemModel) onCopy;
  final Function(ClipboardItemModel) onFavorite;
  final Function(ClipboardItemModel) onDelete;
  final bool showActions;
  final bool compact;
  final VoidCallback? onSuccess; // 新增成功回调

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
          // 类型图标
          Icon(
            TypeIconHelper.getTypeIcon(
              model.ptype ?? ClipboardType.unknown,
              pvalue: model.pvalue,
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
                    // 复制按钮
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

                    // 收藏按钮
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

                    // 删除按钮
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

                    // 同步到手机
                    _ActionButton(
                      icon: Icons.mobile_screen_share,
                      tooltip: '同步到手机',
                      iconSize: actionIconSize,
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        try {
                          if (kDebugMode) {
                            print(
                                'SyncPortal: Fetching full data for item ${model.id}');
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
                          if (kDebugMode) {
                            print('SyncPortal ERROR in UI: $e');
                          }
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

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else {
      return '${timestamp.month}月${timestamp.day}日';
    }
  }

  String getDetailedTime(DateTime timestamp) {
    return '${timestamp.year}年${timestamp.month}月${timestamp.day}日 '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  bool isToday(DateTime timestamp) {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }
}

/// 操作按钮组件
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
    final effectiveColor = widget.color ??
        (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppCurves.standard,
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: _isHovered
                  ? (isDark
                      ? AppColors.darkSecondaryBackground
                      : AppColors.lightSecondaryBackground)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: _isHovered
                  ? (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary)
                  : effectiveColor,
            ),
          ),
        ),
      ),
    );
  }
}
