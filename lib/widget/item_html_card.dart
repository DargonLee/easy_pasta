import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:flutter_html/flutter_html.dart';

class ItemHTMLCard extends StatelessWidget {
  final NSPboardTypeModel model;
  final bool isSelected;

  ItemHTMLCard({required this.model, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        border: Border.all(color: Colors.blueAccent,width: isSelected ? 5.0 : 0.1,)
      ),
      child: Html(
        data: model.pvalue,
        extensions: [
          TagExtension(
            tagsToExtend: {"flutter"},
            child: const FlutterLogo(),
          ),
        ],
      ),
    );
  }
}
