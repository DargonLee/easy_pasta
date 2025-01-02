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
    return Expanded(
      child: Html(
        shrinkWrap: true,
        data: htmlData,
        style: {
          "pre": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontFamily: "monospace",
          ),
          "code": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            display: Display.block,
          ),
          "span": Style(
            lineHeight: const LineHeight(1.2),
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
        },
      ),
    );
  }
}
