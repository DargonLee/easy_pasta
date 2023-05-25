//
//  MainManger.swift
//  Runner
//
//  Created by Harlans on 2023/5/25.
//

import Foundation
import FlutterMacOS

final class MainManger {
    var vc: FlutterViewController?
    static let shared = MainManger()
    private init() {}
}
