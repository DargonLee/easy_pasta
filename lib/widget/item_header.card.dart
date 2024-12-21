import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:easy_pasta/widget/item_app_info_card.dart';

class HeaderContent extends StatelessWidget {
  final IconData typeIcon;
  final Uint8List? appIcon;
  final String appName;
  final double iconSize;
  final double spacing;
  final Color? iconColor;
  final Color? backgroundColor;

  const HeaderContent({
    Key? key,
    required this.typeIcon,
    this.appIcon,
    required this.appName,
    this.iconSize = 14,
    this.spacing = 6,
    this.iconColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppInfoContent(
          appIcon: appIcon,
          appName: appName,
          iconSize: iconSize,
        ),
        SizedBox(width: spacing),
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

  /// 获取应用信息的Widget
  Widget getAppInfoWidget() {
    return AppInfoContent(
      appIcon: appIcon,
      appName: appName,
      iconSize: iconSize,
    );
  }
}

/// 类型图标助手类
class TypeIconHelper {
  static IconData getTypeIcon(String type, {String? pvalue}) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'url':
        return Icons.link;
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
