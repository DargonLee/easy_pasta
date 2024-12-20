import 'package:flutter/material.dart';

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
  Size get preferredSize => const Size.fromHeight(110);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  ContentType _selectedType = ContentType.all;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTopBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSearchField(),
          ),
          Expanded(
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
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: widget.searchController,
        onChanged: widget.onSearch,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '搜索',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: widget.searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: widget.onClear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: widget.onSettingsTap,
      tooltip: '设置',
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
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
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required ContentType type,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;
    return FilterChip(
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
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      showCheckmark: false,
    );
  }
}
