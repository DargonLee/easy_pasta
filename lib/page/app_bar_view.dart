import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/grid_density.dart';
import 'package:easy_pasta/model/time_filter.dart';
import 'package:easy_pasta/widget/app_bar/app_bar_action_buttons.dart';
import 'package:easy_pasta/widget/app_bar/app_bar_density_toggle.dart';
import 'package:easy_pasta/widget/app_bar/app_bar_filter_bar.dart';
import 'package:easy_pasta/widget/app_bar/app_bar_search_field.dart';
import 'package:easy_pasta/widget/app_bar/app_bar_time_filter_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double height = 72;

  final ValueChanged<String> onSearch;
  final TextEditingController searchController;
  final VoidCallback onClear;
  final ValueChanged<NSPboardSortType> onTypeChanged;
  final NSPboardSortType selectedType;
  final TimeFilter selectedTimeFilter;
  final ValueChanged<TimeFilter> onTimeFilterChanged;
  final VoidCallback onSettingsTap;
  final VoidCallback? onAnalyticsTap;
  final GridDensity density;
  final ValueChanged<GridDensity> onDensityChanged;

  const CustomAppBar({
    super.key,
    required this.onSearch,
    required this.searchController,
    required this.onClear,
    required this.onTypeChanged,
    required this.selectedType,
    required this.selectedTimeFilter,
    required this.onTimeFilterChanged,
    required this.onSettingsTap,
    this.onAnalyticsTap,
    required this.density,
    required this.onDensityChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkFrostedSurface : AppColors.lightFrostedSurface;
    final borderColor =
        isDark ? AppColors.darkFrostedBorder : AppColors.lightFrostedBorder;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppBlur.frosted,
          sigmaY: AppBlur.frosted,
        ),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
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
              Expanded(
                flex: 3,
                child: AppBarSearchField(
                  controller: searchController,
                  onSearch: onSearch,
                  onClear: onClear,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Expanded(
                      child: AppBarFilterBar(
                        selectedType: selectedType,
                        onTypeChanged: onTypeChanged,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppBarTimeFilterButton(
                      selectedFilter: selectedTimeFilter,
                      onFilterChanged: onTimeFilterChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppBarDensityToggle(
                density: density,
                onChanged: onDensityChanged,
              ),
              const SizedBox(width: AppSpacing.md),
              const AppBarSyncButton(),
              const SizedBox(width: AppSpacing.md),
              if (onAnalyticsTap != null)
                AppBarAnalyticsButton(onTap: onAnalyticsTap!),
              if (onAnalyticsTap != null)
                const SizedBox(width: AppSpacing.md),
              AppBarSettingsButton(onTap: onSettingsTap),
            ],
          ),
        ),
      ),
    );
  }
}
