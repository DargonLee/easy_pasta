import 'package:flutter/material.dart';
import 'package:easy_pasta/widget/item_utf8_card.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/pasteboard_type.dart';
import 'package:easy_pasta/widget/item_html_card.dart';
import 'package:easy_pasta/widget/item_tiff_card.dart';
import 'package:easy_pasta/widget/item_rtf_card.dart';
import 'package:easy_pasta/widget/item_file_card.dart';

class ItemCard extends StatelessWidget {
  final NSPboardTypeModel model;
  final int selectedId;

  ItemCard({required this.model, this.selectedId = 0});

  @override
  Widget build(BuildContext context) {
    Widget itemCard;
    bool isSelected = selectedId == model.id?.toInt();
    if (model.ptype == NSPboardType.stringType.name) {
      itemCard = ItemUtf8Card(model: model, isSelected: isSelected,);
    } else if (model.ptype == NSPboardType.htmlType.name) {
      itemCard = ItemHTMLCard(model: model, isSelected: isSelected,);
    }else if (model.ptype == NSPboardType.rtfType.name) {
      itemCard = ItemRtfCard(model: model, isSelected: isSelected,);
    }else if (model.ptype == NSPboardType.textRtfType.name) {
      itemCard = ItemRtfCard(model: model, isSelected: isSelected,);
    }else if (model.ptype == NSPboardType.tiffType.name) {
      itemCard = ItemTiffCard(model: model, isSelected: isSelected,);
    }else if (model.ptype == NSPboardType.fileUrlType.name) {
      itemCard = ItemFileCard(model: model, isSelected: isSelected,);
    }else if (model.ptype == NSPboardType.pngType.name) {
      itemCard = ItemUtf8Card(model: model);
    }else if (model.ptype == NSPboardType.appleNotesTypeType.name) {
      itemCard = ItemUtf8Card(model: model);
    }else {
      itemCard = Container(
        alignment: Alignment.center,
        child: const Text('Not support this type card'),
      );
    }

    return itemCard;
  }
}