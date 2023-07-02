import 'dart:convert';
import 'dart:typed_data';
import 'package:easy_pasta/model/pasteboard_type.dart';
import 'package:intl/intl.dart';

class NSPboardTypeModel {
  int? id;
  String time = "";
  String ptype = "";
  String pvalue = "";
  String pjsonstr = "";
  Uint8List? tiffbytes;

  String appid = "";
  String appname = "";
  Uint8List? appicon;

  NSPboardTypeModel.fromItemArray(List<Map> itemArray) {
    time = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

    for (var item in itemArray) {
      item.forEach((key, value) {
        if (ptype.isEmpty &&
            NSPboardType.values.any((element) => element.name == key)) {
          ptype = key;
          Uint8List uint8list = Uint8List.fromList(value);
          if (key == NSPboardType.tiffType.name) {
            pvalue = "";
            tiffbytes = uint8list;
          } else {
            pvalue = utf8.decode(uint8list);
          }
        }

        if (key == NSPboardTypeAppInfo.AppId) {
          appid = utf8.decode(Uint8List.fromList(value));
        } else if (key == NSPboardTypeAppInfo.AppName) {
          appname = utf8.decode(Uint8List.fromList(value));
        } else if (key == NSPboardTypeAppInfo.AppIcon) {
          appicon = Uint8List.fromList(value);
        }
      });
    }

    pjsonstr = ptype == NSPboardType.tiffType.name
        ? ""
        : _convertListToString(itemArray);
  }

  List<Map<String, Uint8List>> get itemArray =>
      _convertJsonStringToList(pjsonstr);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'type': ptype,
      'value': pvalue,
      'jsonstr': pjsonstr,
      'tiffbytes': tiffbytes,
      'appname': appname,
      'appid': appid,
      'appicon': appicon,
    };
  }

  NSPboardTypeModel.fromMapObject(Map<String, dynamic> map) {
    id = map['id'];
    ptype = map['type'];
    time = map['time'];
    pvalue = map['value'];
    pjsonstr = map['jsonstr'];
    tiffbytes = map['tiffbytes'];

    appname = map['appname'];
    appid = map['appid'];
    appicon = map['appicon'];
  }

  String _convertListToString(List<Map> itemArray) {
    List tmp = [];
    for (var item in itemArray) {
      item.forEach((key, value) {
        String dv = String.fromCharCodes(value);
        if (dv.isNotEmpty) {
          tmp.add({key: dv});
        }
      });
    }
    String result = json.encode(tmp);
    return result;
  }

  List<Map<String, Uint8List>> _convertJsonStringToList(String jsonStr) {
    List<Map<String, Uint8List>> tmp = [];
    List<Map<String, dynamic>> itemArray = List.from(json.decode(jsonStr));
    for (Map<String, dynamic> item in itemArray) {
      item.forEach((key, value) {
        Uint8List bytes = Uint8List.fromList(value.codeUnits);
        tmp.add({key: bytes});
      });
    }
    return tmp;
  }

  List<Map<String, Uint8List>> fromModeltoList() {
    if (ptype == NSPboardType.tiffType.name) {
      return [
        {ptype: tiffbytes ?? Uint8List(1)}
      ];
    }
    return _convertJsonStringToList(pjsonstr);
  }
}
