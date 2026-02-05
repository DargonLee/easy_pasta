import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';

class AppBarSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;

  const AppBarSearchField({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<AppBarSearchField> createState() => _AppBarSearchFieldState();
}

class _AppBarSearchFieldState extends State<AppBarSearchField> {
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
