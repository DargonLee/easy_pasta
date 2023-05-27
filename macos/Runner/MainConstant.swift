//
//  MainConstant.swift
//  Runner
//
//  Created by Harlans on 2023/5/26.
//

import Foundation

let ChangeCountKey = "UserDefaultsChangeCount"

extension UserDefaults {
    func setPasteboardChangeCount(changeCount: Int) {
        self.set(changeCount, forKey: ChangeCountKey)
    }
    
    func getPasteboardChangeCount() -> Int {
        return self.value(forKey: ChangeCountKey) as? Int ?? 0
    }
}
