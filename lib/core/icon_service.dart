import 'package:flutter/material.dart';
import 'package:easy_pasta/model/clipboard_type.dart';

/// 类型图标助手类
/// 根据剪贴板内容类型返回对应的图标
class TypeIconHelper {
  static final _urlPattern = RegExp(
    r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    caseSensitive: false,
  );

  static IconData getTypeIcon(ClipboardType type, {String? pvalue}) {
    if (pvalue == null) {
      return Icons.content_copy;
    }

    switch (type) {
      case ClipboardType.text:
        return _urlPattern.hasMatch(pvalue) ? Icons.link : Icons.text_fields;
      case ClipboardType.image:
        return Icons.image;
      case ClipboardType.file:
        return pvalue.endsWith('/') ? Icons.folder : Icons.insert_drive_file;
      case ClipboardType.html:
        return Icons.code;
      default:
        return Icons.content_copy;
    }
  }
}
