import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TextContent extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool selectable;

  const TextContent({
    Key? key,
    required this.text,
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

    // 检查是否为URL
    final urlPattern = RegExp(
      r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
      caseSensitive: false,
    );

    if (urlPattern.hasMatch(text)) {
      return InkWell(
        onTap: () => _launchURL(text),
        child: Text(
          text,
          textAlign: textAlign,
          softWrap: true,
          style: textStyle.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    final textWidget = selectable
        ? SelectableText(
            text,
            textAlign: textAlign,
            style: textStyle,
          )
        : Text(
            text,
            textAlign: textAlign,
            softWrap: true,
            style: textStyle,
          );

    return textWidget;
  }

  /// 打开URL
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
