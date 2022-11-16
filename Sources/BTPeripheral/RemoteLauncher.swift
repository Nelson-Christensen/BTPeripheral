//
//  RemoteLauncher.swift
//  BTPeripheral
//
//  Created by MKIII-1 on 2022-11-15.
//

import Foundation

func safeShell(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh") //<--updated
    task.standardInput = nil

    try task.run() //<--updated
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

func LaunchRemote()
{
    do {
        try safeShell("/usr/bin/automator ~/Documents/GitHub/StartRemote.app")
    }
    catch {
        print("\(error)") //handle or silence the error here
    }
}

func QuitRemote()
{
    do {
        try safeShell("/usr/bin/automator ~/Documents/GitHub/QuitRemote.app")
    }
    catch {
        print("\(error)") //handle or silence the error here
    }
}
