import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class HtmlContent extends StatelessWidget {
  final String htmlData;
  final double? width;
  final double? height;

  const HtmlContent({
    Key? key,
    required this.htmlData,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: HtmlWidget(
          htmlData,
        ),
      ),
    );
  }
}
