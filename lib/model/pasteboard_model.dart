import 'dart:typed_data';
import 'package:intl/intl.dart';

class NSPboardTypeModel {
  // 基础属性
  int? id;
  final String time;
  final String ptype;
  final String pvalue;
  final Uint8List? tiffbytes;

  NSPboardTypeModel({
    this.id,
    required this.time,
    required this.ptype,
    required this.pvalue,
    this.tiffbytes,
  });

  // 从剪贴板数据创建模型
  factory NSPboardTypeModel.fromItemArray(List<Map> itemArray) {
    String ptype = '';
    String pvalue = '';
    Uint8List? tiffbytes;

    for (var item in itemArray) {
      if (item.containsKey('type')) {
        ptype = item['type'];
        if (item.containsKey('content')) {
          pvalue = item['content'];
        }
        continue;
      }
    }

    return NSPboardTypeModel(
      time: DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
      ptype: ptype,
      pvalue: pvalue,
      tiffbytes: tiffbytes,
    );
  }

  // 从数据库映射创建模型
  factory NSPboardTypeModel.fromMapObject(Map<String, dynamic> map) {
    return NSPboardTypeModel(
      id: map['id'],
      time: map['time'],
      ptype: map['type'],
      pvalue: map['value'],
      tiffbytes: map['tiffbytes'],
    );
  }

  // 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'type': ptype,
      'value': pvalue,
      'tiffbytes': tiffbytes,
    };
  }
}
