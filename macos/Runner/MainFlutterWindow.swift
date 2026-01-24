import Cocoa
import FlutterMacOS
import window_manager
import LaunchAtLogin

class MainFlutterWindow: NSWindow {
    private var lastExternalBundleId: String?
    private var appActivationObserver: NSObjectProtocol?

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
        startAppActivationObserver()
        
        FlutterMethodChannel(
            name: "launch_at_startup", binaryMessenger:  flutterViewController.engine.binaryMessenger
        )
        .setMethodCallHandler { (_ call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "launchAtStartupIsEnabled":
                result(LaunchAtLogin.isEnabled)
            case "launchAtStartupSetEnabled":
                if let arguments = call.arguments as? [String: Any] {
                    LaunchAtLogin.isEnabled = arguments["setEnabledValue"] as! Bool
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        let appSourceChannel = FlutterMethodChannel(
            name: "app_source", binaryMessenger: flutterViewController.engine.binaryMessenger
        )
        appSourceChannel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "getFrontmostApp":
                if let sourceId = self?.pasteboardSourceBundleId() {
                    if sourceId != Bundle.main.bundleIdentifier {
                        self?.lastExternalBundleId = sourceId
                    }
                    result(sourceId)
                    return
                }
                let selfBundleId = Bundle.main.bundleIdentifier
                let frontmostId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
                if let frontmostId, frontmostId != selfBundleId {
                    self?.lastExternalBundleId = frontmostId
                    result(frontmostId)
                    return
                }
                if let cached = self?.lastExternalBundleId {
                    result(cached)
                    return
                }
                let fallbackId = WindowInfo.appOwningFrontmostWindow()?.bundleIdentifier
                if let fallbackId, fallbackId != selfBundleId {
                    self?.lastExternalBundleId = fallbackId
                }
                result(fallbackId)
            case "getAppIcon":
                guard let bundleId = call.arguments as? String else {
                    result(FlutterError(code: "invalid_args", message: "bundleId required", details: nil))
                    return
                }
                let data = self?.appIconData(for: bundleId)
                if let data {
                    result(FlutterStandardTypedData(bytes: data))
                } else {
                    result(nil)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        let autoPasteChannel = FlutterMethodChannel(
            name: "auto_paste", binaryMessenger: flutterViewController.engine.binaryMessenger
        )
        autoPasteChannel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "checkAccessibility":
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
                let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
                result(isTrusted)
            case "requestAccessibility":
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                AXIsProcessTrustedWithOptions(options as CFDictionary)
                result(nil)
            case "paste":
                self?.performPaste(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        RegisterGeneratedPlugins(registry: flutterViewController)
    }

    private func performPaste(result: @escaping FlutterResult) {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !isTrusted {
            result(false)
            return
        }

        // 1. 寻找目标应用: 优先级 lastExternalBundleId -> 当前最前应用(非EasyPasta)
        var targetApp: NSRunningApplication?
        
        if let bundleId = lastExternalBundleId {
            targetApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId })
        }
        
        if targetApp == nil {
            // 兜底方案: 取除了自己之外最前面的应用
            targetApp = NSWorkspace.shared.runningApplications.first { app in
                app.isActive == false && app.bundleIdentifier != Bundle.main.bundleIdentifier && app.activationPolicy == .regular
            }
        }

        if let app = targetApp {
            app.activate(options: [.activateIgnoringOtherApps])
        }

        // 2. 延迟执行模拟按键, 给窗口切换留出一点点时间
        // 增加一点时间, 确保目标应用已经完全激活并获得了键盘焦点
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let source = CGEventSource(stateID: .combinedSessionState)
            
            // Cmd Key Code: 0x37 (55), V Key Code: 0x09 (9)
            guard let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else {
                result(false)
                return
            }
            vKeyDown.flags = .maskCommand
            
            guard let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
                result(false)
                return
            }
            vKeyUp.flags = .maskCommand
            
            vKeyDown.post(tap: .cghidEventTap)
            vKeyUp.post(tap: .cghidEventTap)
            
            result(true)
        }
    }

    deinit {
        if let appActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(appActivationObserver)
        }
    }

    private func appIconData(for bundleId: String) -> Data? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: appURL.path)
        let targetSize = NSSize(width: 32, height: 32)
        return icon.pngData(size: targetSize)
    }

    private func pasteboardSourceBundleId() -> String? {
        let pasteboard = NSPasteboard.general
        let typeNames = [
            "org.nspasteboard.source",
            "org.nspasteboard.SourceApplication",
            "com.apple.pasteboard.source",
            "com.apple.pasteboard.SourceApplication"
        ]

        for name in typeNames {
            let type = NSPasteboard.PasteboardType(name)
            if let value = pasteboard.string(forType: type),
               let bundleId = normalizeBundleId(from: value) {
                return bundleId
            }
            if let data = pasteboard.data(forType: type),
               let bundleId = bundleIdFromData(data) {
                return bundleId
            }
        }
        return nil
    }

    private func normalizeBundleId(from value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        if trimmed.hasPrefix("file://") || trimmed.contains(".app") || trimmed.hasPrefix("/") {
            let path = trimmed.replacingOccurrences(of: "file://", with: "")
            let url = URL(fileURLWithPath: path)
            if let bundle = Bundle(url: url) {
                return bundle.bundleIdentifier
            }
        }
        return trimmed
    }

    private func bundleIdFromData(_ data: Data) -> String? {
        guard
            let plist = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ),
            let dict = plist as? [String: Any]
        else {
            return nil
        }
        if let bundleId = dict["bundleIdentifier"] as? String {
            return bundleId
        }
        if let bundleId = dict["bundleID"] as? String {
            return bundleId
        }
        if let bundleId = dict["bundle_id"] as? String {
            return bundleId
        }
        return nil
    }

    private func startAppActivationObserver() {
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                let bundleId = app.bundleIdentifier,
                bundleId != Bundle.main.bundleIdentifier
            else {
                return
            }
            self?.lastExternalBundleId = bundleId
        }
    }
}

private extension NSImage {
    func pngData(size: NSSize) -> Data? {
        let image = self.copy() as? NSImage ?? self
        image.size = size
        var rect = NSRect(origin: .zero, size: size)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            return nil
        }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        return rep.representation(using: .png, properties: [:])
    }
}
