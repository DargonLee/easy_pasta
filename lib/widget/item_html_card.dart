import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class HtmlContent extends StatelessWidget {
  final String htmlData;
  final double? width;
  final double? height;
  final int maxLines;
  final double fontSize;

  const HtmlContent({
    Key? key,
    required this.htmlData,
    this.width,
    this.height,
    this.maxLines = 3,
    this.fontSize = 13,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width ?? double.infinity,
        maxHeight: height ?? double.infinity,
      ),
      child: HtmlWidget(
        htmlData,
        textStyle: TextStyle(
          fontSize: fontSize,
        ),
        customStylesBuilder: (element) {
          return {
            'display': '-webkit-box',
            '-webkit-line-clamp': '$maxLines',
            '-webkit-box-orient': 'vertical',
            'overflow': 'hidden',
            'text-overflow': 'ellipsis'
          };
        },
      ),
    );
  }
}
