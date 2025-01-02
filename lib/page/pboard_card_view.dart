import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/widget/cards/tiff_card.dart';
import 'package:easy_pasta/widget/cards/file_card.dart';
import 'package:easy_pasta/widget/cards/text_card.dart';
import 'package:easy_pasta/widget/cards/footer_card.dart';
import 'package:easy_pasta/widget/cards/header.card.dart';
import 'package:easy_pasta/widget/cards/html_card.dart';
import 'package:easy_pasta/model/clipboard_type.dart';

class NewPboardItemCard extends StatelessWidget {
  final ClipboardItemModel model;
  final int selectedId;
  final Function(ClipboardItemModel) onTap;
  final Function(ClipboardItemModel) onDoubleTap;
  final Function(ClipboardItemModel) onCopy;
  const NewPboardItemCard({
    Key? key,
    required this.model,
    required this.selectedId,
    required this.onTap,
    required this.onDoubleTap,
    required this.onCopy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == model.id;

    return RepaintBoundary(
        child: Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.all(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(model),
        onDoubleTap: () => onDoubleTap(model),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Expanded(child: _buildContent(context)),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildHeader(BuildContext context) {
    return HeaderContent(
      typeIcon: TypeIconHelper.getTypeIcon(
        model.ptype ?? ClipboardType.unknown,
        pvalue: model.pvalue,
      ),
      iconSize: 14,
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _buildContentByType(context),
    );
  }

  Widget _buildContentByType(BuildContext context) {
    switch (model.ptype) {
      case ClipboardType.image:
        return ImageContent(
          imageBytes: model.imageBytes ?? Uint8List(0),
        );
      case ClipboardType.file:
        return FileContent(
          filePath: model.pvalue,
        );
      case ClipboardType.html:
        return HtmlContent(
          htmlData: model.pvalue,
        );
      case ClipboardType.unknown:
        return const TextContent(
          text: 'Unknown',
        );
      default:
        return TextContent(
          text: model.pvalue,
        );
    }
  }

  Widget _buildFooter(BuildContext context) {
    return TimestampContent(
      model: model,
      onCopy: onCopy,
    );
  }
}
