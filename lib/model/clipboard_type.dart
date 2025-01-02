/// 剪贴板内容类型
enum ClipboardType {
  text('text'), // 文本
  image('image'), // 图片
  file('file'), // 文件
  url('url'), // 链接
  html('html'), // HTML
  rtf('rtf'), // RTF
  unknown('unknown'); // 未知类型

  final String value;
  const ClipboardType(this.value);

  /// 从字符串转换为枚举
  static ClipboardType fromString(String? value) {
    return ClipboardType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ClipboardType.unknown,
    );
  }

  @override
  String toString() => value;
}