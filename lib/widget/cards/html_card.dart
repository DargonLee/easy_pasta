import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class HtmlContent extends StatelessWidget {
  final String htmlData;

  const HtmlContent({
    Key? key,
    required this.htmlData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Html(
      shrinkWrap: true,
      data: htmlData,
      style: {
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
      },
    );
  }
}
