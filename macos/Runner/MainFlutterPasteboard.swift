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
    
    func getPasteboardItem() -> [Dictionary<String, AnyObject?>]? {
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
    
}
