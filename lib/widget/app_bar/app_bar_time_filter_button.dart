import 'package:flutter/material.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/time_filter.dart';

class AppBarTimeFilterButton extends StatelessWidget {
  final TimeFilter selectedFilter;
  final ValueChanged<TimeFilter> onFilterChanged;

  const AppBarTimeFilterButton({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<TimeFilter>(
      initialValue: selectedFilter,
      onSelected: onFilterChanged,
      tooltip: '时间过滤',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: isDark
              ? AppColors.darkFrostedBorder
              : AppColors.lightFrostedBorder,
        ),
      ),
      color:
          isDark ? AppColors.darkFrostedSurface : AppColors.lightFrostedSurface,
      elevation: 8,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selectedFilter != TimeFilter.all
              ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selectedFilter != TimeFilter.all
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selectedFilter.icon,
              size: 16,
              color: selectedFilter != TimeFilter.all
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => TimeFilter.values.map((filter) {
        final isSelected = selectedFilter == filter;
        return PopupMenuItem<TimeFilter>(
          value: filter,
          child: Row(
            children: [
              Icon(
                filter.icon,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                filter.label,
                style:
                    (isDark ? AppTypography.darkBody : AppTypography.lightBody)
                        .copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
