import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'dart:convert';

class JsonCardContent extends StatefulWidget {
  final String jsonText;
  final String? rootType;
  final int maxLines;

  const JsonCardContent({
    super.key,
    required this.jsonText,
    this.rootType,
    this.maxLines = 4,
  });

  @override
  State<JsonCardContent> createState() => _JsonCardContentState();
}

class _JsonCardContentState extends State<JsonCardContent> {
  late String _formatted;

  @override
  void initState() {
    super.initState();
    _formatted = _formatJsonSnippet(widget.jsonText);
  }

  @override
  void didUpdateWidget(covariant JsonCardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jsonText != widget.jsonText) {
      _formatted = _formatJsonSnippet(widget.jsonText);
    }
  }

  String _formatJsonSnippet(String json) {
    try {
      final decoded = jsonDecode(json);
      const encoder = JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(decoded);
      return formatted;
    } catch (_) {
      return json;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badgeColor = isDark
        ? AppColors.darkSecondaryBackground.withValues(alpha: 0.8)
        : AppColors.lightSecondaryBackground.withValues(alpha: 0.8);
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.4)
        : AppColors.lightBorder.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                'JSON ${widget.rootType ?? ''}'.trim().toUpperCase(),
                style: (isDark
                        ? AppTypography.darkCaption
                        : AppTypography.lightCaption)
                    .copyWith(
                  fontWeight: AppFontWeights.semiBold,
                  letterSpacing: 0.4,
                  color: AppColors.primary,
                ),
              ),
            ),
            const Spacer(),
            const Icon(Icons.data_object, size: 14, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              _formatted,
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
              style: (isDark
                      ? AppTypography.darkMonospace
                      : AppTypography.lightMonospace)
                  .copyWith(fontSize: 11, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
