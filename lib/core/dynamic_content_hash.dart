import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class DynamicContentHash {
  // 方法1: 使用内容特征生成hash
  static String generateContentHash(dynamic content) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final contentString = content.toString();
    final input = utf8.encode('$timestamp-$contentString');

    return sha256.convert(input).toString();
  }

  // 方法2: 时间戳+随机数
  static String generateTimestampHash() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (100000 + Random().nextInt(900000)).toString();

    return '$timestamp-$random';
  }

  // 方法3: 针对特定内容结构
  static String generateStructuredHash(Map<String, dynamic> content) {
    // 提取关键字段
    final id = content['id'] ?? '';
    final title = content['title'] ?? '';
    final updateTime = content['updateTime'] ?? '';

    final input = utf8.encode('$id-$title-$updateTime');
    return md5.convert(input).toString();
  }

  // 方法4: 版本化的hash
  static String generateVersionHash(dynamic content, String version) {
    final input = utf8.encode('$content-v$version');
    return sha1.convert(input).toString();
  }
}
