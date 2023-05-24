import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:flutter_html/flutter_html.dart';

class ItemHTMLCard extends StatelessWidget {
  final NSPboardTypeModel model;

  ItemHTMLCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Html(
          data: model.pvalue,
          extensions: [
            TagExtension(
              tagsToExtend: {"flutter"},
              child: const FlutterLogo(),
            ),
          ],
        ),
      ),
    );
  }
}
