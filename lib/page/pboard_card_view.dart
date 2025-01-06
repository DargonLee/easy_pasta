import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/widget/cards/image_card.dart';
import 'package:easy_pasta/widget/cards/file_card.dart';
import 'package:easy_pasta/widget/cards/text_card.dart';
import 'package:easy_pasta/widget/cards/footer_card.dart';
import 'package:easy_pasta/widget/cards/html_card.dart';
import 'package:easy_pasta/model/clipboard_type.dart';

class NewPboardItemCard extends StatelessWidget {
  final ClipboardItemModel model;
  final int selectedId;
  final Function(ClipboardItemModel) onTap;
  final Function(ClipboardItemModel) onDoubleTap;
  final Function(ClipboardItemModel) onCopy;
  final Function(ClipboardItemModel) onFavorite;
  final Function(ClipboardItemModel) onDelete;
  const NewPboardItemCard({
    Key? key,
    required this.model,
    required this.selectedId,
    required this.onTap,
    required this.onDoubleTap,
    required this.onCopy,
    required this.onFavorite,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == model.id;
    return RepaintBoundary(
      child: Card(
        elevation: isSelected ? 2 : 0,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTap(model),
          onDoubleTap: () => onDoubleTap(model),
          child: LayoutBuilder(builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 50,
                      maxHeight: constraints.maxHeight - 48,
                    ),
                    child: _buildContent(context),
                  ),
                  const Spacer(),
                  _buildFooter(context),
                ],
              ),
            );
          }),
        ),
      ),
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
          imageBytes: model.bytes ?? Uint8List(0),
        );
      case ClipboardType.file:
        return FileContent(
          fileName: model.pvalue,
          fileUri: model.bytesToString(model.bytes ?? Uint8List(0)),
        );
      case ClipboardType.html:
        return HtmlContent(
          htmlData: model.bytesToString(model.bytes ?? Uint8List(0)),
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
    return FooterContent(
      model: model,
      onCopy: onCopy,
      onFavorite: onFavorite,
      onDelete: onDelete,
    );
  }
}
