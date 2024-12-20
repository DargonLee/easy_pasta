import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    // MARK: - Properties
    private let statusBarManager = StatusBarManager.shared

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
