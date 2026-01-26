import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';

class TextContent extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool selectable;
  final int? maxLines;
  final String? highlight;

  const TextContent({
    super.key,
    required this.text,
    this.fontSize = 13,
    this.style,
    this.textAlign = TextAlign.left,
    this.selectable = false,
    this.maxLines,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle =
        style ?? (isDark ? AppTypography.darkBody : AppTypography.lightBody);

    return _buildNormalText(text, textStyle);
  }

  Widget _buildNormalText(String displayText, TextStyle style) {
    if (highlight == null || highlight!.isEmpty) {
      return selectable
          ? SelectableText(
              displayText,
              textAlign: textAlign,
              style: style,
              maxLines: maxLines,
            )
          : Text(
              displayText,
              textAlign: textAlign,
              softWrap: true,
              maxLines: maxLines,
              overflow: TextOverflow.fade,
              style: style,
            );
    }

    final lowerText = displayText.toLowerCase();
    final lowerHighlight = highlight!.toLowerCase();

    // 对于超长文本，仅对前 5000 字符进行高亮处理以保证性能
    final isTooLong = displayText.length > 5000;
    final processText =
        isTooLong ? displayText.substring(0, 5000) : displayText;
    final processLower = isTooLong ? lowerText.substring(0, 5000) : lowerText;

    final spells = <TextSpan>[];
    int start = 0;
    int indexOfHighlight;

    while ((indexOfHighlight = processLower.indexOf(lowerHighlight, start)) !=
        -1) {
      if (indexOfHighlight > start) {
        spells.add(
            TextSpan(text: processText.substring(start, indexOfHighlight)));
      }
      spells.add(TextSpan(
        text: processText.substring(
            indexOfHighlight, indexOfHighlight + highlight!.length),
        style: style.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        ),
      ));
      start = indexOfHighlight + highlight!.length;
    }

    if (start < processText.length) {
      spells.add(TextSpan(text: processText.substring(start)));
    }

    if (isTooLong) {
      spells.add(TextSpan(text: displayText.substring(5000)));
    }

    return Text.rich(
      TextSpan(children: spells, style: style),
      textAlign: textAlign,
      softWrap: true,
      maxLines: maxLines,
      overflow: TextOverflow.fade,
    );
  }

  /// 获取文本的预览内容
  String get previewText {
    if (text.length <= 100) return text;
    return '${text.substring(0, 97)}...';
  }

  /// 检查文本是否为空
  bool get isEmpty => text.trim().isEmpty;

  /// 获取文本的字数统计
  int get wordCount => text.trim().length;
}
