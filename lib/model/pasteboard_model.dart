import 'dart:convert';
import 'dart:typed_data';
import 'package:easy_pasta/model/pasteboard_type.dart';
import 'package:intl/intl.dart';

class NSPboardTypeModel {
  int? id;
  late String time;
  late String ptype;
  late String pvalue;
  late String pjsonstr;
  Uint8List? tiffbytes;

  NSPboardTypeModel.fromItemArray(List<Map> itemArray) {
    DateTime now = DateTime.now();
    time = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);

    itemArray.first.forEach((key, value) {
      ptype = key;
      Uint8List uint8list = Uint8List.fromList(value);

      if (key == NSPboardType.tiffType.name) {
        pvalue = "";
        tiffbytes = uint8list;
      } else {
        pvalue = utf8.decode(uint8list);
      }
    });

    pjsonstr = ptype == NSPboardType.tiffType.name ? "" : _convertListToString(itemArray);
  }

  List<Map<String, Uint8List>> get itemArray => _convertJsonStringToList(pjsonstr);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'type': ptype,
      'value': pvalue,
      'jsonstr': pjsonstr,
      'tiffbytes': tiffbytes,
    };
  }

  NSPboardTypeModel.fromMapObject(Map<String, dynamic> map) {
    id = map['id'];
    ptype = map['type'];
    time = map['time'];
    pvalue = map['value'];
    pjsonstr = map['jsonstr'];
    tiffbytes = map['tiffbytes'];
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
    for (Map<String, dynamic> item  in itemArray) {
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
