import Cocoa
import FlutterMacOS
import window_manager

// MARK: - Channel Constants
private enum ChannelNames {
    static let event = "com.easy.pasteboard.event"
    static let method = "com.easy.pasteboard.method"
}

// MARK: - Method Names
private enum MethodNames {
    static let setPasteboardItem = "setPasteboardItem"
    static let showMainPasteboardWindow = "showMainPasteboardWindow"
    static let setLaunchCtl = "setLaunchCtl"
}

class MainFlutterWindow: NSWindow {
    // MARK: - Properties
    private let pasteboard = MainFlutterPasteboard()
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    // MARK: - Lifecycle
    override func awakeFromNib() {
        configureWindow()
        super.awakeFromNib()
    }
    
    override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
        super.order(place, relativeTo: otherWin)
        hiddenWindowAtLaunch()
    }

    // MARK: - Window Configuration
    private func configureWindow() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        RegisterGeneratedPlugins(registry: flutterViewController)
    }

    // MARK: - Channel Setup
    private func setupChannels(with controller: FlutterViewController) {
        setupEventChannel(controller)
        setupMethodChannel(controller)
    }

    private func setupEventChannel(_ controller: FlutterViewController) {
        eventChannel = FlutterEventChannel(
            name: ChannelNames.event,
            binaryMessenger: controller.engine.binaryMessenger
        )
        eventChannel?.setStreamHandler(self)
    }

    private func setupMethodChannel(_ controller: FlutterViewController) {
        methodChannel = FlutterMethodChannel(
            name: ChannelNames.method,
            binaryMessenger: controller.engine.binaryMessenger
        )

        methodChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }
    }

    // MARK: - Method Channel Handler
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case MethodNames.setPasteboardItem:
            handleSetPasteboardItem(call.arguments)

        case MethodNames.showMainPasteboardWindow:
            handleShowMainWindow()

        case MethodNames.setLaunchCtl:
            handleSetLaunchCtl(call.arguments)

        default:
            result(FlutterMethodNotImplemented)
            return
        }

        result(0)
    }

    // MARK: - Method Handlers
    private func handleSetPasteboardItem(_ arguments: Any?) {
        debugPrint("Received setPasteboardItem call from dart")
        debugPrint(arguments ?? "")

        if let items = arguments as? [[String: AnyObject]] {
            pasteboard.setPasteboardItem(item: items)
            DispatchQueue.main.async { [weak self] in
                self?.close()
            }
        }
    }

    private func handleShowMainWindow() {
        DispatchQueue.main.async { [weak self] in
            self?.orderFront(nil)
        }
    }

    private func handleSetLaunchCtl(_ arguments: Any?) {
        if let status = arguments as? Bool {
            LaunchctlHelper.launchctl(status: status)
        }
    }

    // MARK: - Keyboard Monitor
    private func setupKeyboardMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.shouldCloseWindow(for: event) == true {
                self?.close()
                return nil
            }
            return event
        }
    }

    private func shouldCloseWindow(for event: NSEvent) -> Bool {
        return event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "w"
    }

    // MARK: - Pasteboard Monitoring
    private func startPasteboardMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let array = self?.pasteboard.getPasteboardItem() else { return }
            self?.eventSink?(array)
        }
    }
}

// MARK: - FlutterStreamHandler
extension MainFlutterWindow: FlutterStreamHandler {
    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
