import 'package:flutter/material.dart';
import 'package:easy_pasta/model/clipboard_type.dart';

/// 类型图标助手类
class TypeIconHelper {
  static final urlPattern = RegExp(
    r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
    caseSensitive: false,
  );

  static IconData getTypeIcon(ClipboardType type, {String? pvalue}) {
    switch (type) {
      case ClipboardType.text:
        if (urlPattern.hasMatch(pvalue ?? '')) {
          return Icons.link;
        }
        return Icons.text_fields;
      case ClipboardType.image:
        return Icons.image;
      case ClipboardType.file:
        final isDirectory = pvalue?.endsWith('/') ?? false;
        return isDirectory == true ? Icons.folder : Icons.insert_drive_file;
      case ClipboardType.html:
        return Icons.code;
      default:
        return Icons.content_copy;
    }
  }
}
