import 'package:flutter/material.dart';

class HeaderContent extends StatelessWidget {
  final IconData typeIcon;
  final double iconSize;
  final double spacing;
  final Color? iconColor;
  final Color? backgroundColor;

  const HeaderContent({
    Key? key,
    required this.typeIcon,
    this.iconSize = 14,
    this.spacing = 6,
    this.iconColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        _buildTypeIcon(context),
      ],
    );
  }

  Widget _buildTypeIcon(BuildContext context) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;
    final bgColor = backgroundColor ?? color.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        typeIcon,
        size: iconSize,
        color: color,
      ),
    );
  }

  /// 获取类型图标的Widget
  Widget getTypeIconWidget(BuildContext context) {
    return _buildTypeIcon(context);
  }
}

/// 类型图标助手类
class TypeIconHelper {
  static final urlPattern = RegExp(
    r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
    caseSensitive: false,
  );

  static IconData getTypeIcon(String type, {String? pvalue}) {
    switch (type) {
      case 'text':
        if (urlPattern.hasMatch(pvalue ?? '')) {
          return Icons.link;
        }
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'file':
        final isDirectory = pvalue?.endsWith('/') ?? false;
        return isDirectory == true ? Icons.folder : Icons.insert_drive_file;
      case 'rtf':
        return Icons.article;
      case 'html':
        return Icons.code;
      default:
        return Icons.content_copy;
    }
  }
}
