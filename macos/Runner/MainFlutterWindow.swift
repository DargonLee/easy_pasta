import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, FlutterStreamHandler {
    var pasteboard = MainFlutterPasteboard()
    
    var methodChannel: FlutterMethodChannel?
    
    var eventChannel: FlutterEventChannel?
    var eventSink : FlutterEventSink?
    
    
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        self.center()
        self.styleMask = .resizable
        
        RegisterGeneratedPlugins(registry: flutterViewController)
        super.awakeFromNib()
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) -> NSEvent? in
            // 判断是否按下 Command+W
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "w" {
                // 关闭窗口
                self.close()
                return nil // 阻止事件传递给其他处理程序
            }
            return event
        }
        
        /// 初始化Channel
        setupEventChannel(vc: flutterViewController)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            guard let array = self.pasteboard.getPasteboardItem() else {
                return
            }
            self.eventSink?(array)
        })
    }
    
    func setupEventChannel(vc: FlutterViewController) {
        eventChannel = FlutterEventChannel(name: "com.easy.pasteboard.event", binaryMessenger: vc.engine.binaryMessenger)
        eventChannel?.setStreamHandler(self)
        
        methodChannel = FlutterMethodChannel(name: "com.easy.pasteboard.method", binaryMessenger: vc.engine.binaryMessenger)
        methodChannel?.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in

            if call.method == "setPasteboardItem" {
                print("receive setPasteboardItem call from dart")
                print(call.arguments ?? "")
                self?.pasteboard.setPasteboardItem(item: (call.arguments as! [Dictionary<String, AnyObject>]))
                DispatchQueue.main.async {
                    self?.close()
                }
            }
            if call.method == "showMainPasteboardWindow" {
                DispatchQueue.main.async {
                    self?.orderFront(nil)
                }
            }
            if call.method == "setLaunchCtl" {
                if let arg = call.arguments {
                    LaunchctlHelper.launchctl(status: arg as! Bool)
                }
            }
            
            result(0)
        })
    }
    
    /// FlutterStreamHandler
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // let error = FlutterError(code: "0", message: nil, details: nil)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // let error = FlutterError(code: "0", message: nil, details: nil)
        return nil
    }
    
}
