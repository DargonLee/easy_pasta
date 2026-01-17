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
import 'package:easy_pasta/model/grid_density.dart';

class NewPboardItemCard extends StatefulWidget {
  final ClipboardItemModel model;
  final String selectedId;
  final Function(ClipboardItemModel) onTap;
  final Function(ClipboardItemModel) onDoubleTap;
  final Function(ClipboardItemModel) onCopy;
  final Function(ClipboardItemModel) onFavorite;
  final Function(ClipboardItemModel) onDelete;
  final GridDensity density;
  final bool showFocus;
  
  const NewPboardItemCard({
    Key? key,
    required this.model,
    required this.selectedId,
    required this.onTap,
    required this.onDoubleTap,
    required this.onCopy,
    required this.onFavorite,
    required this.onDelete,
    required this.density,
    this.showFocus = false,
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
    final spec = widget.density.spec;
    final isElevated = _isHovered || isSelected;
    final showFocus = widget.showFocus;
    final borderColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkFrostedBorder : AppColors.lightFrostedBorder);
    final focusRingColor =
        AppColors.primary.withOpacity(isDark ? 0.4 : 0.25);
    final baseShadows = isDark
        ? (isElevated ? AppShadows.darkSm : AppShadows.none)
        : (isElevated ? AppShadows.md : AppShadows.sm);
    final shadows = <BoxShadow>[
      ...baseShadows,
      if (showFocus)
        BoxShadow(
          color: focusRingColor,
          blurRadius: 0,
          spreadRadius: 2,
        ),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: RepaintBoundary(
        child: AnimatedScale(
          scale: isElevated ? 1.01 : 1.0,
          duration: AppDurations.fast,
          curve: AppCurves.standard,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppCurves.standard,
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppGradients.darkCardSheen
                  : AppGradients.lightCardSheen,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: shadows,
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
                  padding: EdgeInsets.all(spec.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildContent(context)),
                      const SizedBox(height: AppSpacing.xs),
                      _buildFooter(
                        context,
                        showActions: isElevated || showFocus,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final density = widget.density;
    final contentPadding = density == GridDensity.compact ? 2.0 : 4.0;
    return Container(
      padding: EdgeInsets.symmetric(vertical: contentPadding),
      child: _buildContentByType(context),
    );
  }

  Widget _buildContentByType(BuildContext context) {
    final spec = widget.density.spec;
    switch (widget.model.ptype) {
      case ClipboardType.image:
        return ImageContent(
          imageBytes: widget.model.bytes ?? Uint8List(0),
          borderRadius: spec.imageRadius,
        );
      case ClipboardType.file:
        return FileContent(
          fileName: widget.model.pvalue,
          fileUri: widget.model.bytesToString(widget.model.bytes ?? Uint8List(0)),
        );
      case ClipboardType.html:
        return HtmlContent(
          htmlData: widget.model.bytesToString(widget.model.bytes ?? Uint8List(0)),
          maxLines: spec.maxTextLines,
        );
      case ClipboardType.unknown:
        return TextContent(
          text: 'Unknown',
          maxLines: spec.maxTextLines,
        );
      default:
        return TextContent(
          text: widget.model.pvalue,
          maxLines: spec.maxTextLines,
        );
    }
  }

  Widget _buildFooter(BuildContext context, {required bool showActions}) {
    return FooterContent(
      model: widget.model,
      onCopy: widget.onCopy,
      onFavorite: widget.onFavorite,
      onDelete: widget.onDelete,
      showActions: showActions,
      compact: widget.density == GridDensity.compact,
    );
  }
}
