import 'package:flutter/services.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

class ChannelManager {
  factory ChannelManager() => _instance;
  ChannelManager._internal();
  static final ChannelManager _instance = ChannelManager._internal();

  late final ValueChanged<NSPboardTypeModel> eventValueChangedCallback;

  static const EVENT_CHANNEL_NAME = 'com.easy.pasteboard.event';
  static const METHOD_CHANNEL_NAME = 'com.easy.pasteboard.method';

  final EventChannel _eventChannel = const EventChannel(EVENT_CHANNEL_NAME);
  final MethodChannel _methodChannel = const MethodChannel(METHOD_CHANNEL_NAME);

  void initChannel() {
    _eventChannel.receiveBroadcastStream().listen((event) {
      print('received event from macos pasteboard');
      final List<Map> pItem = List.from(event);
      final NSPboardTypeModel model = NSPboardTypeModel.fromItemArray(pItem);
      eventValueChangedCallback(model);
    }, onError: (dynamic error) {
      print('received error: ${error.message}');
    }, cancelOnError: true);
  }

  void setPasteboardItem(NSPboardTypeModel model) async {
    try {
      List list = model.fromModeltoList();
      final result =
          await _methodChannel.invokeMethod('setPasteboardItem', list);
      print('receive swift data ${result}');
    } on PlatformException catch (e) {
      print('call setPasteboardItem error : ${e.message}');
    }
  }

  void showMainPasteboardWindow() async{
    try {
      final result =
      await _methodChannel.invokeMethod('showMainPasteboardWindow');
    } on PlatformException catch (e) {
      print('call showMainPasteboardWindow error : ${e.message}');
    }
  }

  void setLaunchCtl(bool status) async{
    try {
      final result =
      await _methodChannel.invokeMethod('setLaunchCtl', status);
    } on PlatformException catch (e) {
      print('call setLaunchCtl error : ${e.message}');
    }
  }


}
