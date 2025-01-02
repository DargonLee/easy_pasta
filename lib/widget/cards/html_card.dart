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
      child: SingleChildScrollView(
        child: Html(
          data: htmlData,
          style: {
            "body": Style(
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
              backgroundColor: Colors.transparent,
              // 设置宽度和高度为100%以填充容器
              width: Width.auto(),
              height: Height.auto(),
            ),
            // 确保内部元素也能填充
            "div": Style(
              width: Width.auto(),
              height: Height.auto(),
              backgroundColor: Colors.transparent,
            ),
          },
        ),
      ),
    );
  }
}
