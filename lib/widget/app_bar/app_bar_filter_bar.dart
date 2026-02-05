import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';

class AppBarFilterBar extends StatelessWidget {
  final NSPboardSortType selectedType;
  final ValueChanged<NSPboardSortType> onTypeChanged;

  const AppBarFilterBar({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in filterOptions)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppBarFilterChip(
                option: option,
                isSelected: selectedType == option.type,
                onSelected: onTypeChanged,
              ),
            ),
        ],
      ),
    );
  }
}

class AppBarFilterChip extends StatelessWidget {
  final FilterOption option;
  final bool isSelected;
  final ValueChanged<NSPboardSortType> onSelected;

  const AppBarFilterChip({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark
        ? AppColors.darkSecondaryBackground.withValues(alpha: 0.7)
        : AppColors.lightSecondaryBackground.withValues(alpha: 0.7);

    return Tooltip(
      message: option.label,
      waitDuration: const Duration(milliseconds: 500),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : unselectedColor,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
          boxShadow: isSelected ? AppShadows.sm : AppShadows.none,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(option.type);
            },
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
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
      ),
    );
  }
}
