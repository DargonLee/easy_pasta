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
    case webURL = "public.url"

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

    // MARK: - Initialization
    override init() {
        self.lastChangeCount = UserDefaults.standard.getPasteboardChangeCount()
        super.init()
    }

    // MARK: - Public Interface
    func getPasteboardItem() -> [[String: AnyObject]]? {
        guard hasNewContent else { return nil }

        var items = [[String: AnyObject]]()

        // 获取剪贴板内容
        if let clipboardItems = getClipboardContent() {
            items.append(contentsOf: clipboardItems)
        }

        // 获取源应用信息
        if let metadataItems = getSourceAppMetadata() {
            items.append(contentsOf: metadataItems)
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
        guard let item = pasteboard.pasteboardItems?.first,
            let firstType = item.types.first
        else { return nil }

        var results: [[String: AnyObject]] = []

        if let data = item.data(forType: firstType) {
            switch firstType {
            case ContentType.tiff.pasteboardType:
                results.append(processImage(data))
            case ContentType.webURL.pasteboardType:
                results.append(processURL(data))
            case ContentType.fileURL.pasteboardType:
                results.append(processFileURL(data))
            case ContentType.rtf.pasteboardType:
                results.append(processRTF(data))
            case ContentType.html.pasteboardType:
                results.append(processHTML(data))
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

    private func processURL(_ data: Data) -> [String: AnyObject] {
        guard let urlString = String(data: data, encoding: .utf8),
            let url = URL(string: urlString)
        else {
            return [
                "type": "text" as AnyObject,
                "content": (String(data: data, encoding: .utf8) ?? "") as AnyObject,
            ]
        }

        return [
            "type": "url" as AnyObject,
            "content": url.absoluteString as AnyObject,
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
