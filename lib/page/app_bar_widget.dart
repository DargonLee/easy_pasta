import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

enum ContentType { all, text, image, file, favorite }

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
        child: _buildTopBar(),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildSearchField(),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _buildFilterBar(),
          ),
          const SizedBox(width: 8),
          _buildSettingsButton(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: 100),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: widget.searchController,
        onChanged: widget.onSearch,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: '搜索',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: widget.searchController.text.isNotEmpty
              ? IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: widget.onClear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return IconButton(
      constraints: const BoxConstraints(minWidth: 40),
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.settings),
      onPressed: widget.onSettingsTap,
      tooltip: '设置',
    );
  }

  Widget _buildFilterBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFilterChip(
          label: '全部',
          type: ContentType.all,
          icon: Icons.all_inclusive,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          label: '文本',
          type: ContentType.text,
          icon: Icons.text_fields,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          label: '图片',
          type: ContentType.image,
          icon: Icons.image,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          label: '文件',
          type: ContentType.file,
          icon: Icons.folder,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          label: '收藏',
          type: ContentType.favorite,
          icon: Icons.favorite,
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required ContentType type,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;
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
        onSelected: (bool selected) {
          setState(() => _selectedType = type);
          widget.onTypeChanged(type);
        },
        selectedColor: Colors.blue,
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
