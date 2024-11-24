//
//  CLIError.swift
//  GitCommitCLI
//
//  Created by shahanul on 11/24/24.
//
import Foundation
// Sources/GitCommitCLI/Errors/CLIError.swift
enum CLIError: LocalizedError {
    case noStagedFiles
    case gitCommandFailed(String)
    case aiGenerationFailed(String)
    case invalidUserInput
    case invalidGitRepository
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .noStagedFiles:
            return "No staged files found"
        case .gitCommandFailed(let message):
            return "Git command failed: \(message)"
        case .aiGenerationFailed(let message):
            return "AI generation failed: \(message)"
        case .invalidUserInput:
            return "Invalid user input"
        case .invalidGitRepository:
            return "Invalid Git repository"
        case .userCancelled:
            return "User cancelled"
        }
    }
}

