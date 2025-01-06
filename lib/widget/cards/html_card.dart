import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class HtmlContent extends StatelessWidget {
  static final Map<String, Style> _defaultStyles = {
    "body": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      width: Width.auto(),
    ),
    "pre": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      fontFamily: "monospace",
      backgroundColor: Colors.transparent,
    ),
    "code": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      display: Display.block,
      backgroundColor: Colors.transparent,
    ),
    "span": Style(
      lineHeight: const LineHeight(1.2),
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      backgroundColor: Colors.transparent,
    ),
    "div": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      backgroundColor: Colors.transparent,
    ),
  };

  final String htmlData;

  const HtmlContent({
    super.key,
    required this.htmlData,
  });

  @override
  Widget build(BuildContext context) {
    return Html(
      shrinkWrap: true,
      data: htmlData,
      style: _defaultStyles,
      onLinkTap: (url, _, __) {
        if (url != null) {
          launchUrl(Uri.parse(url));
        }
      },
    );
  }
}
