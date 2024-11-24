//
//  ConsoleIO.swift
//  GitCommitCLI
//
//  Created by shahanul on 11/24/24.
//
import Foundation
// Sources/GitCommitCLI/UI/ConsoleIO.swift
@available(macOS 14.0, *)
actor ConsoleIO {
    func askYesNo(_ question: String) async -> Bool {
        print("\(question) (Y/n): ", terminator: "")
        guard let response = readLine()?.lowercased() else { return true }
        return response.starts(with: "y")
    }
    
    func displayError(_ error: Error) {
        print("Error: \(error.localizedDescription)".red)
    }
}
