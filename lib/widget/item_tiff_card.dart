import 'dart:typed_data';
import 'package:image/image.dart' as imgLib;
import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

class ItemTiffCard extends StatelessWidget {

  final NSPboardTypeModel model;
  final bool isSelected;

  ItemTiffCard({required this.model, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blueAccent,width: isSelected ? 5.0 : 0.1,),
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(image: MemoryImage(model.tiffbytes!)),
      ),
    );
  }
}