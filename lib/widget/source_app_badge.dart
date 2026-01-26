import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_pasta/core/app_source_service.dart';
import 'package:easy_pasta/model/design_tokens.dart';

class SourceAppBadge extends StatefulWidget {
  final String bundleId;
  final double size;

  const SourceAppBadge({
    super.key,
    required this.bundleId,
    this.size = 18,
  });

  @override
  State<SourceAppBadge> createState() => _SourceAppBadgeState();
}

class _SourceAppBadgeState extends State<SourceAppBadge> {
  late Future<Uint8List?> _iconFuture;

  @override
  void initState() {
    super.initState();
    _iconFuture = AppSourceService().getAppIcon(widget.bundleId);
  }

  @override
  void didUpdateWidget(covariant SourceAppBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bundleId != widget.bundleId) {
      _iconFuture = AppSourceService().getAppIcon(widget.bundleId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? AppColors.darkFrostedSurface : AppColors.lightFrostedSurface;
    final border =
        isDark ? AppColors.darkFrostedBorder : AppColors.lightFrostedBorder;
    final fallbackColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final containerSize = widget.size + 8;

    return FutureBuilder<Uint8List?>(
      future: _iconFuture,
      builder: (context, snapshot) {
        final iconBytes = snapshot.data;
        return Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(containerSize / 2),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.all(2),
          child: iconBytes == null
              ? Icon(
                  Icons.apps,
                  size: widget.size - 2,
                  color: fallbackColor,
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(widget.size / 2),
                  child: Image.memory(
                    iconBytes,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                  ),
                ),
        );
      },
    );
  }
}
