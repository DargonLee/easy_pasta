import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_pasta/model/clipboard_type.dart';

/// 剪贴板数据模型
class ClipboardItemModel {
  // 基础属性
  final String id;
  final String time;
  final ClipboardType? ptype;
  final String pvalue;
  bool isFavorite;
  final Uint8List? bytes;
  final String? sourceAppId;

  /// 创建剪贴板数据模型
  ClipboardItemModel({
    String? id,
    String? time,
    required this.ptype,
    required this.pvalue,
    this.isFavorite = false,
    this.bytes,
    this.sourceAppId,
  })  : id = id ?? const Uuid().v4(),
        time = time ?? DateTime.now().toString();

  /// 从数据库映射创建模型
  factory ClipboardItemModel.fromMapObject(Map<String, dynamic> map) {
    return ClipboardItemModel(
      id: map['id'],
      time: map['time'],
      ptype: ClipboardType.fromString(map['type']),
      pvalue: map['value'],
      isFavorite: map['isFavorite'] == 1,
      bytes: map['bytes'],
      sourceAppId: map['sourceAppId'],
    );
  }

  /// 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'type': ptype.toString(),
      'value': pvalue,
      'isFavorite': isFavorite ? 1 : 0,
      'bytes': bytes,
      'sourceAppId': sourceAppId,
    };
  }

  /// 获取HTML数据
  String? get htmlData =>
      ptype == ClipboardType.html ? bytesToString(bytes ?? Uint8List(0)) : null;

  /// 获取图片数据
  Uint8List? get imageBytes => ptype == ClipboardType.image ? bytes : null;

  /// 获取文件路径
  String? get filePath =>
      ptype == ClipboardType.file ? bytesToString(bytes ?? Uint8List(0)) : null;

  /// 将字符串转换为Uint8List
  static Uint8List stringToBytes(String str) {
    return Uint8List.fromList(utf8.encode(str));
  }

  /// 将Uint8List转换为字符串
  String bytesToString(Uint8List bytes) {
    return utf8.decode(bytes);
  }

  /// 复制模型并更新部分属性
  ClipboardItemModel copyWith({
    String? id,
    String? time,
    ClipboardType? ptype,
    String? pvalue,
    bool? isFavorite,
    Uint8List? bytes,
    String? sourceAppId,
  }) {
    return ClipboardItemModel(
      id: id ?? this.id,
      time: time ?? this.time,
      ptype: ptype ?? this.ptype,
      pvalue: pvalue ?? this.pvalue,
      isFavorite: isFavorite ?? this.isFavorite,
      bytes: bytes ?? this.bytes,
      sourceAppId: sourceAppId ?? this.sourceAppId,
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
      'ClipboardItemModel(id: $id, time: $time, type: $ptype, value: $pvalue, isFavorite: $isFavorite, sourceAppId: $sourceAppId)';
}
