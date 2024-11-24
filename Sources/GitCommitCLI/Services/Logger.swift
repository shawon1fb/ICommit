//
//  Logger.swift
//  GitCommitCLI
//
//  Created by shahanul on 11/24/24.
//

import Foundation

@available(macOS 14.0, *)
actor Logger {
    private let isVerbose: Bool
    private let dateFormatter: DateFormatter
    
    init(isVerbose: Bool) {
        self.isVerbose = isVerbose
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    private func timestamp() -> String {
        dateFormatter.string(from: Date())
    }
    
    func info(_ message: String) {
        print("[\(timestamp())] ℹ️ \(message)".blue)
    }
    
    func success(_ message: String) {
        print("[\(timestamp())] ✅ \(message)".green)
    }
    
    func warning(_ message: String) {
        print("[\(timestamp())] ⚠️ \(message)".yellow)
    }
    
    func error(_ message: String) {
        print("[\(timestamp())] ❌ \(message)".red)
    }
    
    func debug(_ message: String) {
        guard isVerbose else { return }
        print("[\(timestamp())] 🔍 \(message)".gray)
    }
    
    func command(_ command: String) {
        guard isVerbose else { return }
        print("[\(timestamp())] 🔧 Executing: \(command)".gray)
    }
    
    func api(_ request: String) {
        guard isVerbose else { return }
        print("[\(timestamp())] 🌐 API Request: \(request)".gray)
    }
}


