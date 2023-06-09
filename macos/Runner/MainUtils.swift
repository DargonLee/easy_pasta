//
//  MainUtils.swift
//  Runner
//
//  Created by Harlans on 2023/5/25.
//

import AppKit

extension NSWorkspace {
    /**
    Get an app name from an app URL.

    ```
    let app = WindowInfo.appOwningFrontmostWindow()
    app?.url
    NSWorkspace.shared.appName(for: …)
    //=> "Lungo"
    ```
    */
    func appName(for url: URL) -> String {
        url.localizedName.removingSuffix(".app")
    }
}


extension NSRunningApplication {
    /**
    Like `.localizedName` but guaranteed to return something useful even if the name is not available.
    */
    var localizedTitle: String {
        localizedName
            ?? executableURL?.deletingPathExtension().lastPathComponent
            ?? bundleURL?.deletingPathExtension().lastPathComponent
            ?? bundleIdentifier
            ?? (processIdentifier == -1 ? nil : "PID\(processIdentifier)")
            ?? "<Unknown>"
    }
}

extension BinaryInteger {
    var boolValue: Bool { self != 0 }
}


/**
Static representation of a window.

- Note: The `name` property is always `nil` on macOS 10.15 and later unless you request “Screen Recording” permission.
*/
struct WindowInfo {
    struct Owner {
        let name: String
        let processIdentifier: Int
        let bundleIdentifier: String?
        let app: NSRunningApplication?
    }

    // Most of these keys are guaranteed to exist: https://developer.apple.com/documentation/coregraphics/quartz_window_services/required_window_list_keys

    let identifier: CGWindowID
    let name: String?
    let owner: Owner
    let bounds: CGRect
    let layer: Int
    let alpha: Double
    let memoryUsage: Int
    let sharingState: CGWindowSharingType // https://stackoverflow.com/questions/27695742/what-does-kcgwindowsharingstate-actually-do
    let isOnScreen: Bool

    /**
    Accepts a window dictionary coming from `CGWindowListCopyWindowInfo`.
    */
    private init(windowDictionary window: [String: Any]) {
        self.identifier = window[kCGWindowNumber as String] as! CGWindowID
        self.name = window[kCGWindowName as String] as? String

        let processIdentifier = window[kCGWindowOwnerPID as String] as! Int
        let app = NSRunningApplication(processIdentifier: pid_t(processIdentifier))

        self.owner = Owner(
            name: window[kCGWindowOwnerName as String] as? String ?? app?.localizedTitle ?? "<Unknown>",
            processIdentifier: processIdentifier,
            bundleIdentifier: app?.bundleIdentifier,
            app: app
        )

        self.bounds = CGRect(dictionaryRepresentation: window[kCGWindowBounds as String] as! CFDictionary)!
        self.layer = window[kCGWindowLayer as String] as! Int
        self.alpha = window[kCGWindowAlpha as String] as! Double
        self.memoryUsage = window[kCGWindowMemoryUsage as String] as? Int ?? 0
        self.sharingState = CGWindowSharingType(rawValue: window[kCGWindowSharingState as String] as! UInt32)!
        self.isOnScreen = (window[kCGWindowIsOnscreen as String] as? Int)?.boolValue ?? false
    }
}


extension WindowInfo {
    typealias Filter = (Self) -> Bool

