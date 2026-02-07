import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_pasta/db/database_helper.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/model/content_classification.dart';

/// 剪贴板数据模型
class ClipboardItemModel {
  // 基础属性
  final String id;
  final String time;
  final DateTime parsedTime;
  final ClipboardType? ptype;
  final String pvalue;
  final bool isFavorite;
  final Uint8List? bytes;
  final Uint8List? thumbnail; // 新增缩略图
  final String? sourceAppId;
  final ContentClassification? classification;
  late final String decodedBytes = _decodeBytes();

  /// 创建剪贴板数据模型
  ClipboardItemModel({
    String? id,
    String? time,
    required this.ptype,
    required this.pvalue,
    this.isFavorite = false,
    this.bytes,
    this.thumbnail,
    this.sourceAppId,
    this.classification,
  })  : id = id ?? const Uuid().v4(),
        time = time ?? DateTime.now().toString(),
        parsedTime = DateTime.parse(time ?? DateTime.now().toString());

  /// 从数据库映射创建模型
  factory ClipboardItemModel.fromMapObject(Map<String, dynamic> map) {
    ContentClassification? classification;
    final classificationStr = map['classification'] as String?;
    if (classificationStr != null && classificationStr.isNotEmpty) {
      try {
        classification =
            ContentClassification.fromMap(jsonDecode(classificationStr));
      } catch (_) {
        // Silently ignore malformed classification
      }
    }

    return ClipboardItemModel(
      id: map['id'],
      time: map['time'],
      ptype: ClipboardType.fromString(map['type']),
      pvalue: map['value'],
      isFavorite: map[DatabaseConfig.columnIsFavorite] == 1,
      bytes: map[DatabaseConfig.columnBytes],
      thumbnail: map[DatabaseConfig.columnThumbnail],
      sourceAppId: map[DatabaseConfig.columnSourceAppId],
      classification: classification,
    );
  }

  /// 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'type': ptype.toString(),
      'value': pvalue,
      DatabaseConfig.columnIsFavorite: isFavorite ? 1 : 0,
      DatabaseConfig.columnBytes: bytes,
      DatabaseConfig.columnThumbnail: thumbnail,
      DatabaseConfig.columnSourceAppId: sourceAppId,
      'classification':
          classification != null ? jsonEncode(classification!.toMap()) : null,
    };
  }

  /// 获取HTML数据
  String? get htmlData =>
      ptype == ClipboardType.html ? decodedBytes : null;

  /// 获取图片数据
  Uint8List? get imageBytes => ptype == ClipboardType.image ? bytes : null;

  /// 获取文件路径
  String? get filePath =>
      ptype == ClipboardType.file ? decodedBytes : null;

  /// 将字符串转换为Uint8List
  static Uint8List stringToBytes(String str) {
    return Uint8List.fromList(utf8.encode(str));
  }

  /// 将Uint8List转换为字符串
  String bytesToString(Uint8List bytes) {
    return utf8.decode(bytes);
  }

  String _decodeBytes() {
    final data = bytes;
    if (data == null || data.isEmpty) return '';
    return utf8.decode(data);
  }

  /// 复制模型并更新部分属性
  ClipboardItemModel copyWith({
    String? id,
    String? time,
    ClipboardType? ptype,
    String? pvalue,
    bool? isFavorite,
    Uint8List? bytes,
    Uint8List? thumbnail,
    String? sourceAppId,
    ContentClassification? classification,
  }) {
    return ClipboardItemModel(
      id: id ?? this.id,
      time: time ?? this.time,
      ptype: ptype ?? this.ptype,
      pvalue: pvalue ?? this.pvalue,
      isFavorite: isFavorite ?? this.isFavorite,
      bytes: bytes ?? this.bytes,
      thumbnail: thumbnail ?? this.thumbnail,
      sourceAppId: sourceAppId ?? this.sourceAppId,
      classification: classification ?? this.classification,
    );
  }

  /// 切换收藏状态
  ClipboardItemModel toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ClipboardItemModel) return false;

    switch (ptype) {
      case ClipboardType.text:
        return pvalue == other.pvalue && ptype == other.ptype;
      case ClipboardType.html:
        return pvalue == other.pvalue &&
            ptype == other.ptype &&
            listEquals(bytes, other.bytes);
      case ClipboardType.file:
        return pvalue == other.pvalue && ptype == other.ptype;
      case ClipboardType.image:
        return ptype == other.ptype && listEquals(bytes, other.bytes);
      default:
        return false;
    }
  }

  @override
  int get hashCode => Object.hash(id, time, ptype, pvalue, bytes, isFavorite);

  @override
  String toString() =>
      'ClipboardItemModel(id: $id, time: $time, type: $ptype, value: $pvalue, isFavorite: $isFavorite, sourceAppId: $sourceAppId, classification: $classification)';
}
