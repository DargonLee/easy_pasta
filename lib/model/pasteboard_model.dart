import 'dart:typed_data';

/// 剪贴板数据模型
class NSPboardTypeModel {
  // 基础属性
  final int id;
  final String time;
  final String ptype;
  final String pvalue;
  final bool isFavorite;
  final Uint8List? tiffbytes;

  /// 创建剪贴板数据模型
  /// [id] - 数据ID，默认为 DateTime.now().millisecondsSinceEpoch
  /// [time] - 创建时间，默认为当前时间
  /// [ptype] - 数据类型
  /// [pvalue] - 数据内容
  /// [tiffbytes] - 图片数据，可选
  NSPboardTypeModel({
    int? id,
    String? time,
    required this.ptype,
    required this.pvalue,
    this.isFavorite = false,
    this.tiffbytes,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch,
        time = time ?? DateTime.now().toString();

  /// 从数据库映射创建模型
  factory NSPboardTypeModel.fromMapObject(Map<String, dynamic> map) {
    return NSPboardTypeModel(
      id: map['id'],
      time: map['time'],
      ptype: map['type'],
      pvalue: map['value'],
      isFavorite: map['isFavorite'] == 1,
      tiffbytes: map['tiffbytes'],
    );
  }

  /// 切换收藏状态
  NSPboardTypeModel toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  /// 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'type': ptype,
      'value': pvalue,
      'isFavorite': isFavorite ? 1 : 0,
      'tiffbytes': tiffbytes,
    };
  }

  /// 复制模型并更新部分属性
  NSPboardTypeModel copyWith({
    int? id,
    String? time,
    String? ptype,
    String? pvalue,
    bool? isFavorite,
    Uint8List? tiffbytes,
  }) {
    return NSPboardTypeModel(
      id: id ?? this.id,
      time: time ?? this.time,
      ptype: ptype ?? this.ptype,
      pvalue: pvalue ?? this.pvalue,
      isFavorite: isFavorite ?? this.isFavorite,
      tiffbytes: tiffbytes ?? this.tiffbytes,
    );
  }

  @override
  String toString() =>
      'NSPboardTypeModel(id: $id, time: $time, type: $ptype, value: $pvalue, isFavorite: $isFavorite)';
}
