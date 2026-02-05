import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/grid_density.dart';

class AppBarDensityToggle extends StatelessWidget {
  final GridDensity density;
  final ValueChanged<GridDensity> onChanged;

  const AppBarDensityToggle({
    super.key,
    required this.density,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.darkSecondaryBackground.withValues(alpha: 0.7)
        : AppColors.lightSecondaryBackground.withValues(alpha: 0.7);
    final border = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.4)
        : AppColors.lightBorder.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in GridDensity.values)
            AppBarDensityOption(
              option: option,
              isSelected: density == option,
              onSelected: onChanged,
            ),
        ],
      ),
    );
  }
}

class AppBarDensityOption extends StatelessWidget {
  final GridDensity option;
  final bool isSelected;
  final ValueChanged<GridDensity> onSelected;

  const AppBarDensityOption({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Tooltip(
      message: option.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(option);
          },
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppCurves.standard,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected ? selectedColor : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.full),
              boxShadow: isSelected ? AppShadows.sm : AppShadows.none,
            ),
            child: Icon(
              option.icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
