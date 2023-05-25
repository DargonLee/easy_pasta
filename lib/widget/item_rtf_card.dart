import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:flutter_html/flutter_html.dart';

class ItemRtfCard extends StatelessWidget {
  final NSPboardTypeModel model;
  final bool isSelected;

  ItemRtfCard({required this.model, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 16, 10, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueAccent,width: isSelected ? 5.0 : 0.1,),
      ),
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