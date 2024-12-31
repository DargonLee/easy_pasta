import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/widget/cards/tiff_card.dart';
import 'package:easy_pasta/widget/cards/file_card.dart';
import 'package:easy_pasta/widget/cards/text_card.dart';
import 'package:easy_pasta/widget/cards/footer_card.dart';
import 'package:easy_pasta/widget/cards/header.card.dart';
import 'package:easy_pasta/widget/cards/html_card.dart';
import 'package:easy_pasta/widget/cards/source_card.dart';

class NewPboardItemCard extends StatelessWidget {
  final NSPboardTypeModel model;
  final int selectedId;
  final Function(NSPboardTypeModel) onTap;
  final Function(NSPboardTypeModel) onDoubleTap;
  final Function(NSPboardTypeModel) onCopy;
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
        model.ptype,
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
      case 'tiff':
        return ImageContent(
          imageBytes: model.tiffbytes!,
          borderRadius: 8.0,
          fit: BoxFit.cover,
        );
      case 'file':
        return FileContent(
          filePath: model.pvalue,
          iconSize: 16,
          maxLines: 2,
          fontSize: 13,
        );
      case 'rtf':
      case 'html':
        return HtmlContent(
          htmlData: model.pvalue,
        );
      case 'source_code':
        return SourceCodeContent(
          code: model.pvalue,
        );
      default:
        return TextContent(
          text: model.pvalue,
          maxLines: 3,
          fontSize: 13,
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