/// 内容类型枚举
enum ContentFormat {
  plainText, // 纯文本
  text, // 富文本
  image, // 图片
  html // HTML
}

/// 剪贴板内容模型
class ClipboardItem {
  /// 唯一标识
  final String id;

  /// 内容
  final String content;

  /// 创建时间
  final DateTime createdAt;

  /// 是否收藏
  bool isFavorite;

  /// 内容格式
  final ContentFormat format;

  ClipboardItem({
    required this.id,
    required this.content,
    required this.createdAt,
    this.isFavorite = false,
    required this.format,
  });

  /// 获取创建时间距今多久
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 从Map创建实例
  factory ClipboardItem.fromMap(Map<String, dynamic> map) {
    return ClipboardItem(
      id: map['id'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      isFavorite: map['isFavorite'] ?? false,
      format: ContentFormat.values.byName(map['format']),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'format': format.name,
    };
  }
}
