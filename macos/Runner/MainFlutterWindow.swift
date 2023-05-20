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
        //self.styleMask = .closable
        
        RegisterGeneratedPlugins(registry: flutterViewController)
        super.awakeFromNib()
        
        /// 初始化Channel
        setupEventChannel(vc: flutterViewController)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            guard let dict = self.pasteboard.getPasteboardItem() else {
                return
            }
            self.eventSink?(dict)
        })
    }
    
    func setupEventChannel(vc: FlutterViewController) {
        eventChannel = FlutterEventChannel(name: "com.easy.pasteboard.event", binaryMessenger: vc.engine.binaryMessenger)
        eventChannel?.setStreamHandler(self)
        
        methodChannel = FlutterMethodChannel(name: "com.easy.pasteboard.method", binaryMessenger: vc.engine.binaryMessenger)
        methodChannel?.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in

            guard call.method == "setPasteboardItem" else {
                result(FlutterMethodNotImplemented)
                return
            }
            print("receive setPasteboardItem call from dart")
            print(call.arguments ?? "")
            
            self?.pasteboard.setPasteboardItem(item: (call.arguments as! [Dictionary<String, AnyObject>]) )
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
