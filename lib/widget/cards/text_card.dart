import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/core/content_processor.dart';

class TextContent extends StatelessWidget {
  static final _urlPattern = RegExp(
    r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
    caseSensitive: false,
  );

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

    // 清理文本内容
    final cleanedText = ContentProcessor.cleanText(text);

    // 检查是否为URL
    return _urlPattern.hasMatch(cleanedText)
        ? _buildUrlText(cleanedText, textStyle, isDark)
        : _buildNormalText(cleanedText, textStyle);
  }

  Widget _buildUrlText(String urlText, TextStyle baseStyle, bool isDark) {
    final effectiveLines = maxLines ?? 3;
    final urlLines = effectiveLines < 3 ? effectiveLines : 3;
    return InkWell(
      onTap: () => _launchURL(urlText),
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Text(
          urlText.length > 500 ? '${urlText.substring(0, 497)}...' : urlText,
          textAlign: textAlign,
          softWrap: true,
          maxLines: urlLines,
          overflow: TextOverflow.ellipsis,
          style: baseStyle.copyWith(
            color: AppColors.primary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primary,
          ),
        ),
      ),
    );
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
    final spells = <TextSpan>[];
    int start = 0;
    int indexOfHighlight;

    while (
        (indexOfHighlight = lowerText.indexOf(lowerHighlight, start)) != -1) {
      if (indexOfHighlight > start) {
        spells.add(
            TextSpan(text: displayText.substring(start, indexOfHighlight)));
      }
      spells.add(TextSpan(
        text: displayText.substring(
            indexOfHighlight, indexOfHighlight + highlight!.length),
        style: style.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        ),
      ));
      start = indexOfHighlight + highlight!.length;
    }

    if (start < displayText.length) {
      spells.add(TextSpan(text: displayText.substring(start)));
    }

    return Text.rich(
      TextSpan(children: spells, style: style),
      textAlign: textAlign,
      softWrap: true,
      maxLines: maxLines,
      overflow: TextOverflow.fade,
    );
  }

  /// 打开URL
  Future<void> _launchURL(String url) async {
    // Ensure the URL has a scheme; default to https if missing
    String fixedUrl = url.trim();
    if (!fixedUrl.contains('://')) {
      fixedUrl = 'https://$fixedUrl';
    }
    final uri = Uri.parse(fixedUrl);
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
