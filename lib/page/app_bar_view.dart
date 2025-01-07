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
    return Container(
      child: _buildAppBarContent(),
    );
  }

  Widget _buildAppBarContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Flexible(
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
            child: _buildFilterBar(),
          ),
          const SizedBox(width: 8),
          const SizedBox(width: 8),
          IconButton(
            constraints: const BoxConstraints(minWidth: 40),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.settings),
            onPressed: onSettingsTap,
            tooltip: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
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

    return Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: 100),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextField(
            controller: controller,
            onSubmitted: (value) => onSearch(value),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '搜索',
              hintStyle:
                  TextStyle(color: isDark ? Colors.white60 : Colors.black45),
              prefixIcon: Icon(Icons.search,
                  size: 20, color: isDark ? Colors.white54 : Colors.black45),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        controller.clear();
                        onClear();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          );
        },
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 72),
      child: FilterChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              option.label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(option.type),
        selectedColor: Colors.blue,
        checkmarkColor: Colors.white,
        showCheckmark: false,
      ),
    );
  }
}
