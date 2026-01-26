import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/content_classification.dart';
import 'package:flutter/material.dart';

/// 类型图标助手类
/// 根据剪贴板内容类型返回对应的图标
class TypeIconHelper {
  /* [Optimized] RegExp removed for performance
  static final _urlPattern = RegExp(
    r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    caseSensitive: false,
  );
  */

  static IconData getTypeIcon(ClipboardType type,
      {String? pvalue, ClipboardItemModel? model}) {
    if (pvalue == null) {
      return Icons.content_copy;
    }

    switch (type) {
      case ClipboardType.text:
        // 优先使用预计算的分类结果
        if (model?.classification?.kind == ContentKind.url) {
          return Icons.link;
        }
        if (model?.classification?.kind == ContentKind.json) {
          return Icons.data_object;
        }
        // 降级策略: 仅对短文本进行快速前缀检查，绝对不跑正则
        if (pvalue.length < 500 &&
            (pvalue.startsWith('http://') || pvalue.startsWith('https://'))) {
          return Icons.link;
        }
        return Icons.text_fields;
      case ClipboardType.image:
        return Icons.image;
      case ClipboardType.file:
        return pvalue.endsWith('/') ? Icons.folder : Icons.insert_drive_file;
      case ClipboardType.html:
        if (model?.classification?.kind == ContentKind.url) {
          return Icons.link;
        }
        return Icons.code;
      default:
        return Icons.content_copy;
    }
  }
}
