import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';

class NSPboardTypeModel {
  // 基础属性
  int? id;
  final String time;
  final String ptype;
  final String pvalue;
  final Uint8List? tiffbytes;

  

  // 应用信息
  final String appid;
  final String appname;
  final Uint8List? appicon;

  NSPboardTypeModel({
    this.id,
    required this.time,
    required this.ptype,
    required this.pvalue,
    this.tiffbytes,
    required this.appid,
    required this.appname,
    this.appicon,
  });

  // 从剪贴板数据创建模型
  factory NSPboardTypeModel.fromItemArray(List<Map> itemArray) {
    String ptype = '';
    String pvalue = '';
    Uint8List? tiffbytes;
    String appid = '';
    String appname = '';
    Uint8List? appicon;

    for (var item in itemArray) {
      if (item.containsKey('type')) {
        ptype = item['type'];
        if (item.containsKey('content')) {
          pvalue = item['content'];
        }
        continue;
      }
      if (item.containsKey('appId')) {
        Uint8List bytes = item['appId'];
        appid = utf8.decode(bytes.toList());
        continue;
      }
      if (item.containsKey('appName')) {
        Uint8List bytes = item['appName'];
        appname = utf8.decode(bytes.toList());
        continue;
      }
      if (item.containsKey('appIcon')) {
        Uint8List bytes = item['appIcon'];
        appicon = Uint8List.fromList(bytes.toList());
        continue;
      }
    }

    return NSPboardTypeModel(
      time: DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
      ptype: ptype,
      pvalue: pvalue,
      tiffbytes: tiffbytes,
      appid: appid,
      appname: appname,
      appicon: appicon,
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
      appname: map['appname'],
      appid: map['appid'],
      appicon: map['appicon'],
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
      'appname': appname,
      'appid': appid,
      'appicon': appicon,
    };
  }
}
