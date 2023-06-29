//
//  MainFlutterPasteboard.swift
//  Runner
//
//  Created by Harlans on 2023/5/19.
//

import Cocoa
import FlutterMacOS

class MainFlutterPasteboard: NSObject {

    let AppId = "appId"
    let AppIcon = "appIcon"
    let AppName = "appName"
    
    var genral = NSPasteboard.general
    var chanageCount:Int = UserDefaults.standard.getPasteboardChangeCount()
    var isNeedUpdate: Bool {
        get {
            if genral.changeCount > chanageCount {
                chanageCount = genral.changeCount
                return true
            }
            return false
        }
    }
    
    func getPasteboardItem() -> [Dictionary<String, AnyObject>]? {
        
        if isNeedUpdate == false  {
            return nil
        }
        /// Clipboard data
        var array = [Dictionary<String, AnyObject>]()
        if let firstItem = genral.pasteboardItems?.first {
            for type in firstItem.types {
                if type.rawValue.starts(with: "dyn") {
                    continue
                }
                if var data = firstItem.data(forType: type) {
                    if type == NSPasteboard.PasteboardType.rtf {
                        data = rtfDataToHtmlData(data: data)!
                    }
                    let dict = [type.rawValue: FlutterStandardTypedData(bytes: data)]
                    array.append(dict)
                }
            }
        }
        /// Source App Info
        let appInfo = getSourceAppInfo()
        if !appInfo.isEmpty {
            array += appInfo
        }
        
        print("appName => \(array)")
        
        return array
    }
    
    func setPasteboardItem(item :[Dictionary<String, AnyObject>]?) {
        guard let item = item else {
            return
        }
        
        chanageCount += item.count;
        
        for dict in item {
            let _ = dict.first { (key , value) -> Bool in
                if key == AppName || key == AppId || key == AppIcon { return false }
                print("set type : \(key)")
                let uintInt8List =  value as! FlutterStandardTypedData
                self.debugPrint(data: uintInt8List, type:key)
                genral.clearContents()
                let result = genral.setData(uintInt8List.data, forType: NSPasteboard.PasteboardType(key))
                print("setPasteboardItem result is \(result)")
                return true
            }
        }
    }
    
    func rtfDataToHtmlData(data: Data) -> Data? {
        let attributedString = NSAttributedString(rtf: data, documentAttributes: nil)!
        do {
            let htmlData = try attributedString.data(from: NSRange(location: 0, length: attributedString.length), documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType:NSAttributedString.DocumentType.html])
            return htmlData
        } catch {
            
        }
        return nil
    }
    
    func getSourceAppInfo() -> [Dictionary<String, AnyObject>] {
        var array = [Dictionary<String, AnyObject>]()
                
        let app = WindowInfo.appOwningFrontmostWindow()
        
        if let bundleId = app?.bundleIdentifier {
            if let data = bundleId.data(using: .utf8) {
                let dict = [AppId:FlutterStandardTypedData(bytes: data)]
                array.append(dict)
            }
        }
        
        if let appURL = app?.url {
            let image = NSWorkspace.shared.icon(forFile: appURL.path)
            if let tiffData = image.tiffRepresentation {
                let bitmapImage = NSBitmapImageRep(data: tiffData)
                let pngData = bitmapImage?.representation(using: .png, properties: [:])
                let dict = [AppIcon:FlutterStandardTypedData(bytes: pngData!)]
                array.append(dict)
            }
            
            let appName = NSWorkspace.shared.appName(for: appURL)
            if let data = appName.data(using: .utf8) {
                let dict = [AppName:FlutterStandardTypedData(bytes: data)]
                array.append(dict)
            }
        }
        
        return array
    }
    
    func debugPrint(data :FlutterStandardTypedData, type: String) {
        let string = NSString(data: data.data, encoding: String.Encoding.utf8.rawValue)
        print(string ?? "")
    }
}
