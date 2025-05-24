import 'package:bonsoir/bonsoir.dart';

class BonsoirManager {
  // 私有构造函数，防止外部创建多个实例
  BonsoirManager._privateConstructor();

  // 静态实例
  static final BonsoirManager _instance = BonsoirManager._privateConstructor();

  // 获取单例实例
  static BonsoirManager get instance => _instance;

  // BonsoirService 和 BonsoirDiscovery 实例
  BonsoirService? _service;
  BonsoirDiscovery? _discovery;
  BonsoirBroadcast? _broadcast;

  // Service 和 Discovery 的类型
  final String _serviceType = '_easypaste-service._tcp';
  final String _serviceName = 'easy paste service';
  final int _servicePort = 3030;

  // 初始化 Bonsoir 服务
  Future<void> initializeService() async {
    if (_service == null) {
      _service = BonsoirService(
        name: _serviceName,
        type: _serviceType,
        port: _servicePort,
      );
      print('Bonsoir service initialized');
    }
  }

  // 启动 Discovery
  Future<void> startDiscovery() async {
    if (_discovery == null) {
      _discovery = BonsoirDiscovery(type: _serviceType);
      await _discovery!.ready;
      _discovery!.eventStream!.listen((event) {
        if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
          print('Service found: ${event.service?.toJson()}');
          event.service!.resolve(_discovery!.serviceResolver);
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
          print('Service resolved: ${event.service?.toJson()}');
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
          print('Service lost: ${event.service?.toJson()}');
        }
      });
      await _discovery!.start();
      print('Discovery started');
    }
  }

  // 停止 Discovery
  Future<void> stopDiscovery() async {
    await _discovery?.stop();
    print('Discovery stopped');
  }

  // 启动广播
  Future<void> startBroadcast() async {
    if (_broadcast == null) {
      await initializeService();
      _broadcast = BonsoirBroadcast(service: _service!);
      await _broadcast!.ready;
      await _broadcast!.start();
      print('Broadcast started');
    }
  }

  // 停止广播
  Future<void> stopBroadcast() async {
    await _broadcast?.stop();
    print('Broadcast stopped');
  }

  // 获取当前的 Discovery 实例
  BonsoirDiscovery? get discovery => _discovery;

  // 获取当前的 Broadcast 实例
  BonsoirBroadcast? get broadcast => _broadcast;

  // 获取当前的 Service 实例
  BonsoirService? get service => _service;
}
