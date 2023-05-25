import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

class ItemFileCard extends StatelessWidget {
  final NSPboardTypeModel model;
  final bool isSelected;

  ItemFileCard({required this.model, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 16, 10, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blueAccent,
          width: isSelected ? 5.0 : 0.1,
        ),
      ),
      child: Column(
        children: [
          Text(
            model.pvalue,
            maxLines: 3,
          ),
          const Expanded(
            flex: 1,
            child: Icon(
              Icons.folder,
              size: 100,
              color: Colors.blue,
            ),
          )
        ],
      ),
    );
  }
}
