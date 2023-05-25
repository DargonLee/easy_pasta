//
//  MainFlutterPasteboard.swift
//  Runner
//
//  Created by Harlans on 2023/5/19.
//

import Cocoa
import FlutterMacOS

class MainFlutterPasteboard: NSObject {

    var genral = NSPasteboard.general
    var chanageCount = 0
    var isFromApp = false
    
    var isNeedUpdate: Bool {
        get {
            if isFromApp {
                return false
            }
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
        return array
    }
    
    func setPasteboardItem(item :[Dictionary<String, AnyObject>]?) {
        guard let item = item else {
            return
        }
        isFromApp = true
        for dict in item {
            let _ = dict.first { (key , value) -> Bool in
                print("set type : \(key)")
                let uintInt8List =  value as! FlutterStandardTypedData
                // self.debugPrint(data: uintInt8List, type:key)
                genral.clearContents()
                let result = genral.setData(uintInt8List.data, forType: NSPasteboard.PasteboardType(key))
                print("result is \(result)")

                return true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
            self.isFromApp = false
        });
        // print(NSPasteboard.general.pasteboardItems?.first?.types ?? "")
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
    
    func debugPrint(data :FlutterStandardTypedData, type: String) {
        let string = NSString(data: data.data, encoding: String.Encoding.utf8.rawValue)
        print(string ?? "")
    }
}