    /**
    Filters out fully transparent windows and windows smaller than 50 width or height.
    */
    static func defaultFilter(window: Self) -> Bool {
        let minimumWindowSize = 50.0

        // Skip windows outside the expected level range.
        guard
            window.layer < NSWindow.Level.screenSaver.rawValue,
            window.layer >= NSWindow.Level.normal.rawValue
        else {
            return false
        }

        // Skip fully transparent windows, like with Chrome.
        guard window.alpha > 0 else {
            return false
        }

        // Skip tiny windows, like the Chrome link hover statusbar.
        guard
            window.bounds.width >= minimumWindowSize,
            window.bounds.height >= minimumWindowSize
        else {
            return false
        }

        // You might think that we could simply skip windows that are `window.owner.app?.activationPolicy != .regular`, but menu bar apps are `.accessory`, and they might be the source of some copied data.
        guard !window.owner.name.lowercased().hasSuffix("agent") else {
            return false
        }

        let appIgnoreList = [
            "com.apple.dock",
            "com.apple.notificationcenterui",
            "com.apple.screencaptureui",
            "com.apple.PIPAgent",
            "com.sindresorhus.Pasteboard-Viewer"
        ]

        if appIgnoreList.contains(window.owner.bundleIdentifier ?? "") {
            return false
        }

        return true
    }

    static func allWindows(
        options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements],
        filter: Filter = defaultFilter
    ) -> [Self] {
        let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
        return info.map { self.init(windowDictionary: $0) }.filter(filter)
    }
}

extension WindowInfo {
    struct UserApp: Hashable, Identifiable {
        let url: URL
        let bundleIdentifier: String

        var id: URL { url }
    }

    /**
    Returns the URL and bundle identifier of the app that owns the frontmost window.

    This method returns more correct results than `NSWorkspace.shared.frontmostApplication?.bundleIdentifier`. For example, the latter cannot correctly detect the 1Password Mini window.
    */
    static func appOwningFrontmostWindow() -> UserApp? {
        func createApp(_ runningApp: NSRunningApplication?) -> UserApp? {
            guard
                let runningApp,
                let url = runningApp.bundleURL,
                let bundleIdentifier = runningApp.bundleIdentifier
            else {
                return nil
            }

            return UserApp(url: url, bundleIdentifier: bundleIdentifier)
        }

        guard
            let app = (
                allWindows()
                    // TODO: Use `.firstNonNil()` here when available.
                    .lazy
                    .compactMap { createApp($0.owner.app) }
                    .first
            )
        else {
            return createApp(NSWorkspace.shared.frontmostApplication)
        }

        return app
    }
}

extension URL {
    private func resourceValue<T>(forKey key: URLResourceKey) -> T? {
        guard let values = try? resourceValues(forKeys: [key]) else {
            return nil
        }

        return values.allValues[key] as? T
    }

    var localizedName: String { resourceValue(forKey: .localizedNameKey) ?? lastPathComponent }
}

extension String {
    func removingSuffix(_ suffix: Self, caseSensitive: Bool = true) -> Self {
        guard caseSensitive else {
            guard let range = range(of: suffix, options: [.caseInsensitive, .anchored, .backwards]) else {
                return self
            }

            return replacingCharacters(in: range, with: "")
        }

        guard hasSuffix(suffix) else {
            return self
        }

        return Self(dropLast(suffix.count))
    }
}


func runShellCommand(_ command: String) {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", command]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    let file = pipe.fileHandleForReading
    task.launch()

    let data = file.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        print(output)
    }
}

func registerLaunchctl() {
    let plistName = "com.example.easyPasta.plist"
    let libaryPath = NSHomeDirectory() + "/Library/LaunchAgents/"
    let targetFilePath = "\(libaryPath)\(plistName)"
    if FileManager.default.fileExists(atPath: targetFilePath) {
        return
    }
    
    let path = Bundle.main.path(forResource: plistName, ofType: nil)
    if let path = path {
        let command = "cp -rf \(path) \(libaryPath)"
        runShellCommand(command)
    }
}

func launchctlUnload() {
    let command = "launchctl unload ~/Library/LaunchAgents/com.example.easyPasta.plist"
    runShellCommand(command)
}


func launchctlLoad() {
    let command = "launchctl load ~/Library/LaunchAgents/com.example.easyPasta.plist"
    runShellCommand(command)
}

func launchctl(status: Bool) {
    if status {
        launchctlLoad()
    }else {
        launchctlUnload()
    }
}
