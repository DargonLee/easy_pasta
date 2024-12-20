//
//  UserDefaults+Extension.swift
//  Runner
//
//  Created by Harlans on 2024/12/20.
//

import Foundation

extension UserDefaults {
    func setPasteboardChangeCount(changeCount: Int) {
        set(changeCount, forKey: "PasteboardChangeCount")
    }
    
    func getPasteboardChangeCount() -> Int {
        return integer(forKey: "PasteboardChangeCount")
    }
}
