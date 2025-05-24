import 'package:flutter/material.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:easy_pasta/core/bonsoir_service.dart';

class BonjourTestPage extends StatefulWidget {
  const BonjourTestPage({Key? key}) : super(key: key);

  @override
  State<BonjourTestPage> createState() => _BonjourTestPageState();
}

class _BonjourTestPageState extends State<BonjourTestPage> {
  final BonjourManager _bonjourManager = BonjourManager.instance;
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '8888');

  List<BonsoirService> _discoveredServices = [];
  List<BonsoirService> _resolvedServices = [];
  String _statusMessage = '就绪';
  bool _isServiceRunning = false;
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _setupBonjourCallbacks();
    _deviceNameController.text = 'Test-Device-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  void _setupBonjourCallbacks() {
    _bonjourManager.onServicesFound = (services) {
      setState(() {
        _discoveredServices = services;
        _statusMessage = '发现 ${services.length} 个设备';
      });
    };

    _bonjourManager.onServicesResolved = (services) {
      setState(() {
        _resolvedServices = services;
        _statusMessage = '已解析 ${services.length} 个设备';
      });
    };

    _bonjourManager.onServiceLost = (service) {
      setState(() {
        _statusMessage = '设备 ${service.name} 已离线';
      });
    };

    _bonjourManager.onError = (error) {
      setState(() {
        _statusMessage = '错误: $error';
      });
      _showSnackBar(error, isError: true);
    };

    _bonjourManager.onServiceStateChanged = (isRunning) {
      setState(() {
        _isServiceRunning = isRunning;
        _statusMessage = isRunning ? '服务已启动' : '服务已停止';
      });
    };

    _bonjourManager.onDiscoveryStateChanged = (isDiscovering) {
      setState(() {
        _isDiscovering = isDiscovering;
        _statusMessage = isDiscovering ? '正在发现设备...' : '发现已停止';
      });
    };
  }

  Future<void> _startService() async {
    final deviceName = _deviceNameController.text.trim();
    final port = int.tryParse(_portController.text) ?? 8888;

    if (deviceName.isEmpty) {
      _showSnackBar('请输入设备名称', isError: true);
      return;
    }

    final success = await _bonjourManager.startService(
      deviceName: deviceName,
      port: port,
      attributes: {
        'test_mode': 'true',
        'app_version': '1.0.0',
      },
    );

    if (success) {
      _showSnackBar('服务启动成功');
    }
  }

  Future<void> _stopService() async {
    await _bonjourManager.stopService();
    _showSnackBar('服务已停止');
  }

  Future<void> _startDiscovery() async {
    final success = await _bonjourManager.startDiscovery();
    if (success) {
      _showSnackBar('开始发现设备');
    }
  }

  Future<void> _stopDiscovery() async {
    await _bonjourManager.stopDiscovery();
    _showSnackBar('停止发现设备');
  }

  Future<void> _resolveService(String serviceName) async {
    await _bonjourManager.resolveService(serviceName);
    _showSnackBar('开始解析服务: $serviceName');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bonjour 测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '状态信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('状态: $_statusMessage'),
                    Text('服务运行: ${_isServiceRunning ? "是" : "否"}'),
                    Text('正在发现: ${_isDiscovering ? "是" : "否"}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 服务控制
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '服务控制',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _deviceNameController,
                      decoration: const InputDecoration(
                        labelText: '设备名称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: '端口',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isServiceRunning ? null : _startService,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('启动服务'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isServiceRunning ? _stopService : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('停止服务'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 发现控制
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '设备发现',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isDiscovering ? null : _startDiscovery,
                            icon: const Icon(Icons.search),
                            label: const Text('开始发现'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isDiscovering ? _stopDiscovery : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('停止发现'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 设备列表
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '发现的设备',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _discoveredServices.isEmpty
                            ? const Center(
                          child: Text(
                            '暂无发现的设备\n请确保其他设备也在运行 EasyPasta 服务',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                            : ListView.builder(
                          itemCount: _discoveredServices.length,
                          itemBuilder: (context, index) {
                            final service = _discoveredServices[index];
                            final isResolved = _resolvedServices
                                .any((s) => s.name == service.name);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  isResolved
                                      ? Icons.check_circle
                                      : Icons.device_unknown,
                                  color: isResolved
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                title: Text(service.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('类型: ${service.type}'),
                                    if (isResolved) ...[
                                      Text('端口: ${service.port}'),
                                      if (service.attributes.isNotEmpty)
                                        Text('属性: ${service.attributes}'),
                                    ],
                                  ],
                                ),
                                trailing: isResolved
                                    ? const Icon(Icons.done, color: Colors.green)
                                    : ElevatedButton(
                                  onPressed: () => _resolveService(service.name),
                                  child: const Text('解析'),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _portController.dispose();
    super.dispose();
  }
}