import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';

class SettingsHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const SettingsHeader({
    super.key,
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
                SettingsHeaderButton(
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

class SettingsHeaderButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const SettingsHeaderButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  State<SettingsHeaderButton> createState() => _SettingsHeaderButtonState();
}

class _SettingsHeaderButtonState extends State<SettingsHeaderButton> {
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
                    ? AppColors.darkBorder.withValues(alpha: 0.4)
                    : AppColors.lightBorder.withValues(alpha: 0.4),
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
