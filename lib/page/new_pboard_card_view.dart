import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/widget/item_tiff_card.dart';
import 'package:easy_pasta/widget/item_url_card.dart';
import 'package:easy_pasta/widget/item_file_card.dart';
import 'package:easy_pasta/widget/item_utf8_card.dart';
import 'package:easy_pasta/widget/item_footer_card.dart';
import 'package:easy_pasta/widget/item_header.card.dart';
import 'package:easy_pasta/widget/item_html_card.dart';

class NewPboardItemCard extends StatelessWidget {
  final NSPboardTypeModel model;
  final int selectedId;
  final Function(NSPboardTypeModel) onTap;
  final Function(NSPboardTypeModel) onDoubleTap;

  const NewPboardItemCard({
    Key? key,
    required this.model,
    required this.selectedId,
    required this.onTap,
    required this.onDoubleTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == model.id;
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: isSelected ? 2 : 0,
          margin: const EdgeInsets.all(4),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.8)
              : theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
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
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return HeaderContent(
      typeIcon: TypeIconHelper.getTypeIcon(
        model.ptype,
        pvalue: model.pvalue,
      ),
      appIcon: model.appicon,
      appName: model.appname,
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
      case 'url':
        return URLContent(
          url: model.pvalue,
          maxLines: 2,
          fontSize: 13,
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
      timestamp: model.time,
      fontSize: 10,
    );
  }
}
