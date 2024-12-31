import 'package:flutter/material.dart';

enum NSPboardSortType { all, text, image, file, favorite }

typedef FilterOption = ({String label, IconData icon, NSPboardSortType type});
final filterOptions = [
  (label: '全部', icon: Icons.all_inclusive, type: NSPboardSortType.all),
  (label: '文本', icon: Icons.text_fields, type: NSPboardSortType.text),
  (label: '图片', icon: Icons.image, type: NSPboardSortType.image),
  (label: '文件', icon: Icons.folder, type: NSPboardSortType.file),
  (label: '收藏', icon: Icons.favorite, type: NSPboardSortType.favorite),
];