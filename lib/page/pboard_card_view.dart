import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/widget/cards/image_card.dart';
import 'package:easy_pasta/widget/cards/file_card.dart';
import 'package:easy_pasta/widget/cards/text_card.dart';
import 'package:easy_pasta/widget/cards/footer_card.dart';
import 'package:easy_pasta/widget/cards/html_card.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/model/design_tokens.dart';

class NewPboardItemCard extends StatefulWidget {
  final ClipboardItemModel model;
  final String selectedId;
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
  State<NewPboardItemCard> createState() => _NewPboardItemCardState();
}

class _NewPboardItemCardState extends State<NewPboardItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedId == widget.model.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: RepaintBoundary(
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.standard,
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.darkCardBackground 
                : AppColors.lightCardBackground,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: isSelected
                ? Border.all(
                    color: AppColors.primary,
                    width: 2,
                  )
                : Border.all(
                    color: isDark 
                        ? AppColors.darkBorder.withOpacity(0.3)
                        : AppColors.lightBorder.withOpacity(0.3),
                    width: 1,
                  ),
            boxShadow: _isHovered || isSelected ? AppShadows.md : AppShadows.sm,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTap(widget.model);
              },
              onDoubleTap: () {
                HapticFeedback.mediumImpact();
                widget.onDoubleTap(widget.model);
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: 50,
                              maxHeight: constraints.maxHeight - 28,
                            ),
                            child: _buildContent(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _buildFooter(context),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
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
    switch (widget.model.ptype) {
      case ClipboardType.image:
        return ImageContent(
          imageBytes: widget.model.bytes ?? Uint8List(0),
        );
      case ClipboardType.file:
        return FileContent(
          fileName: widget.model.pvalue,
          fileUri: widget.model.bytesToString(widget.model.bytes ?? Uint8List(0)),
        );
      case ClipboardType.html:
        return HtmlContent(
          htmlData: widget.model.bytesToString(widget.model.bytes ?? Uint8List(0)),
        );
      case ClipboardType.unknown:
        return const TextContent(
          text: 'Unknown',
        );
      default:
        return TextContent(
          text: widget.model.pvalue,
        );
    }
  }

  Widget _buildFooter(BuildContext context) {
    return FooterContent(
      model: widget.model,
      onCopy: widget.onCopy,
      onFavorite: widget.onFavorite,
      onDelete: widget.onDelete,
    );
  }
}
