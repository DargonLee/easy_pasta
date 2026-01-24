import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/model/grid_density.dart';
import 'package:easy_pasta/model/time_filter.dart';
import 'package:easy_pasta/widget/mobile_sync_dialog.dart';

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
                child: _SearchField(
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
                      child: _FilterBar(
                        selectedType: selectedType,
                        onTypeChanged: onTypeChanged,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _TimeFilterButton(
                      selectedFilter: selectedTimeFilter,
                      onFilterChanged: onTimeFilterChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _DensityToggle(
                density: density,
                onChanged: onDensityChanged,
              ),
              const SizedBox(width: AppSpacing.md),
              _SyncButton(),
              const SizedBox(width: AppSpacing.md),
              _SettingsButton(onTap: onSettingsTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final FocusNode _focusNode;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSecondaryBackground.withValues(alpha: 0.7)
        : AppColors.lightSecondaryBackground.withValues(alpha: 0.7);
    final shadows = <BoxShadow>[
      if (_isFocused)
        BoxShadow(
          color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      if (_isHovered && !_isFocused) ...AppShadows.md,
    ];

    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.4)
        : AppColors.lightBorder.withValues(alpha: 0.4);
    final textStyle = isDark ? AppTypography.darkBody : AppTypography.lightBody;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        decoration: BoxDecoration(
          color: _isFocused
              ? (isDark
                  ? AppColors.darkSecondaryBackground
                  : AppColors.lightSecondaryBackground)
              : baseColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _isFocused
                ? AppColors.primary.withValues(alpha: 0.4)
                : borderColor,
            width: 1,
          ),
          boxShadow: shadows,
        ),
        child: TextField(
          focusNode: _focusNode,
          controller: widget.controller,
          onChanged: widget.onSearch,
          onSubmitted: widget.onSearch,
          style: textStyle,
          textInputAction: TextInputAction.search,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: '搜索剪贴板',
            hintStyle: textStyle.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.controller.clear();
                    widget.onClear();
                  },
                  splashRadius: 16,
                );
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

class _TimeFilterButton extends StatelessWidget {
  final TimeFilter selectedFilter;
  final ValueChanged<TimeFilter> onFilterChanged;

  const _TimeFilterButton({
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

class _FilterBar extends StatelessWidget {
  final NSPboardSortType selectedType;
  final ValueChanged<NSPboardSortType> onTypeChanged;

  const _FilterBar({
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
              child: _FilterChip(
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

class _FilterChip extends StatelessWidget {
  final FilterOption option;
  final bool isSelected;
  final ValueChanged<NSPboardSortType> onSelected;

  const _FilterChip({
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

class _DensityToggle extends StatelessWidget {
  final GridDensity density;
  final ValueChanged<GridDensity> onChanged;

  const _DensityToggle({
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
            _DensityOption(
              option: option,
              isSelected: density == option,
              onSelected: onChanged,
            ),
        ],
      ),
    );
  }
}

class _DensityOption extends StatelessWidget {
  final GridDensity option;
  final bool isSelected;
  final ValueChanged<GridDensity> onSelected;

  const _DensityOption({
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

class _SettingsButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SettingsButton({required this.onTap});

  @override
  State<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton> {
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
      message: '设置',
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
              child: Icon(
                Icons.settings,
                size: 18,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncButton extends StatefulWidget {
  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton> {
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
      message: '手机同步',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              MobileSyncDialog.show(context);
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
              child: Icon(
                Icons.mobile_screen_share,
                size: 18,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
