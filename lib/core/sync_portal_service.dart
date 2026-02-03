import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/clipboard_type.dart';

/// 移动端同步 Portal 服务
/// 在局域网内启动 Web 服务器，供手机浏览器访问以实现跨设备同步
class SyncPortalService {
  static final SyncPortalService _instance = SyncPortalService._internal();
  static SyncPortalService get instance => _instance;

  HttpServer? _server;
  final _router = Router();
  int _port = 8899;
  String? _ip;

  // 服务器状态监控
  final ValueNotifier<bool> isRunning = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  // 当前待同步的内容
  ClipboardItemModel? _currentItem;

  // 用于通知移动端更新的状态流 (简易 SSE 实现)
  final StreamController<ClipboardItemModel?> _syncController =
      StreamController<ClipboardItemModel?>.broadcast();

  // 用于接收移动端传回的内容
  final StreamController<String> _receivedItemsController =
      StreamController<String>.broadcast();

  Stream<String> get receivedItemsStream => _receivedItemsController.stream;

  // 活跃连接计数
  int _activeConnections = 0;
  bool get hasActiveConnections => _activeConnections > 0;

  SyncPortalService._internal() {
    _setupRoutes();
  }

  void _setupRoutes() {
    // 首页：提供给移动端浏览器
    _router.get('/', _handleIndex);

    // 获取当前剪贴板内容 (JSON)
    _router.get('/api/current', _handleGetCurrent);

    // 图片数据接口
    _router.get('/api/image/<id>', _handleGetImage);

    // 更新流 (SSE)
    _router.get('/api/events', _handleEvents);

    // 接收移动端上传的内容
    _router.post('/api/upload', _handleUpload);
  }

