import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppSourceService {
  static final AppSourceService _instance = AppSourceService._internal();
  factory AppSourceService() => _instance;
  AppSourceService._internal();

  static const MethodChannel _channel = MethodChannel('app_source');

  final Map<String, Uint8List> _iconCache = {};
  final Map<String, Future<Uint8List?>> _iconInFlight = {};

  Future<String?> getFrontmostAppBundleId() async {
    if (!Platform.isMacOS) return null;
    try {
      return await _channel.invokeMethod<String>('getFrontmostApp');
    } catch (e) {
      debugPrint('Failed to fetch frontmost app: $e');
      return null;
    }
  }

  Future<Uint8List?> getAppIcon(String bundleId) {
    if (!Platform.isMacOS) return Future.value(null);
    final cached = _iconCache[bundleId];
    if (cached != null) return Future.value(cached);
    final inflight = _iconInFlight[bundleId];
    if (inflight != null) return inflight;

    final future = _channel
        .invokeMethod<Uint8List>('getAppIcon', bundleId)
        .then((data) {
      if (data != null) {
        _iconCache[bundleId] = data;
      }
      _iconInFlight.remove(bundleId);
      return data;
    }).catchError((e) {
      _iconInFlight.remove(bundleId);
      debugPrint('Failed to fetch app icon: $e');
      return null;
    });

    _iconInFlight[bundleId] = future;
    return future;
  }
}
