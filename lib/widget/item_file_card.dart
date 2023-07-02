import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/widget/animation_widget.dart';

class ItemFileCard extends StatelessWidget {
  final NSPboardTypeModel model;
  final bool isSelected;

  ItemFileCard({required this.model, this.isSelected = false});

  bool get isfile {
    // bool result = FileSystemEntity.isFileSync(model.pvalue);
    bool result = model.pvalue.contains('.');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ItemAnimationWidget(
      isSelected: isSelected,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
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
            Expanded(
              child: Text(
                model.pvalue,
                maxLines: 3,
              ),
            ),
            Icon(
              isfile ? Icons.file_open : Icons.folder,
            ),
            Text(
              model.appname,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
