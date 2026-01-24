import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/widget/cards/file_card.dart';
import 'package:easy_pasta/widget/cards/text_card.dart';
import 'package:easy_pasta/widget/cards/footer_card.dart';
import 'package:easy_pasta/widget/cards/html_card.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/model/grid_density.dart';
import 'package:easy_pasta/widget/source_app_badge.dart';

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
    this.enableHover = true,
    this.showFocus = false,
    this.highlight,
  }) : super(key: key);

  @override
  State<NewPboardItemCard> createState() => _NewPboardItemCardState();
}

class _NewPboardItemCardState extends State<NewPboardItemCard> {
  bool _isHovered = false;
  bool _showPulse = false; // 新增脉冲状态

  void _triggerPulse() {
    if (!mounted) return;
    setState(() => _showPulse = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showPulse = false);
    });
  }

  @override
  void didUpdateWidget(covariant NewPboardItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enableHover && _isHovered) {
      _isHovered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedId == widget.model.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = widget.density.spec;
    final isHovered = widget.enableHover && _isHovered;
    final isElevated = isHovered || isSelected;
    final showFocus = widget.showFocus;
    final sourceAppId = widget.model.sourceAppId;
    final showSourceBadge =
        sourceAppId != null && sourceAppId.trim().isNotEmpty;
    final badgeSize = widget.density == GridDensity.compact
        ? 16.0
        : widget.density == GridDensity.spacious
            ? 20.0
            : 18.0;
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

    return MouseRegion(
      onEnter:
          widget.enableHover ? (_) => setState(() => _isHovered = true) : null,
      onExit:
          widget.enableHover ? (_) => setState(() => _isHovered = false) : null,
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
                  _triggerPulse();
                  widget.onDoubleTap(widget.model);
                },
                child: Stack(
                  children: [
                    // 背景脉冲阴影动画
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        boxShadow: [
                          if (_showPulse)
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(spec.cardPadding),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _buildContent(context)),
                                const SizedBox(height: AppSpacing.xs),
                                _buildFooter(
                                  context,
                                  showActions: true,
                                ),
                              ],
                            ),
                          ),
                          if (showSourceBadge)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IgnorePointer(
                                child: SourceAppBadge(
                                  bundleId: sourceAppId,
                                  size: badgeSize,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 前景脉冲边框动画
                    if (_showPulse)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 400),
                            opacity: _showPulse ? 0 : 1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.card),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight =
            (constraints.maxHeight - (contentPadding * 2)).clamp(0.0, 10000.0);
        return Container(
          padding: EdgeInsets.symmetric(vertical: contentPadding),
          child: _buildContentByType(
            context,
            availableHeight: availableHeight,
          ),
        );
      },
    );
  }

  int _calculateMaxLines(TextStyle style, double height) {
    final fontSize = style.fontSize ?? 13;
    final lineHeight = fontSize * (style.height ?? 1.0);
    if (lineHeight <= 0) return 1;
    final lines = (height / lineHeight).floor();
    return lines < 1 ? 1 : lines;
  }

  Widget _buildContentByType(BuildContext context,
      {required double availableHeight}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseStyle = isDark ? AppTypography.darkBody : AppTypography.lightBody;
    final textLines = _calculateMaxLines(baseStyle, availableHeight);
    final htmlLines = _calculateMaxLines(
      baseStyle.copyWith(height: 1.5),
      availableHeight,
    );
    switch (widget.model.ptype) {
      case ClipboardType.image:
        return _ImagePreview(model: widget.model);
      case ClipboardType.file:
        return FileContent(
          fileName: widget.model.pvalue,
          fileUri:
              widget.model.bytesToString(widget.model.bytes ?? Uint8List(0)),
        );
      case ClipboardType.html:
        return HtmlContent(
          htmlData:
              widget.model.bytesToString(widget.model.bytes ?? Uint8List(0)),
          maxLines: htmlLines,
        );
      case ClipboardType.unknown:
        return TextContent(
          text: 'Unknown',
          style: baseStyle,
          highlight: widget.highlight,
          maxLines: textLines,
        );
      default:
        return TextContent(
          text: widget.model.pvalue,
          style: baseStyle,
          highlight: widget.highlight,
          maxLines: textLines,
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
      onSuccess: _triggerPulse,
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final ClipboardItemModel model;

  const _ImagePreview({required this.model});

  @override
  Widget build(BuildContext context) {
    // 优先加载缩略图以节省内存，如果正在预览或已缓存完整字节则加载完整字节
    final imageData = model.thumbnail ?? model.bytes;

    if (imageData == null) {
      return Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).disabledColor,
        ),
      );
    }

    return Image.memory(
      imageData,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // 启用图片缓存优化
      cacheWidth: 400,
    );
  }
}
