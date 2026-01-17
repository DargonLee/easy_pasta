import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;
  final VoidCallback onClear;
  final ValueChanged<NSPboardSortType> onTypeChanged;
  final NSPboardSortType selectedType;
  final VoidCallback onSettingsTap;

  const CustomAppBar({
    super.key,
    required this.onSearch,
    required this.searchController,
    required this.onClear,
    required this.onTypeChanged,
    required this.selectedType,
    required this.onSettingsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _SearchField(
              controller: searchController,
              onSearch: onSearch,
              onClear: onClear,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: _FilterBar(
              selectedType: selectedType,
              onTypeChanged: onTypeChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _SettingsButton(onTap: onSettingsTap),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        onSubmitted: onSearch,
        textAlignVertical: TextAlignVertical.center,
        style: isDark ? AppTypography.darkBody : AppTypography.lightBody,
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark 
              ? AppColors.darkSecondaryBackground 
              : AppColors.lightSecondaryBackground,
          hintText: '搜索',
          hintStyle: (isDark 
              ? AppTypography.darkBody 
              : AppTypography.lightBody
          ).copyWith(
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
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  Icons.clear,
                  size: 16,
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  controller.clear();
                  onClear();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 16,
              );
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 0,
          ),
          isDense: true,
        ),
      ),
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

    return AnimatedContainer(
      duration: AppDurations.fast,
      curve: AppCurves.standard,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary
            : (isDark 
                ? AppColors.darkSecondaryBackground 
                : AppColors.lightSecondaryBackground),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(option.type);
          },
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  option.icon,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : (isDark 
                          ? AppColors.darkTextPrimary 
                          : AppColors.lightTextPrimary),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  option.label,
                  style: (isDark 
                      ? AppTypography.darkBody 
                      : AppTypography.lightBody
                  ).copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDark 
                            ? AppColors.darkTextPrimary 
                            : AppColors.lightTextPrimary),
                    fontWeight: isSelected 
                        ? AppFontWeights.semiBold 
                        : AppFontWeights.regular,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SettingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Tooltip(
      message: '设置',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.darkSecondaryBackground 
                  : AppColors.lightSecondaryBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.settings,
              size: 20,
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
