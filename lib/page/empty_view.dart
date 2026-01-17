import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';
import 'package:easy_pasta/core/animation_helper.dart';
import 'package:easy_pasta/widget/category_empty_state.dart';

class EmptyStateView extends StatelessWidget {
  final NSPboardSortType category;
  
  const EmptyStateView({
    super.key,
    this.category = NSPboardSortType.all,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryEmptyState(category: category);
  }
}
