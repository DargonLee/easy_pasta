import 'package:flutter/material.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
class TimestampContent extends StatelessWidget {
  final NSPboardTypeModel model;
  final Function(NSPboardTypeModel) onCopy;

  const TimestampContent({
    Key? key,
    required this.model,
    required this.onCopy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[500],
          fontSize: 10,
        );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatTimestamp(DateTime.parse(model.time)),
            style: defaultStyle,
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            onPressed: () => onCopy(model),
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

  /// 获取详细时间
  String getDetailedTime(DateTime timestamp) {
    return '${timestamp.year}年${timestamp.month}月${timestamp.day}日 '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// 判断是否是今天
  bool isToday(DateTime timestamp) {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }
}