  /// 启动服务器
  Future<bool> start() async {
    try {
      if (_server != null) return true;

      // 获取本地非回环地址
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            _ip = addr.address;
            break;
          }
        }
        if (_ip != null) break;
      }

      // 自动探测可用端口
      int retryCount = 0;
      const int maxRetries = 100; // 尝试从 8899 到 8999

      while (retryCount < maxRetries) {
        try {
          final currentPort = _port + retryCount;
          _server = await io.serve(
              _router.call, InternetAddress.anyIPv4, currentPort);
          _port = currentPort; // 记录实际成功的端口
          break;
        } catch (e) {
          if (e is SocketException &&
              (e.osError?.errorCode == 48 || e.osError?.errorCode == 98)) {
            // 端口已被占用 (macOS: 48, Linux/Android: 98)
            retryCount++;
            continue;
          }
          rethrow;
        }
      }

      if (_server == null) {
        throw Exception(
            'Could not find an available port after $maxRetries attempts');
      }

      isRunning.value = true;
      lastError.value = null;
      if (kDebugMode) {
        print(
            'Sync Portal Server running at http://${_ip ?? "localhost"}:$_port');
      }
      return true;
    } catch (e) {
      isRunning.value = false;
      lastError.value = e.toString();
      if (kDebugMode) print('Failed to start Sync Portal Server: $e');
      return false;
    }
  }

  /// 停止服务器
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    isRunning.value = false;
    _currentItem = null;
  }

  /// 释放资源（仅在应用退出时调用）
  Future<void> dispose() async {
    await stop();

    // 安全地关闭流控制器，防止重复关闭导致的异常
    try {
      if (!_syncController.isClosed) {
        await _syncController.close();
      }
    } catch (e) {
      if (kDebugMode) print('关闭 _syncController 时出错: $e');
    }

    try {
      if (!_receivedItemsController.isClosed) {
        await _receivedItemsController.close();
      }
    } catch (e) {
      if (kDebugMode) print('关闭 _receivedItemsController 时出错: $e');
    }

    // 释放 ValueNotifier
    isRunning.dispose();
    lastError.dispose();
  }

  /// 推送内容到手机
  void pushItem(ClipboardItemModel item) {
    _currentItem = item; // 始终更新当前内容，供新连接获取

    // 只在有活跃连接时才广播更新，节省资源
    if (!hasActiveConnections) {
      if (kDebugMode) {
        print('SyncPortal: No active connections, skipping broadcast');
      }
      return;
    }

    if (kDebugMode) {
      print(
          'SyncPortal: Pushing item ${item.id} to $_activeConnections active connection(s) (Type: ${item.ptype}, Value length: ${item.pvalue.length})');
      if (item.ptype == ClipboardType.image) {
        print('SyncPortal: Image bytes length: ${item.bytes?.length ?? 0}');
      }
    }
    _syncController.add(item);
    if (kDebugMode) {
      print('SyncPortal: Item pushed to stream');
    }
  }

  String? get portalUrl => _ip != null ? 'http://$_ip:$_port' : null;

  // --- Handler 模拟 ---

  Response _handleIndex(Request request) {
    final html = _getPortalHtml();
    return Response.ok(html,
        headers: {'content-type': 'text/html; charset=utf-8'});
  }

  Response _handleGetCurrent(Request request) {
    if (_currentItem == null) {
      return Response.ok(jsonEncode({'status': 'empty'}));
    }
    return Response.ok(
        jsonEncode({
          'id': _currentItem!.id,
          'type': _currentItem!.ptype.toString(),
          'value': _currentItem!.pvalue,
          'hasImage': _currentItem!.ptype == ClipboardType.image,
        }),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _handleGetImage(Request request, String id) async {
    if (_currentItem == null ||
        _currentItem!.id != id ||
        _currentItem!.bytes == null) {
      return Response.notFound('Image not found');
    }
    return Response.ok(_currentItem!.bytes!,
        headers: {'content-type': 'image/png'});
  }

  Response _handleEvents(Request request) {
    if (kDebugMode) {
      print(
          'SyncPortal: New SSE connection from ${request.context['shelf.io.connection_info']}');
    }

    // 增加活跃连接计数
    _activeConnections++;
    if (kDebugMode) {
      print('SyncPortal: Active connections: $_activeConnections');
    }

    StreamSubscription<ClipboardItemModel?>? subscription;
    Timer? timer;
    Timer? timeoutTimer;
    bool didCleanup = false;
    DateTime lastActivity = DateTime.now();
    late final StreamController<List<int>> controller;

    void cleanup() {
      if (didCleanup) return;
      didCleanup = true;
      subscription?.cancel();
      timer?.cancel();
      timeoutTimer?.cancel();
      if (!controller.isClosed) {
        controller.close();
      }
      // 减少活跃连接计数
      _activeConnections--;
      if (kDebugMode) {
        print('SyncPortal: Connection cleaned up, active: $_activeConnections');
      }
    }

    controller = StreamController<List<int>>(
      onCancel: cleanup,
      onListen: () {
        // 启动连接超时检测
        timeoutTimer = Timer.periodic(const Duration(seconds: 30), (t) {
          final inactiveDuration = DateTime.now().difference(lastActivity);
          if (inactiveDuration > const Duration(seconds: 60)) {
            cleanup();
          }
        });
      },
    );

    // 发送初始状态
    if (_currentItem != null) {
      if (kDebugMode) {
        print('SyncPortal: Sending initial state to new member');
      }
      if (!controller.isClosed) {
        controller.add(utf8.encode('data: ${jsonEncode({
              'update': true,
              'id': _currentItem!.id
            })}\n\n'));
        lastActivity = DateTime.now();
      }
    }

    subscription = _syncController.stream.listen((item) {
      if (controller.isClosed) return;
      if (kDebugMode) {
        print('SyncPortal: Sending update signal for item ${item?.id}');
      }
      controller.add(utf8
          .encode('data: ${jsonEncode({'update': true, 'id': item?.id})}\n\n'));
      lastActivity = DateTime.now();
    });

    // 定期发送 ping 以保持连接活跃并检测死连接
    timer = Timer.periodic(const Duration(seconds: 15), (t) {
      if (!controller.isClosed) {
        controller.add(utf8.encode(
            'event: ping\ndata: {"time": ${DateTime.now().millisecondsSinceEpoch}}\n\n'));
        lastActivity = DateTime.now();
      }
    });

    return Response.ok(
      controller.stream,
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    );
  }

  Future<Response> _handleUpload(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final text = data['text'] as String?;

      if (text != null && text.trim().isNotEmpty) {
        if (kDebugMode) {
          print('SyncPortal: Received text from mobile: ${text.length} chars');
        }
        _receivedItemsController.add(text);
        return Response.ok(jsonEncode({'status': 'success'}),
            headers: {'content-type': 'application/json'});
      } else {
        return Response.badRequest(body: jsonEncode({'error': 'Empty text'}));
      }
    } catch (e) {
      if (kDebugMode) print('SyncPortal ERROR in upload: $e');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}));
    }
  }

  String _getPortalHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <title>EasyPasta Mobile Sync</title>
    <style>
        :root {
            --primary: #0071e3;
            --bg: #f5f5f7;
            --card-bg: rgba(255, 255, 255, 0.8);
            --text-main: #1d1d1f;
            --text-sec: #86868b;
        }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; 
            background: var(--bg); 
            margin: 0; padding: 20px;
            display: flex; flex-direction: column; align-items: center;
            color: var(--text-main);
        }
        .container { width: 100%; max-width: 500px; }
        .header-row {
            display: flex; justify-content: space-between; align-items: center;
            margin-bottom: 20px; width: 100%;
        }
        .header { font-weight: 700; font-size: 24px; letter-spacing: -0.5px; }
        .refresh-icon {
            background: white; border: none; width: 36px; height: 36px;
            border-radius: 50%; display: flex; align-items: center; justify-content: center;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05); cursor: pointer;
            transition: transform 0.2s, background 0.2s;
        }
        .refresh-icon:active { transform: rotate(180deg) scale(0.9); background: #eee; }
        .card { 
            background: var(--card-bg); backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);
            border-radius: 20px; padding: 24px; 
            box-shadow: 0 8px 32px rgba(0,0,0,0.05);
            margin-bottom: 24px; min-height: 120px;
            display: flex; flex-direction: column;
            border: 1px solid rgba(255,255,255,0.3);
        }
        .input-card { margin-top: 10px; }
        .textarea {
            width: 100%; height: 100px; border: 1px solid #ddd;
            border-radius: 12px; padding: 12px; margin-bottom: 16px;
            font-family: inherit; font-size: 15px; resize: none;
            box-sizing: border-box; background: rgba(255,255,255,0.5);
            outline: none; transition: border-color 0.2s;
        }
        .textarea:focus { border-color: var(--primary); }
        .btn-sec { background: #34c759; margin-top: 10px; }
        .content { font-size: 16px; line-height: 1.6; word-break: break-all; margin-bottom: 24px; white-space: pre-wrap; }
        .image { width: 100%; border-radius: 12px; margin-bottom: 24px; display: none; object-fit: contain; max-height: 70vh; }
        .btn { 
            background: var(--primary); color: white; border: none; 
            padding: 14px 28px; border-radius: 14px; font-weight: 600;
            cursor: pointer; font-size: 16px; transition: transform 0.1s, opacity 0.2s;
            text-align: center; width: 100%; box-sizing: border-box;
        }
        .btn:active { transform: scale(0.98); opacity: 0.9; }
        .footer { text-align: center; }
        .status-text { font-size: 13px; color: var(--text-sec); margin-bottom: 8px; }
        .last-updated { font-size: 11px; color: #b0b0b5; }
        
        #toast {
            position: fixed; top: 30px; left: 50%; transform: translateX(-50%);
            background: rgba(0,0,0,0.8); color: white; padding: 12px 24px;
            border-radius: 24px; display: none; z-index: 1000; font-size: 14px; font-weight: 500;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header-row">
            <div class="header">EasyPasta</div>
            <button class="refresh-icon" id="refresh-btn" title="手动刷新">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M23 4v6h-6"></path>
                    <path d="M1 20v-6h6"></path>
                    <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path>
                </svg>
            </button>
        </div>
        <div class="card" id="card">
            <div id="text-content" class="content">等待 Mac 端推送内容...</div>
            <img id="image-content" class="image" src="" />
            <button class="btn" id="copy-btn" style="display:none">一键复制内容</button>
        </div>
        <div class="card input-card">
            <textarea id="upload-input" class="textarea" placeholder="输入内容发送到 Mac..."></textarea>
            <button class="btn btn-sec" id="send-btn">发送到 Mac</button>
        </div>
        <div class="footer">
            <div class="status-text">保持页面开启，Mac 端点击同步后将自动更新</div>
            <div class="last-updated" id="update-time"></div>
        </div>
    </div>
    <div id="toast">已同步到剪贴板</div>

    <script>
        const textEl = document.getElementById('text-content');
        const imgEl = document.getElementById('image-content');
        const copyBtn = document.getElementById('copy-btn');
        const refreshBtn = document.getElementById('refresh-btn');
        const sendBtn = document.getElementById('send-btn');
        const uploadInput = document.getElementById('upload-input');
        const timeEl = document.getElementById('update-time');
        const toast = document.getElementById('toast');
        let currentData = null;

        function showMessage(msg) {
            toast.innerText = msg;
            toast.style.display = 'block';
            setTimeout(() => { toast.style.display = 'none'; }, 2000);
        }

        async function updateContent() {
            try {
                const res = await fetch('/api/current');
                const data = await res.json();
                
                // 更新时间显示
                const now = new Date();
                timeEl.innerText = "最后更新: " + now.getHours().toString().padStart(2, '0') + ":" + now.getMinutes().toString().padStart(2, '0') + ":" + now.getSeconds().toString().padStart(2, '0');

                if (data.status === 'empty') return;
                
                currentData = data;
                if (data.hasImage) {
                    textEl.style.display = 'none';
                    imgEl.style.display = 'block';
                    imgEl.src = '/api/image/' + data.id + '?t=' + new Date().getTime();
                    copyBtn.innerText = '暂不支持直接从网页复制图片';
                    copyBtn.style.background = '#86868b';
                } else {
                    imgEl.style.display = 'none';
                    textEl.style.display = 'block';
                    textEl.innerText = data.value;
                    copyBtn.innerText = '一键复制文字';
                    copyBtn.style.background = '#0071e3';
                }
                copyBtn.style.display = 'block';
            } catch (e) {
                console.error('Fetch error:', e);
            }
        }

        refreshBtn.onclick = () => {
            updateContent();
            console.log("Manual refresh triggered");
        };

        copyBtn.onclick = async () => {
            if (!currentData || currentData.hasImage) return;
            try {
                await navigator.clipboard.writeText(currentData.value);
                showMessage("已同步到剪贴板");
            } catch (err) {
                const textArea = document.createElement("textarea");
                textArea.value = currentData.value;
                document.body.appendChild(textArea);
                textArea.select();
                document.execCommand('copy');
                document.body.removeChild(textArea);
                showMessage("已同步到剪贴板");
            }
        };

        sendBtn.onclick = async () => {
            const text = uploadInput.value.trim();
            if (!text) return;
            
            try {
                sendBtn.disabled = true;
                sendBtn.innerText = "发送中...";
                const res = await fetch('/api/upload', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ text: text })
                });
                const data = await res.json();
                if (data.status === 'success') {
                    uploadInput.value = '';
                    showMessage("已成功发送到 Mac");
                } else {
                    showMessage("发送失败: " + (data.error || "未知错误"));
                }
            } catch (e) {
                showMessage("网络错误: " + e.message);
            } finally {
                sendBtn.disabled = false;
                sendBtn.innerText = "发送到 Mac";
            }
        };

        function showToast() {
            // 已被 showMessage 替代
        }

        // SSE 监听
        let evtSource = null;
        function connectSSE() {
            if (evtSource) evtSource.close();
            
            console.log("Connecting to SSE...");
            evtSource = new EventSource("/api/events");
            
            evtSource.onopen = () => {
                console.log("SSE Connection opened");
            };

            evtSource.onmessage = (event) => {
                console.log("SSE Message received:", event.data);
                const data = JSON.parse(event.data);
                if (data.update) {
                    updateContent();
                }
            };
            
            evtSource.addEventListener('ping', (event) => {
                console.log("SSE Ping received");
            });

            evtSource.onerror = (err) => {
                console.error("SSE Error/Closed, reconnecting...", err);
                evtSource.close();
                setTimeout(connectSSE, 3000);
            };
        }
        
        // 初始加载
        updateContent();
        connectSSE();

        // 轮询机制：作为 SSE 的鲁棒性补充，每 2 秒尝试静默检查一次
        // 这样即使 SSE 断连，用户也无需手动点击刷新按钮
        setInterval(() => {
            updateContent();
        }, 2000);
    </script>
</body>
</html>
    ''';
  }
}
