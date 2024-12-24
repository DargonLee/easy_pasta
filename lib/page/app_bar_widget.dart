import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

/// 内容类型枚举
enum ContentType { all, text, image, file, favorite }

/// 过滤器选项配置
class FilterOption {
  final String label;
  final IconData icon;
  final ContentType type;

  const FilterOption({
    required this.label,
    required this.icon,
    required this.type,
  });
}

/// 自定义应用栏组件
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final Function(ContentType) onTypeChanged;
  final VoidCallback onClear;
  final VoidCallback onSettingsTap;

  const CustomAppBar({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.onTypeChanged,
    required this.onClear,
    required this.onSettingsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  ContentType _selectedType = ContentType.all;

  // 过滤器选项配置列表
  final List<FilterOption> _filterOptions = const [
    FilterOption(
      label: '全部',
      icon: Icons.all_inclusive,
      type: ContentType.all,
    ),
    FilterOption(
      label: '文本',
      icon: Icons.text_fields,
      type: ContentType.text,
    ),
    FilterOption(
      label: '图片',
      icon: Icons.image,
      type: ContentType.image,
    ),
    FilterOption(
      label: '文件',
      icon: Icons.folder,
      type: ContentType.file,
    ),
    FilterOption(
      label: '收藏',
      icon: Icons.favorite,
      type: ContentType.favorite,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: MoveWindow(
        child: _AppBarContent(
          searchController: widget.searchController,
          onSearch: widget.onSearch,
          onClear: widget.onClear,
          onSettingsTap: widget.onSettingsTap,
          selectedType: _selectedType,
          filterOptions: _filterOptions,
          onTypeChanged: (type) {
            setState(() => _selectedType = type);
            widget.onTypeChanged(type);
          },
        ),
      ),
    );
  }
}

/// 应用栏内容组件
class _AppBarContent extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final VoidCallback onClear;
  final VoidCallback onSettingsTap;
  final ContentType selectedType;
  final List<FilterOption> filterOptions;
  final Function(ContentType) onTypeChanged;

  const _AppBarContent({
    required this.searchController,
    required this.onSearch,
    required this.onClear,
    required this.onSettingsTap,
    required this.selectedType,
    required this.filterOptions,
    required this.onTypeChanged,
  });

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
              filterOptions: filterOptions,
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

/// 搜索框组件
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: 100),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        onChanged: onSearch,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: '搜索',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: onClear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }
}

/// 过滤栏组件
class _FilterBar extends StatelessWidget {
  final ContentType selectedType;
  final List<FilterOption> filterOptions;
  final Function(ContentType) onTypeChanged;

  const _FilterBar({
    required this.selectedType,
    required this.filterOptions,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: filterOptions.map((option) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _FilterChip(
            label: option.label,
            icon: option.icon,
            type: option.type,
            isSelected: selectedType == option.type,
            onSelected: onTypeChanged,
          ),
        );
      }).toList(),
    );
  }
}

/// 过滤器选项组件
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final ContentType type;
  final bool isSelected;
  final Function(ContentType) onSelected;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.type,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 72),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(type),
        selectedColor: Colors.blue,
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// 设置按钮组件
class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SettingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      constraints: const BoxConstraints(minWidth: 40),
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.settings),
      onPressed: onTap,
      tooltip: '设置',
    );
  }
}
