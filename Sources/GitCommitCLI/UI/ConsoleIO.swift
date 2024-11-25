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
extension ConsoleIO {
    func askForChoice(options: Int) async -> Int {
        while true {
            if let input = await askForInput("Enter your choice (1-\(options)):"),
               let choice = Int(input),
               choice >= 1 && choice <= options {
                return choice
            }
            print("Invalid choice. Please enter a number between 1 and \(options)".red)
        }
    }
}

extension ConsoleIO {
    func askForInput(_ prompt: String) async -> String? {
        print(prompt.yellow)
        return readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
