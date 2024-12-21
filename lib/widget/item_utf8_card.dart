import 'package:flutter/material.dart';

class TextContent extends StatelessWidget {
  final String text;
  final int maxLines;
  final double fontSize;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool selectable;

  const TextContent({
    Key? key,
    required this.text,
    this.maxLines = 3,
    this.fontSize = 13,
    this.style,
    this.textAlign = TextAlign.left,
    this.selectable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = style ??
        TextStyle(
          fontSize: fontSize,
          height: 1.2,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        );

    return selectable
        ? SelectableText(
            text,
            maxLines: maxLines,
            textAlign: textAlign,
            style: textStyle,
          )
        : Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: textStyle,
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
