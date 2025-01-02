import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/core/icon_service.dart';
import 'package:easy_pasta/model/clipboard_type.dart';

class FooterContent extends StatelessWidget {
  final ClipboardItemModel model;
  final Function(ClipboardItemModel) onCopy;
  final Function(ClipboardItemModel) onFavorite;
  final Function(ClipboardItemModel) onDelete;

  const FooterContent({
    Key? key,
    required this.model,
    required this.onCopy,
    required this.onFavorite,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[500],
          fontSize: 10,
        );

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            TypeIconHelper.getTypeIcon(model.ptype ?? ClipboardType.unknown,
                pvalue: model.pvalue),
            size: 15,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTimestamp(DateTime.parse(model.time)),
            style: defaultStyle,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            onPressed: () => onCopy(model),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 12,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              model.isFavorite ? Icons.star : Icons.star_border,
              size: 15,
            ),
            onPressed: () => onFavorite(model),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 12,
            color: model.isFavorite ? Colors.amber : Colors.grey[500],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 15),
            onPressed: () => onDelete(model),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 12,
            color: Colors.grey[500],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else {
      return '${timestamp.month}月${timestamp.day}日';
    }
  }

  String getDetailedTime(DateTime timestamp) {
    return '${timestamp.year}年${timestamp.month}月${timestamp.day}日 '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  bool isToday(DateTime timestamp) {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }
}
