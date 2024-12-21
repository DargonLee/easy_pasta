//
//  MainFlutterPasteboard.swift
//  Runner
//
//  Created by Harlans on 2023/5/19.
//

import Cocoa
import FlutterMacOS

// MARK: - PasteboardDataType
private enum ContentType: String {
    case plainText = "public.utf8-plain-text"
    case rtf = "public.rtf"
    case html = "public.html"
    case tiff = "public.tiff"
    case fileURL = "public.file-url"

    var pasteboardType: NSPasteboard.PasteboardType {
        return NSPasteboard.PasteboardType(rawValue: self.rawValue)
    }
}

// MARK: - PasteboardMetadata
private struct PasteboardMetadata {
    static let appId = "appId"
    static let appIcon = "appIcon"
    static let appName = "appName"

    let bundleId: String?
    let appIcon: NSImage?
    let appName: String?

    init(from app: UserApp) {
        self.bundleId = app.bundleIdentifier
        let appURL = app.url
        self.appIcon = NSWorkspace.shared.icon(forFile: appURL.path)
        self.appName = NSWorkspace.shared.appName(for: appURL)
    }
}

class MainFlutterPasteboard: NSObject {
    // MARK: - Properties
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var bundleId = ""

    // MARK: - Initialization
    override init() {
        self.lastChangeCount = UserDefaults.standard.getPasteboardChangeCount()
        super.init()
    }

    // MARK: - Public Interface
    func getPasteboardItem() -> [[String: AnyObject]]? {
        guard hasNewContent else { return nil }

        var items = [[String: AnyObject]]()

        // 获取源应用信息
        if let metadataItems = getSourceAppMetadata() {
            items.append(contentsOf: metadataItems)
        }
        
        // 获取剪贴板内容
        if let clipboardItems = getClipboardContent() {
            items.append(contentsOf: clipboardItems)
        }

        return items.isEmpty ? nil : items
    }

    func setPasteboardItem(item: [[String: AnyObject]]?) {
        guard let items = item else { return }

        lastChangeCount += items.count
        pasteboard.clearContents()

        for item in items {
            guard let (type, data) = item.first else { continue }
            if isMetadataKey(type) { continue }

            writeToPasteboard(data: data, forType: type)
        }
    }

    // MARK: - Private Helpers
    private var hasNewContent: Bool {
        let currentCount = pasteboard.changeCount
        guard currentCount > lastChangeCount else { return false }
        lastChangeCount = currentCount
        return true
    }

    private func isMetadataKey(_ key: String) -> Bool {
        [
            PasteboardMetadata.appId,
            PasteboardMetadata.appIcon,
            PasteboardMetadata.appName,
        ].contains(key)
    }

    private func getClipboardContent() -> [[String: AnyObject]]? {
        guard let pasteboardItems = pasteboard.pasteboardItems,
              let firstItem = pasteboardItems.first else { return nil }
        
        var results: [[String: AnyObject]] = []
        let types = firstItem.types
        
        if let sourceContent = getSourceContent(from: firstItem, types: types) {
            results.append(sourceContent)
            return results
        }
        
        if let generalContent = getGeneralContent(from: firstItem, types: types) {
            results.append(contentsOf: generalContent)
        }
        
        return results.isEmpty ? nil : results
    }
    
    private func getSourceContent(from item: NSPasteboardItem, types: [NSPasteboard.PasteboardType]) -> [String: AnyObject]? {
        
        if types.contains(ContentType.rtf.pasteboardType),
           let rtfData = item.data(forType: ContentType.rtf.pasteboardType) {
            return processRTF(rtfData)
        }
        
        if let sourceCodeData = item.data(forType: ContentType.plainText.pasteboardType) {
            if MainFlutterPasteboard.sampialIDEBundles.contains(bundleId) {
                return processSourceCode(sourceCodeData)
            }
        }
        
        if types.contains(ContentType.html.pasteboardType) {
            if let htmlData = item.data(forType: ContentType.html.pasteboardType) {
                return processHTML(htmlData)
            }
        }
        
        return nil
    }
    
    private func getGeneralContent(from item: NSPasteboardItem, types: [NSPasteboard.PasteboardType]) -> [[String: AnyObject]]? {
        guard let item = pasteboard.pasteboardItems?.first,
              let firstType = item.types.first else { return nil }
        
        var results: [[String: AnyObject]] = []
        
        if let data = item.data(forType: firstType) {
            switch firstType {
            case ContentType.tiff.pasteboardType:
                results.append(processImage(data))
            case ContentType.fileURL.pasteboardType:
                results.append(processFileURL(data))
            default:
                if let textData = item.data(forType: ContentType.plainText.pasteboardType) {
                    results.append(processPlainText(textData))
                }
            }
        }

        return results.isEmpty ? nil : results
    }

    private func writeToPasteboard(data: AnyObject, forType type: String) {
        guard let flutterData = data as? FlutterStandardTypedData else {
            NSLog("❌ 无效的数据格式: \(type)")
            return
        }
        let pasteboardType = NSPasteboard.PasteboardType(type)
        pasteboard.setData(flutterData.data, forType: pasteboardType)
    }
}

