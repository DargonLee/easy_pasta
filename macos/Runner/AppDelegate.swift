import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    
    var statusBarItem: NSStatusItem!
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        let changeCount = NSPasteboard.general.changeCount
        UserDefaults.standard.setPasteboardChangeCount(changeCount: changeCount)
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        if let button = self.statusBarItem.button {
//            statusBarItem.button?.title = "⏳"
            configureMenuBarForDarkModeChange()
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
        let image = Bundle.main.image(forResource: imageName)
        image?.size = NSSize(width: 22, height: 22)
        self.statusBarItem.button?.image = image
    }
    
    func isDarkMode() -> Bool {
        let name = NSApplication.shared.effectiveAppearance.name
        if name == .darkAqua {
            return true
        }
        return false
    }
}
