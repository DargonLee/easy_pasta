import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:flutter/foundation.dart';

/// 剪贴板数据模型
class ClipboardItemModel {
  // 基础属性
  final int id;
  final String time;
  final ClipboardType? ptype;
  final String pvalue;
  bool isFavorite;
  final Uint8List? imageBytes;

  /// 创建剪贴板数据模型
  /// [id] - 数据ID，默认为 DateTime.now().millisecondsSinceEpoch
  /// [time] - 创建时间，默认为当前时间
  /// [ptype] - 数据类型
  /// [pvalue] - 数据内容
  /// [imageBytes] - 图片数据，可选
  ClipboardItemModel({
    int? id,
    String? time,
    required ClipboardType? ptype,
    required this.pvalue,
    this.isFavorite = false,
    this.imageBytes,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch,
        time = time ?? DateTime.now().toString(),
        ptype = ptype ?? ClipboardType.unknown;

  /// 从数据库映射创建模型
  factory ClipboardItemModel.fromMapObject(Map<String, dynamic> map) {
    return ClipboardItemModel(
      id: map['id'],
      time: map['time'],
      ptype: ClipboardType.fromString(map['type']),
      pvalue: map['value'],
      isFavorite: map['isFavorite'] == 1,
      imageBytes: map['image'],
    );
  }

  /// 切换收藏状态
  ClipboardItemModel toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  /// 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'type': ptype.toString(),
      'value': pvalue,
      'isFavorite': isFavorite ? 1 : 0,
      'image': imageBytes,
    };
  }

  /// 复制模型并更新部分属性
  ClipboardItemModel copyWith({
    int? id,
    String? time,
    ClipboardType? ptype,
    String? pvalue,
    bool? isFavorite,
    Uint8List? imageBytes,
  }) {
    return ClipboardItemModel(
      id: id ?? this.id,
      time: time ?? this.time,
      ptype: ptype ?? this.ptype,
      pvalue: pvalue ?? this.pvalue,
      isFavorite: isFavorite ?? this.isFavorite,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ClipboardItemModel) return false;

    switch (ptype) {
      case ClipboardType.text:
        return pvalue == other.pvalue && ptype == other.ptype;
      case ClipboardType.html:
        return pvalue == other.pvalue && ptype == other.ptype;
      case ClipboardType.file:
        return pvalue == other.pvalue && ptype == other.ptype;
      case ClipboardType.image:
        if (imageBytes == null || other.imageBytes == null) return false;
        if (imageBytes!.length != other.imageBytes!.length) return false;
        // 对于图片数据，可以只比较长度和采样点
        return _compareImageData(imageBytes!, other.imageBytes!);
      default:
        return false;
    }
  }

  bool _compareImageData(List<int> data1, List<int> data2) {
    // 为了提高性能，可以只比较关键采样点
    const sampleSize = 100; // 采样点数量
    if (data1.length < sampleSize || data2.length < sampleSize) {
      return listEquals(data1, data2);
    }

    final step = data1.length ~/ sampleSize;
    for (var i = 0; i < sampleSize; i++) {
      if (data1[i * step] != data2[i * step]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, time, ptype, pvalue, isFavorite);

  @override
  String toString() =>
      'ClipboardItemModel(id: $id, time: $time, type: $ptype, value: $pvalue, isFavorite: $isFavorite)';
}
