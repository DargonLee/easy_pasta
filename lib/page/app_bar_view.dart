import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';

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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _FilterBar(
              selectedType: selectedType,
              onTypeChanged: onTypeChanged,
            ),
          ),
          const SizedBox(width: 8),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SearchBar(
      controller: controller,
      onSubmitted: onSearch,
      hintText: '搜索',
      hintStyle: WidgetStateProperty.all(
        TextStyle(color: isDark ? Colors.white60 : Colors.black45),
      ),
      leading: Icon(
        Icons.search,
        size: 20,
        color: isDark ? Colors.white54 : Colors.black45,
      ),
      trailing: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                controller.clear();
                onClear();
              },
            );
          },
        ),
      ],
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(
        isDark ? Colors.grey[800] : Colors.grey[50],
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 8),
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
              padding: const EdgeInsets.only(right: 8),
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
    final theme = Theme.of(context);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            option.icon,
            size: 16,
            color: isSelected ? Colors.white : theme.iconTheme.color,
          ),
          const SizedBox(width: 4),
          Text(
            option.label,
            style: TextStyle(
              color:
                  isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
              fontSize: 13,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(option.type),
      selectedColor: theme.colorScheme.primary,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SettingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: onTap,
      tooltip: '设置',
      constraints: const BoxConstraints(minWidth: 40),
      padding: EdgeInsets.zero,
    );
  }
}
