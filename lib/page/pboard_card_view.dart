import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/widget/cards/file_card.dart';
import 'package:easy_pasta/widget/cards/text_card.dart';
import 'package:easy_pasta/widget/cards/footer_card.dart';
import 'package:easy_pasta/widget/cards/html_card.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/model/content_classification.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/model/grid_density.dart';
import 'package:easy_pasta/widget/source_app_badge.dart';
import 'package:easy_pasta/widget/cards/url_card.dart';
import 'package:easy_pasta/widget/cards/command_card.dart';
import 'package:easy_pasta/widget/cards/json_card.dart';

class NewPboardItemCard extends StatefulWidget {
  final ClipboardItemModel model;
  final String selectedId;
  final Function(ClipboardItemModel) onTap;
  final Function(ClipboardItemModel) onDoubleTap;
  final Function(ClipboardItemModel) onCopy;
  final Function(ClipboardItemModel) onFavorite;
  final Function(ClipboardItemModel) onDelete;
  final GridDensity density;
  final bool enableHover;
  final bool showFocus;
  final String? highlight;
  final int? badgeIndex;

  const NewPboardItemCard({
    super.key,
    required this.model,
    required this.selectedId,
    required this.onTap,
    required this.onDoubleTap,
    required this.onCopy,
    required this.onFavorite,
    required this.onDelete,
    required this.density,
    this.enableHover = true,
    this.showFocus = false,
    this.highlight,
    this.badgeIndex,
  });

  @override
  State<NewPboardItemCard> createState() => _NewPboardItemCardState();
}

class _NewPboardItemCardState extends State<NewPboardItemCard> {
  bool _isHovered = false;
  bool _showPulse = false;

  static const _pulseDuration = Duration(milliseconds: 400);

  void _triggerPulse() {
    if (!mounted) return;
    setState(() => _showPulse = true);
    Future.delayed(_pulseDuration, () {
      if (mounted) setState(() => _showPulse = false);
    });
  }

  void _handleHoverChange(bool isHovered) {
    if (!widget.enableHover || _isHovered == isHovered) return;
    setState(() => _isHovered = isHovered);
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedId == widget.model.id;
    final isElevated = (widget.enableHover && _isHovered) || isSelected;

    final card = _CardContainer(
      isSelected: isSelected,
      isElevated: isElevated,
      showPulse: _showPulse,
      model: widget.model,
      density: widget.density,
      highlight: widget.highlight,
      showFocus: widget.showFocus,
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap(widget.model);
      },
      onDoubleTap: () {
        HapticFeedback.mediumImpact();
        _triggerPulse();
        widget.onDoubleTap(widget.model);
      },
      onCopy: widget.onCopy,
      onFavorite: widget.onFavorite,
      onDelete: widget.onDelete,
      onSuccess: _triggerPulse,
    );

    if (!widget.enableHover) {
      return card;
    }

    return MouseRegion(
      onEnter: (_) => _handleHoverChange(true),
      onExit: (_) => _handleHoverChange(false),
      child: card,
    );
  }
}

// ============================================================================
// 卡片容器 - 独立渲染单元
// ============================================================================

class _CardContainer extends StatelessWidget {
  final bool isSelected;
  final bool isElevated;
  final bool showPulse;
  final ClipboardItemModel model;
  final GridDensity density;
  final String? highlight;
  final bool showFocus;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final Function(ClipboardItemModel) onCopy;
  final Function(ClipboardItemModel) onFavorite;
  final Function(ClipboardItemModel) onDelete;
  final VoidCallback onSuccess;

  const _CardContainer({
    required this.isSelected,
    required this.isElevated,
    required this.showPulse,
    required this.model,
    required this.density,
    required this.highlight,
    required this.showFocus,
    required this.onTap,
    required this.onDoubleTap,
    required this.onCopy,
    required this.onFavorite,
    required this.onDelete,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkFrostedBorder : AppColors.lightFrostedBorder);

    final focusRingColor =
        AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25);
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

