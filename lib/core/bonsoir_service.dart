import 'dart:async';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

/// Bonjour/mDNS 服务管理单例
/// 用于 EasyPasta 跨设备剪贴板同步功能
class BonjourManager {
  static BonjourManager? _instance;
  static final _lock = Object();

  // 服务配置
  static const String _serviceType = '_easypasta._tcp';
  static const String _serviceName = 'EasyPasta-Clipboard';
  static const int _defaultPort = 8888;

  BonsoirService? _service;
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription? _discoverySubscription;

  // 发现的设备列表 - 使用 service name 作为 key
  final Map<String, BonsoirService> _discoveredServices = {};
  final Map<String, BonsoirService> _resolvedServices = {};

  // 状态回调
  Function(List<BonsoirService>)? onServicesFound;
  Function(List<BonsoirService>)? onServicesResolved;
  Function(BonsoirService)? onServiceLost;
  Function(String message)? onError;
  Function(bool isRunning)? onServiceStateChanged;
  Function(bool isDiscovering)? onDiscoveryStateChanged;

  // 私有构造函数
  BonjourManager._internal();

  /// 获取单例实例
  static BonjourManager get instance {
    if (_instance == null) {
      synchronized(_lock, () {
        _instance ??= BonjourManager._internal();
      });
    }
    return _instance!;
  }

  /// 启动 Bonjour 服务（广播本设备）
  Future<bool> startService({
    String? deviceName,
    int port = _defaultPort,
    Map<String, String>? attributes,
  }) async {
    try {
      await stopService(); // 先停止现有服务

      final Map<String, String> serviceAttributes = {
        'device_name': deviceName ?? 'EasyPasta Device',
        'version': '1.0.0',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'portal_url': attributes?['portal_url'] ?? '',
        ...?attributes,
      };

      _service = BonsoirService(
        name: deviceName ?? _serviceName,
        type: _serviceType,
        port: port,
        attributes: serviceAttributes,
      );

      _broadcast = BonsoirBroadcast(service: _service!);

      await _broadcast!.initialize();
      await _broadcast!.start();

      if (kDebugMode) {
        print('EasyPasta Bonjour 服务已启动: ${_service!.name}');
      }

      onServiceStateChanged?.call(true);
      return true;
    } catch (e) {
      final error = 'Bonjour 服务启动失败: $e';
      if (kDebugMode) print(error);
      onError?.call(error);
      return false;
    }
  }

  /// 停止 Bonjour 服务
  Future<void> stopService() async {
    try {
      if (_broadcast != null) {
        await _broadcast!.stop();
        _broadcast = null;
      }
      _service = null;

      onServiceStateChanged?.call(false);

      if (kDebugMode) {
        print('EasyPasta Bonjour 服务已停止');
      }
    } catch (e) {
      if (kDebugMode) print('停止 Bonjour 服务时出错: $e');
    }
  }

  /// 开始发现其他设备
  Future<bool> startDiscovery() async {
    try {
      await stopDiscovery(); // 先停止现有发现

      _discovery = BonsoirDiscovery(type: _serviceType);

      await _discovery!.initialize();

      // 监听发现的服务 - 必须在 start() 之前设置监听
      _discoverySubscription = _discovery!.eventStream!.listen((event) {
        if (event is BonsoirDiscoveryServiceFoundEvent) {
          _handleServiceFound(event.service!);
        } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
          _handleServiceResolved(event.service!);
        } else if (event is BonsoirDiscoveryServiceLostEvent) {
          _handleServiceLost(event.service!);
        }
      });

      await _discovery!.start();

      onDiscoveryStateChanged?.call(true);

      if (kDebugMode) {
        print('开始发现 EasyPasta 设备...');
      }

      return true;
    } catch (e) {
      final error = '设备发现启动失败: $e';
      if (kDebugMode) print(error);
      onError?.call(error);
      return false;
    }
  }

  /// 停止设备发现
  Future<void> stopDiscovery() async {
    try {
      if (_discovery != null) {
        await _discovery!.stop();
        _discovery = null;
      }

      await _discoverySubscription?.cancel();
      _discoverySubscription = null;

      _discoveredServices.clear();
      _resolvedServices.clear();

      onDiscoveryStateChanged?.call(false);

      if (kDebugMode) {
        print('设备发现已停止');
      }
    } catch (e) {
      if (kDebugMode) print('停止设备发现时出错: $e');
    }
  }

  /// 处理发现的服务
  void _handleServiceFound(BonsoirService service) {
    _discoveredServices[service.name] = service;

    if (kDebugMode) {
      print('发现 EasyPasta 设备: ${service.name}');
      print('服务信息: ${service.toJson()}');
    }

    onServicesFound?.call(_discoveredServices.values.toList());
  }

  /// 处理已解析的服务
  void _handleServiceResolved(BonsoirService service) {
    _resolvedServices[service.name] = service;

    if (kDebugMode) {
      print('EasyPasta 设备已解析: ${service.name}');
      print('解析信息: ${service.toJson()}');
    }

    onServicesResolved?.call(_resolvedServices.values.toList());
  }

  /// 处理丢失的服务
  void _handleServiceLost(BonsoirService service) {
    _discoveredServices.remove(service.name);
    _resolvedServices.remove(service.name);

    if (kDebugMode) {
      print('EasyPasta 设备离线: ${service.name}');
    }

    onServiceLost?.call(service);
    onServicesFound?.call(_discoveredServices.values.toList());
    onServicesResolved?.call(_resolvedServices.values.toList());
  }

  /// 手动解析指定服务（当用户想要连接到该服务时调用）
  Future<void> resolveService(String serviceName) async {
    final service = _discoveredServices[serviceName];
    if (service != null && _discovery != null) {
      try {
        await service.resolve(_discovery!.serviceResolver);
        if (kDebugMode) {
          print('开始解析服务: $serviceName');
        }
      } catch (e) {
        final error = '解析服务失败: $e';
        if (kDebugMode) print(error);
        onError?.call(error);
      }
    }
  }

  /// 获取当前发现的服务列表（未解析）
  List<BonsoirService> get discoveredServices =>
      _discoveredServices.values.toList();

  /// 获取当前已解析的服务列表
  List<BonsoirService> get resolvedServices =>
      _resolvedServices.values.toList();

  /// 检查服务是否正在运行
  bool get isServiceRunning => _broadcast != null;

  /// 检查是否正在发现设备
  bool get isDiscovering => _discovery != null;

  /// 根据服务名获取发现的服务
  BonsoirService? getDiscoveredService(String name) {
    return _discoveredServices[name];
  }

  /// 根据服务名获取已解析的服务
  BonsoirService? getResolvedService(String name) {
    return _resolvedServices[name];
  }

  /// 获取当前广播的服务信息
  BonsoirService? get currentService => _service;

  /// 清理资源
  Future<void> dispose() async {
    await stopService();
    await stopDiscovery();
    onServicesFound = null;
    onServicesResolved = null;
    onServiceLost = null;
    onError = null;
    onServiceStateChanged = null;
    onDiscoveryStateChanged = null;
  }
}

/// 线程安全的同步方法
void synchronized(Object lock, void Function() body) {
  // Flutter 中的简单同步实现
  body();
}
