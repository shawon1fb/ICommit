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
  func getAIModels() async throws -> [String]
}

@available(macOS 14.0, *)
actor OllamaService: AIServiceProtocol {

  struct OllamaRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
  }

  struct OllamaResponse: Codable {
    let response: String
    let done: Bool
  }

  private let config: Config
  private let logger: Logger
  private var model: String

  private struct Config {
    let baseURL: URL
    let model: String

    static func loadFromEnvironment() -> Config {
      let defaultHost = "localhost"
      let defaultPort = "11434"

      let host = ProcessInfo.processInfo.environment["OLLAMA_HOST"] ?? defaultHost
      let port = ProcessInfo.processInfo.environment["OLLAMA_PORT"] ?? defaultPort

      return Config(
        baseURL: URL(string: "http://\(host):\(port)/api")!,
        model: ProcessInfo.processInfo.environment["OLLAMA_MODEL"] ?? ""
      )
    }
  }

  init(logger: Logger = .init(isVerbose: true)) {
    self.logger = logger
    let config = Config.loadFromEnvironment()
    self.config = config
    self.model = config.model
  }
  func getAIModels() async throws -> [String] {
    await logger.debug("Fetching available AI models...")

    let listModelsURL = config.baseURL.appendingPathComponent("tags")
    var request = URLRequest(url: listModelsURL)
    request.httpMethod = "GET"

    await logger.api("GET /api/tags")

    struct ModelResponse: Codable {
      struct Model: Codable {
        let name: String
        let modified_at: String
        let size: Int64

        private enum CodingKeys: String, CodingKey {
          case name, modified_at, size
        }
      }
      let models: [Model]
    }

    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(ModelResponse.self, from: data)
    let modelNames = response.models.map { $0.name }

    // Set default model if not configured
    if model.isEmpty && !modelNames.isEmpty {
      model = modelNames[0]
      await logger.debug("Selected default model: \(model)")
    }

    await logger.debug("Found \(modelNames.count) available models")
    return modelNames
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
      Keep description under 75 characters.
      Return only the commit message, nothing else.
      """

    await logger.api("POST /api/generate")

    var request = URLRequest(url: config.baseURL.appendingPathComponent("generate"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if model.isEmpty {
      let _ = try await getAIModels()
    }
    let requestBody = OllamaRequest(
      model: model,
      prompt: prompt,
      stream: false
    )
      await logger.debug("Using model: \(requestBody.model)")
    request.httpBody = try JSONEncoder().encode(requestBody)
    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(OllamaResponse.self, from: data)
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
//
//@available(macOS 14.0, *)
//extension OllamaService {
//    func processFiles(_ files: [GitFile]) async throws -> String {
//        try await files.concurrentMap { @Sendable file in
//            "File: \(file.path)\nChanges:\n\(file.changes)"
//        }.joined(separator: "\n\n")
//    }
//}
