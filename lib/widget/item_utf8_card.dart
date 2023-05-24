import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

class ItemUtf8Card extends StatelessWidget {
  final NSPboardTypeModel model;

  ItemUtf8Card({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 16, 10, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: SingleChildScrollView(
        child: Text(
          model.pvalue,
        ),
      ),
    );
  }
}