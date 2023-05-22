import 'dart:convert';
import 'dart:typed_data';

/*
* ▿ 4 elements
  ▿ 0 : 1 element
    ▿ 0 : 2 elements
      - key : "public.rtf"
      - value : <FlutterStandardTypedData: 0x600002234400>
  ▿ 1 : 1 element
    ▿ 0 : 2 elements
      - key : "public.utf16-external-plain-text"
      - value : <FlutterStandardTypedData: 0x600002270920>
  ▿ 2 : 1 element
    ▿ 0 : 2 elements
      - key : "public.utf8-plain-text"
      - value : <FlutterStandardTypedData: 0x6000022e4640>
  ▿ 3 : 1 element
    ▿ 0 : 2 elements
      - key : "dyn.ah62d4rv4gu8zg55zsmv0nvperf4g86varvw0c3dmr3xwa75krf4gn65uqfv0nkduqf31k3pcr7u1e3basv61a3k"
      - value : <FlutterStandardTypedData: 0x6000022706e0>
* */
class NSPboardTypeModel {
  int? id;
  late String rawType;
  late String rawValue;
  late String rawJsonStr;

  NSPboardTypeModel.fromItemArray(List<Map> itemArray) {
    itemArray.first.forEach((key, value) {
      rawType = key;
      Uint8List uint8list = Uint8List.fromList(value);
      rawValue = utf8.decode(uint8list);
    });
    rawJsonStr = _convertListToString(itemArray);

    print('-----fromItemArray------');
    print(rawType);
    print(rawValue);
    print(rawJsonStr);
  }

  List<Map<String, Uint8List>> get itesArray => _convertJsonStringToList(rawJsonStr);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rawType': rawType,
      'rawValue': rawValue,
      'rawJsonStr': rawJsonStr,
    };
  }

  NSPboardTypeModel.fromMapObject(Map<String, dynamic> map) {
    id = map['id'];
    rawType = map['rawType'];
    rawValue = map['rawValue'];
    rawJsonStr = map['rawJsonStr'];
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
    List<Map<String, String>> itemArray = json.decode(jsonStr);
    for (var item in itemArray) {
      item.forEach((key, value) {
        Uint8List bytes = Uint8List.fromList(value.codeUnits);
        tmp.add({key, bytes} as Map<String, Uint8List>);
      });
    }
    return tmp;
  }
}
