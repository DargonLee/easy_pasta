import 'dart:typed_data';
import 'package:flutter/material.dart';

class AppInfoContent extends StatelessWidget {
  final Uint8List? appIcon;
  final String appName;
  final double iconSize;
  final double fontSize;
  final double maxWidth;
  final Color? textColor;
  final TextStyle? textStyle;

  const AppInfoContent({
    super.key,
    this.appIcon,
    required this.appName,
    this.iconSize = 14,
    this.fontSize = 11,
    this.maxWidth = 150,
    this.textColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (appIcon != null) ...[
          _buildAppIcon(),
          const SizedBox(width: 4),
        ],
        _buildAppName(context),
      ],
    );
  }

  Widget _buildAppIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.memory(
        appIcon!,
        width: iconSize,
        height: iconSize,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.apps,
            size: iconSize,
            color: Colors.grey[400],
          );
        },
      ),
    );
  }

  Widget _buildAppName(BuildContext context) {
    // 获取默认样式
    final defaultStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor ?? Colors.grey[600],
          fontSize: fontSize,
        );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Tooltip(
        message: appName,
        child: Text(
          appName,
          style: textStyle ?? defaultStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    );
  }

  /// 获取应用图标的Widget
  Widget? get appIconWidget {
    if (appIcon == null) return null;
    return _buildAppIcon();
  }

  /// 检查应用名称是否需要截断
  bool get isNameTruncated {
    final textPainter = TextPainter(
      text: TextSpan(text: appName),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
  }
}
