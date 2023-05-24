import 'dart:typed_data';
import 'package:image/image.dart' as imgLib;
import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

class ItemTiffCard extends StatelessWidget {

  final NSPboardTypeModel model;

  ItemTiffCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(image: MemoryImage(model.tiffbytes!)),
      ),
    );
  }
}