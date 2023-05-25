import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    var statusBarItem: NSStatusItem!
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        if let button = self.statusBarItem.button {
             statusBarItem.button?.title = "⏳"
             button.action = #selector(showMainWindow(_:))
        }
    }
    
    @objc func showMainWindow(_ sender: AnyObject?) {
        self.mainFlutterWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func configureMenuBarForDarkModeChange() {
        var imageName = "status_network_traffic"
        if isDarkMode() {
            imageName = "status_network_traffic_dark"
        }
        self.statusBarItem.button?.image = Bundle.main.image(forResource: imageName)
    }
    
    func isDarkMode() -> Bool {
        return UserDefaults.standard.value(forKey: "AppleInterfaceStyle") as! String == "Dark"
    }
}