    return RepaintBoundary(
      child: AnimatedScale(
        scale: isElevated ? 1.01 : 1.0,
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.standard,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardBackground
                : AppColors.lightCardBackground,
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
              onTap: onTap,
              onDoubleTap: onDoubleTap,
              child: _CardContentLayout(
                model: model,
                density: density,
                highlight: highlight,
                isElevated: isElevated,
                showPulse: showPulse,
                onCopy: onCopy,
                onFavorite: onFavorite,
                onDelete: onDelete,
                onSuccess: onSuccess,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 内容布局组件
// ============================================================================

class _CardContentLayout extends StatelessWidget {
  final ClipboardItemModel model;
  final GridDensity density;
  final String? highlight;
  final bool isElevated;
  final bool showPulse;
  final Function(ClipboardItemModel) onCopy;
  final Function(ClipboardItemModel) onFavorite;
  final Function(ClipboardItemModel) onDelete;
  final VoidCallback onSuccess;

  const _CardContentLayout({
    required this.model,
    required this.density,
    required this.highlight,
    required this.isElevated,
    required this.showPulse,
    required this.onCopy,
    required this.onFavorite,
    required this.onDelete,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final spec = density.spec;
    final sourceAppId = model.sourceAppId;
    final showSourceBadge =
        sourceAppId != null && sourceAppId.trim().isNotEmpty;

    final badgeSize = density == GridDensity.compact
        ? 16.0
        : density == GridDensity.spacious
            ? 20.0
            : 18.0;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(spec.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: RepaintBoundary(
                  child: _ContentArea(
                    model: model,
                    density: density,
                    highlight: highlight,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              FooterContent(
                model: model,
                onCopy: onCopy,
                onFavorite: onFavorite,
                onDelete: onDelete,
                showActions: isElevated,
                compact: density == GridDensity.compact,
                onSuccess: onSuccess,
              ),
            ],
          ),
        ),
        if (showSourceBadge)
          Positioned(
            top: 4,
            right: 4,
            child: IgnorePointer(
              child: SourceAppBadge(
                bundleId: sourceAppId,
                size: badgeSize,
              ),
            ),
          ),
        if (showPulse)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// 内容核心区域 - 隔离频繁变化的逻辑
// ============================================================================

class _ContentArea extends StatelessWidget {
  final ClipboardItemModel model;
  final GridDensity density;
  final String? highlight;

  const _ContentArea({
    required this.model,
    required this.density,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final contentPadding = density == GridDensity.compact ? 2.0 : 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight =
            (constraints.maxHeight - (contentPadding * 2)).clamp(0.0, 10000.0);

        return Container(
          padding: EdgeInsets.symmetric(vertical: contentPadding),
          child: _buildContentByType(context, availableHeight),
        );
      },
    );
  }

  int _calculateMaxLines(TextStyle style, double height) {
    final fontSize = style.fontSize ?? 13;
    final lineHeight = fontSize * (style.height ?? 1.2);
    if (lineHeight <= 0) return 1;
    final lines = (height / lineHeight).floor();
    return lines < 1 ? 1 : lines;
  }

  Widget _buildContentByType(BuildContext context, double availableHeight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseStyle = isDark ? AppTypography.darkBody : AppTypography.lightBody;
    final textLines = _calculateMaxLines(baseStyle, availableHeight);

    switch (model.ptype) {
      case ClipboardType.image:
        return _ImagePreview(model: model);

      case ClipboardType.file:
        return FileContent(
          fileName: model.pvalue,
          fileUri: model.bytesToString(model.bytes ?? Uint8List(0)),
        );

      case ClipboardType.html:
        return _buildHtmlContent(baseStyle, textLines, availableHeight);

      case ClipboardType.text:
        return _buildTextContent(baseStyle, textLines);

      default:
        return TextContent(
          text: model.pvalue,
          style: baseStyle,
          highlight: highlight,
          maxLines: textLines,
        );
    }
  }

  Widget _buildHtmlContent(
      TextStyle baseStyle, int textLines, double availableHeight) {
    final classification = model.classification;

    if (classification?.kind == ContentKind.url) {
      return _buildUrlContent(classification);
    }

    if (classification?.kind == ContentKind.command) {
      return CommandContent(
        commandText: model.pvalue,
        maxLines: textLines,
      );
    }

    final htmlLines = _calculateMaxLines(
      baseStyle.copyWith(height: 1.5),
      availableHeight,
    );

    return HtmlContent(
      htmlData: model.bytesToString(model.bytes ?? Uint8List(0)),
      fallbackText: model.pvalue,
      maxLines: htmlLines,
    );
  }

  Widget _buildTextContent(TextStyle baseStyle, int textLines) {
    final classification = model.classification;

    if (classification?.kind == ContentKind.url) {
      return _buildUrlContent(classification);
    }

    if (classification?.kind == ContentKind.json) {
      return JsonCardContent(
        jsonText: model.pvalue,
        rootType: classification?.metadata?['jsonRoot'] as String?,
        maxLines: textLines,
      );
    }

    if (classification?.kind == ContentKind.command) {
      return CommandContent(
        commandText: model.pvalue,
        maxLines: textLines,
      );
    }

    return TextContent(
      text: model.pvalue,
      style: baseStyle,
      highlight: highlight,
      maxLines: textLines,
    );
  }

  Widget _buildUrlContent(ContentClassification? classification) {
    final normalized = classification?.metadata?['normalizedUrl'];
    return UrlContent(
      urlText: model.pvalue,
      normalizedUrl:
          normalized is String && normalized.isNotEmpty ? normalized : null,
    );
  }
}

// ============================================================================
// 图片预览 - 独立并优化
// ============================================================================

class _ImagePreview extends StatelessWidget {
  final ClipboardItemModel model;
  const _ImagePreview({required this.model});

  static const _fallbackIconSize = 48.0;
  static const _cacheWidth = 800;

  @override
  Widget build(BuildContext context) {
    // 优先使用 bytes，如果没有则使用 thumbnail
    final imageData = model.bytes ?? model.thumbnail;
    if (imageData == null || imageData.isEmpty) {
      return _buildFallbackIcon(context);
    }

    return Image.memory(
      imageData,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: _cacheWidth,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(context),
    );
  }

  Widget _buildFallbackIcon(BuildContext context) {
    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: _fallbackIconSize,
        color: Theme.of(context).disabledColor,
      ),
    );
  }
}
