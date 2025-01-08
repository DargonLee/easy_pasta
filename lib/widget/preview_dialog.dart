import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/clipboard_type.dart';

class PreviewDialog extends StatelessWidget {
  final ClipboardItemModel model;

  const PreviewDialog({
    super.key,
    required this.model,
  });

  static Future<void> show(BuildContext context, ClipboardItemModel model) {
    return showDialog(
      context: context,
      builder: (context) => PreviewDialog(model: model),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: model.ptype == ClipboardType.image ? 800 : 600,
          maxHeight: model.ptype == ClipboardType.image ? 600 : 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, isDark),
            _buildContentArea(context),
          ],
        ),
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '预览',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContentArea(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildContent(context),
        ),
      ),
    );
  }

  /// 构建内容根据剪贴板类型动态渲染
  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    switch (model.ptype) {
      case ClipboardType.image:
        return Center(
          child: Image.memory(
            model.imageBytes!,
            fit: BoxFit.contain,
          ),
        );
      case ClipboardType.html:
      case ClipboardType.text:
      case ClipboardType.file:
      default:
        return SelectableText(
          model.pvalue,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            letterSpacing: 0.3,
          ),
        );
    }
  }
}
