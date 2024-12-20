//
//  StatusBarManager.swift
//  Runner
//
//  Created by Harlans on 2024/12/20.
//

import AppKit

class StatusBarManager: NSObject {
    private let statusItem: NSStatusItem
    
    // MARK: - Singleton
    static let shared = StatusBarManager()
    
    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupStatusBarIcon()
        observeDarkModeChanges()
    }
    
    deinit {
        DistributedNotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupStatusBarIcon() {
        updateIcon()
        
        // 设置图标模板模式，让系统自动处理明暗模式
        if let image = statusItem.button?.image {
            image.isTemplate = true
        }
        
        // 配置按钮
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(statusBarButtonClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    private func observeDarkModeChanges() {
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppearanceChange),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }
    
    // MARK: - Icon Management
    func updateIcon() {
        // 使用单一模板图标，让系统自动处理颜色
        guard let image = NSImage(named: "status_network_traffic") ?? Bundle.main.image(forResource: "status_network_traffic") else {
            return
        }
        
        image.size = NSSize(width: 22, height: 22)
        image.isTemplate = true
        statusItem.button?.image = image
    }
    
    // MARK: - Actions
    @objc private func handleAppearanceChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateIcon()
        }
    }
    @objc private func statusBarButtonClicked() {
        if let window = NSApplication.shared.windows.first(where: { $0 is MainFlutterWindow }) {
            guard let screen = NSScreen.main else { return }
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            let x = screenFrame.origin.x + (screenFrame.width - windowFrame.width) / 2
            let y = screenFrame.origin.y + (screenFrame.height - windowFrame.height) / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
