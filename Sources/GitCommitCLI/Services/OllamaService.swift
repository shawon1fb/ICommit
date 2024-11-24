//
//  OllamaService.swift
//  GitCommitCLI
//
//  Created by shahanul on 11/24/24.
//
import Foundation
// Sources/GitCommitCLI/Services/OllamaService.swift
@available(macOS 14.0, *)
protocol AIServiceProtocol: Sendable {
    func generateCommitMessage(for files: [GitFile]) async throws -> CommitMessage
}

@available(macOS 14.0, *)
actor OllamaService: AIServiceProtocol {
    private let baseURL = URL(string: "http://localhost:11434/api/generate")!
    private let logger: Logger
    private let model: String = "llama3.2:3b"
    struct OllamaRequest: Codable {
        let model: String
        let prompt: String
        let stream: Bool
    }
    
    struct OllamaResponse: Codable {
        let response: String
        let done: Bool
    }
    
    init(logger: Logger = .init(isVerbose: false)){
        self.logger = logger
    }
    
    func generateCommitMessage(for files: [GitFile]) async throws -> CommitMessage {
        await logger.debug("Generating commit message for \(files.count) files...")
        let filesContent = files.map { file in
            "File: \(file.path)\nChanges:\n\(file.changes)"
        }.joined(separator: "\n\n")
        
        let prompt = """
        Generate a concise commit message following the conventional commits format for these changes:
        \(filesContent)
        
        Response format: <type>(<scope>): <description>
        Types: feat, fix, docs, style, refactor, test, chore
        Keep description under 50 characters.
        Return only the commit message, nothing else.
        """
        
        await logger.api("POST /api/generate")
             
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OllamaRequest(
            model: model,
            prompt: prompt,
            stream: false
        )
        await logger.debug("Using model: \(requestBody)")
        request.httpBody = try JSONEncoder().encode(requestBody)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OllamaResponse.self, from: data)
//        await logger.debug("response =>\n\n \(response)")
        let message = response.response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Fixed parsing logic
        let messageParts = message.split(separator: ":", maxSplits: 1)
        guard messageParts.count == 2 else {
            throw CLIError.aiGenerationFailed("Invalid commit message format: missing description")
        }
        
        let typeAndScope = String(messageParts[0])
        let description = String(messageParts[1]).trimmingCharacters(in: .whitespaces)
        
        // Parse type and scope
        let typeScopeParts = typeAndScope.split(separator: "(")
        guard
            typeScopeParts.count == 2,
            let typeString = typeScopeParts.first.map(String.init),
            let type = CommitType(rawValue: typeString),
            let scopeWithParenthesis = typeScopeParts.last.map(String.init)
        else {
            throw CLIError.aiGenerationFailed("Invalid commit type or scope format")
        }
        
        // Remove trailing parenthesis from scope
        let scope = scopeWithParenthesis.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        
        return CommitMessage(
            type: type,
            scope: scope,
            description: description
        )
    }
}

@available(macOS 14.0, *)
extension OllamaService {
    func processFiles(_ files: [GitFile]) async throws -> String {
        try await files.concurrentMap { @Sendable file in
            "File: \(file.path)\nChanges:\n\(file.changes)"
        }.joined(separator: "\n\n")
    }
}
