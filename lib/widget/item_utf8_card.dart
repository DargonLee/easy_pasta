import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

class ItemUtf8Card extends StatelessWidget {
  final NSPboardTypeModel model;
  final bool isSelected;

  ItemUtf8Card({required this.model, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueAccent,width: isSelected ? 5.0 : 0.1,),
      ),
      child: Column(
        children: [
          Expanded(child: Text(
            model.pvalue,
          ),),
          Text(
            model.appname,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}