extension MainFlutterPasteboard {
    private func processRTF(_ data: Data) -> [String: AnyObject] {
        guard let attributedString = NSAttributedString(rtf: data, documentAttributes: nil) else {
            return [
                "type": "text" as AnyObject,
                "content": (String(data: data, encoding: .utf8) ?? "") as AnyObject,
            ]
        }

        do {
            let htmlData = try attributedString.data(
                from: NSRange(location: 0, length: attributedString.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
            )
            return [
                "type": "rtf" as AnyObject,
                "content": (String(data: htmlData, encoding: .utf8) ?? "") as AnyObject,
            ]
        } catch {
            return [
                "type": "text" as AnyObject,
                "content": attributedString.string as AnyObject,
            ]
        }
    }

    private func processHTML(_ data: Data) -> [String: AnyObject] {
        return [
            "type": "html" as AnyObject,
            "content": (String(data: data, encoding: .utf8) ?? "") as AnyObject,
        ]
    }

    private func processImage(_ data: Data) -> [String: AnyObject] {
        return [
            "type": "tiff" as AnyObject,
            "content": FlutterStandardTypedData(bytes: data),
        ]
    }

    private func processFileURL(_ data: Data) -> [String: AnyObject] {
        guard let path = String(data: data, encoding: .utf8),
            let url = URL(string: path)
        else {
            return [
                "type": "text" as AnyObject,
                "content": (String(data: data, encoding: .utf8) ?? "") as AnyObject,
            ]
        }

        return [
            "type": "file" as AnyObject,
            "content": path as AnyObject
        ]
    }

    private func processPlainText(_ data: Data) -> [String: AnyObject] {
        return [
            "type": "text" as AnyObject,
            "content": (String(data: data, encoding: .utf8) ?? "") as AnyObject,
        ]
    }
    
    private func processSourceCode(_ data: Data) -> [String: AnyObject] {
        let language = getSourceMetadata()
        return [
            "type": "source_code" as AnyObject,
            "content": (String(data: data, encoding: .utf8) ?? "") as AnyObject,
        ]
    }
    
    private func getSourceMetadata() -> String {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return "unknown"
        }
        
        let language: String
        switch app.bundleIdentifier {
        case "com.apple.dt.Xcode":
            language = "swift"
        case "com.microsoft.VSCode":
            language = "javascript" // 可以进一步完善
        default:
            language = "unknown"
        }
        
        return language
    }
}

extension MainFlutterPasteboard {
    fileprivate func getSourceAppMetadata() -> [[String: AnyObject]]? {
        guard let app = WindowInfo.appOwningFrontmostWindow() else { return nil }
        let metadata = PasteboardMetadata(from: app)

        var items = [[String: AnyObject]]()

        // Bundle ID
        if let bundleId = metadata.bundleId,
            let data = bundleId.data(using: .utf8)
        {
            self.bundleId = bundleId
            items.append([PasteboardMetadata.appId: FlutterStandardTypedData(bytes: data)])
        }

        // App Icon
        if let icon = metadata.appIcon,
            let tiffData = icon.tiffRepresentation,
            let bitmapImage = NSBitmapImageRep(data: tiffData),
            let pngData = bitmapImage.representation(using: .png, properties: [:])
        {
            items.append([PasteboardMetadata.appIcon: FlutterStandardTypedData(bytes: pngData)])
        }

        // App Name
        if let name = metadata.appName,
            let data = name.data(using: .utf8)
        {
            items.append([PasteboardMetadata.appName: FlutterStandardTypedData(bytes: data)])
        }

        return items.isEmpty ? nil : items
    }
}

extension MainFlutterPasteboard {
    static let sampialIDEBundles = [
        // Xcode
        "com.apple.dt.Xcode",
        
        // Visual Studio Code
        "com.microsoft.VSCode",
        "com.visualstudio.code.oss",
        "com.todesktop.230313mzl4w4u92",
        
        // JetBrains IDEs
        "com.jetbrains.intellij",           // IntelliJ IDEA
        "com.jetbrains.intellij.ce",        // IntelliJ IDEA CE
        "com.jetbrains.WebStorm",           // WebStorm
        "com.jetbrains.pycharm",            // PyCharm
        "com.jetbrains.pycharm.ce",         // PyCharm CE
        "com.jetbrains.CLion",              // CLion
        "com.jetbrains.AppCode",            // AppCode
        "com.jetbrains.rubymine",           // RubyMine
        "com.jetbrains.PhpStorm",           // PhpStorm
        "com.jetbrains.goland",             // GoLand
        
        // Sublime Text
        "com.sublimetext.4",
        "com.sublimetext.3",
        
        // Atom
        "com.github.atom",
        
        // Nova
        "com.panic.Nova",
        
        // BBEdit
        "com.barebones.bbedit",
        
        // TextMate
        "com.macromates.TextMate",
        
        // Android Studio
        "com.google.android.studio",
        
        // Eclipse
        "org.eclipse.platform.ide",
        
        // NetBeans
        "org.netbeans.ide",
        
        // Vim/MacVim
        "org.vim.MacVim",
        
        // Emacs
        "org.gnu.Emacs",
        
        // CodeRunner
        "com.krill.CodeRunner",
        
        // CotEditor
        "com.coteditor.CotEditor",
        
        // Nova
        "com.panic.Nova",
        
        // Brackets
        "io.brackets.appshell"
    ]
}
