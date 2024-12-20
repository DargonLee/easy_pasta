//
//  MainFlutterPasteboard.swift
//  Runner
//
//  Created by Harlans on 2023/5/19.
//

import Cocoa
import FlutterMacOS

// MARK: - PasteboardDataType
enum PasteboardDataType {
    case text
    case rtf
    case image
    case file
    case other(NSPasteboard.PasteboardType)

    var pasteboardType: NSPasteboard.PasteboardType {
        switch self {
        case .text: return .string
        case .rtf: return .rtf
        case .image: return .tiff
        case .file: return .fileURL
        case .other(let type): return type
        }
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
    private var changeCount: Int

    // MARK: - Initialization
    override init() {
        self.changeCount = UserDefaults.standard.getPasteboardChangeCount()
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

        changeCount += items.count
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
        guard currentCount > changeCount else { return false }
        changeCount = currentCount
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
        guard let firstItem = pasteboard.pasteboardItems?.first else { return nil }

        return firstItem.types
            .filter { !$0.rawValue.starts(with: "dyn") }
            .compactMap { type -> [String: AnyObject]? in
                guard let data = firstItem.data(forType: type) else { return nil }
                let processedData = processData(data: data, type: type)
                return [type.rawValue: FlutterStandardTypedData(bytes: processedData)]
            }
    }

    private func processData(data: Data, type: NSPasteboard.PasteboardType) -> Data {
        switch type {
        case .rtf:
            return convertRtfToHtml(data: data) ?? data
        default:
            return data
        }
    }

    private func convertRtfToHtml(data: Data) -> Data? {
        guard let attributedString = NSAttributedString(rtf: data, documentAttributes: nil) else {
            return nil
        }

        do {
            return try attributedString.data(
                from: NSRange(location: 0, length: attributedString.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
            )
        } catch {
            print("RTF to HTML conversion failed:", error)
            return nil
        }
    }

    private func getSourceAppMetadata() -> [[String: AnyObject]]? {
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

    private func writeToPasteboard(data: AnyObject, forType type: String) {
        guard let flutterData = data as? FlutterStandardTypedData else {
            print("Invalid data format for type:", type)
            return
        }

        let success = pasteboard.setData(
            flutterData.data,
            forType: NSPasteboard.PasteboardType(type)
        )

        print("Set pasteboard data for type \(type):", success)
    }
}
