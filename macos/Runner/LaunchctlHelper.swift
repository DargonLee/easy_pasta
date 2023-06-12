//
//  LaunchctlHelper.swift
//  Runner
//
//  Created by Harlans on 2023/6/12.
//

import Foundation


let LaunchctlPlistName = "com.example.easyPasta.plist"
let SystemLibaryPath = NSHomeDirectory() + "/Library/LaunchAgents/"
let TargetFilePath = "\(SystemLibaryPath)\(LaunchctlPlistName)"

func registerLaunchctl() {
    if FileManager.default.fileExists(atPath: TargetFilePath) {
        try? FileManager.default.removeItem(atPath: TargetFilePath)
    }
    
    let path = Bundle.main.path(forResource: LaunchctlPlistName, ofType: nil)
    if let path = path {
        let command = "cp -rf \(path) \(SystemLibaryPath)"
        runShellCommand(command)
    }
}

func launchctlUnload() {
    let command = "launchctl unload ~/Library/LaunchAgents/com.example.easyPasta.plist"
    runShellCommand(command)
}


func launchctlLoad() {
    registerLaunchctl()
    let command = "launchctl load ~/Library/LaunchAgents/com.example.easyPasta.plist"
    runShellCommand(command)
}

func launchctl(status: Bool) {
    if status {
        launchctlLoad()
    }else {
        launchctlUnload()
    }
}

func runShellCommand(_ command: String) {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", command]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    let file = pipe.fileHandleForReading
    task.launch()

    let data = file.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        print(output)
    }
}
