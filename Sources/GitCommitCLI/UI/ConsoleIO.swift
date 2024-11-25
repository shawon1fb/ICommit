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

// Add this to ConsoleIO class
// Update ConsoleIO extension to support zero as an option
extension ConsoleIO {
    func askForChoice(options: Int, includeZero: Bool = false) async -> Int {
        while true {
            let range = includeZero ? "0-\(options)" : "1-\(options)"
            if let input = await askForInput("Enter your choice (\(range)):"),
               let choice = Int(input),
               (includeZero && choice >= 0 && choice <= options) ||
               (!includeZero && choice >= 1 && choice <= options) {
                return choice
            }
            let validRange = includeZero ? "0 and \(options)" : "1 and \(options)"
            print("Invalid choice. Please enter a number between \(validRange)".red)
        }
    }
}

extension ConsoleIO {
    func askForInput(_ prompt: String) async -> String? {
        print(prompt.yellow)
        return readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
