import 'package:flutter/services.dart';
import 'model/pasteboard_model.dart';

class ChannelManager {
  factory ChannelManager() => _instance;
  ChannelManager._internal();
  static final ChannelManager _instance = ChannelManager._internal();

  late final ValueChanged eventValueChangedCallback;

  static const EVENT_CHANNEL_NAME = 'com.easy.pasteboard.event';
  static const METHOD_CHANNEL_NAME = 'com.easy.pasteboard.method';

  final EventChannel _eventChannel = const EventChannel(EVENT_CHANNEL_NAME);
  final MethodChannel _methodChannel = const MethodChannel(METHOD_CHANNEL_NAME);

  void initChannel() {
    _eventChannel.receiveBroadcastStream().listen((event) {
      final List<Map> pItem = List.from(event);
      final NSPboardTypeModel model = NSPboardTypeModel.fromItemArray(pItem);
      print('received event ${model.rawValue}');
      eventValueChangedCallback(model.rawValue);
    }, onError: (dynamic error) {
      print('received error: ${error.message}');
    }, cancelOnError: true);
  }

  dynamic setPasteboardItem(List<Map>? elements) async {
    try {
      List<int> strList1 = 'hello1'.codeUnits;
      Uint8List bytes1 = Uint8List.fromList(strList1);
      List<int> strList2 = 'hello2'.codeUnits;
      Uint8List bytes2 = Uint8List.fromList(strList2);
      List list = [
        {"1": bytes1},
        {"1": bytes2},
      ];
      final result =
          await _methodChannel.invokeMethod('setPasteboardItem', list);
      print('receive swift data ${result}');
      return result;
    } on PlatformException catch (e) {
      print('call setPasteboardItem error : ${e.message}');
    }
  }
}
