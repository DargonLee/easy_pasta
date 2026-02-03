import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/design_tokens.dart';

/// AppBar 通用按钮容器 - 用于 Settings, Sync, Density 等按钮
class AppBarIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Widget? badge;

  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge,
  });

  @override
  State<AppBarIconButton> createState() => _AppBarIconButtonState();
}

class _AppBarIconButtonState extends State<AppBarIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSecondaryBackground.withValues(alpha: 0.7)
        : AppColors.lightSecondaryBackground.withValues(alpha: 0.7);
    final hoverColor = isDark
        ? AppColors.darkTertiaryBackground.withValues(alpha: 0.7)
        : AppColors.lightTertiaryBackground.withValues(alpha: 0.7);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
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
                      ? AppColors.darkBorder.withValues(alpha: 0.4)
                      : AppColors.lightBorder.withValues(alpha: 0.4),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  if (widget.badge != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: widget.badge!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 状态指示器小圆点
class StatusIndicator extends StatelessWidget {
  final bool isActive;
  final Color? activeColor;
  final Color? inactiveColor;

  const StatusIndicator({
    super.key,
    required this.isActive,
    this.activeColor = Colors.green,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkFrostedSurface : AppColors.lightFrostedSurface;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? activeColor
            : (inactiveColor ?? Colors.grey.withValues(alpha: 0.5)),
        border: Border.all(
          color: surfaceColor,
          width: 1.5,
        ),
      ),
    );
  }
}
