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
        var array = [Dictionary<String, AnyObject>]()
        if let firstItem = genral.pasteboardItems?.first {
            for type in firstItem.types {
                if let data = firstItem.data(forType: type) {
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
        for dict in item {
            let _ = dict.first { (key , value) -> Bool in
                print(key)
                print(value)
                let uintInt8List =  value as! FlutterStandardTypedData
                
                let string = NSString(data: uintInt8List.data, encoding: String.Encoding.utf8.rawValue)
                print(string ?? "")
                // genral.setData(uintInt8List.data, forType: NSPasteboard.PasteboardType(key))
                return true
            }
        }
    }
    
}
