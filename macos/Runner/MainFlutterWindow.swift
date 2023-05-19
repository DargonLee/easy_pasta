import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, FlutterStreamHandler {
    var pasteboard = MainFlutterPasteboard()
    var eventChannel: FlutterEventChannel?
    var eventSink : FlutterEventSink?
    
    var count = 0
    
    
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
        eventChannel = FlutterEventChannel(name: "com.easy.pasteboard", binaryMessenger: vc.engine.binaryMessenger)
        eventChannel?.setStreamHandler(self)
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
