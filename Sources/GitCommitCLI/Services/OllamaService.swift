import Foundation

@available(macOS 14.0, *)
protocol AIServiceProtocol: Sendable {
    func generateCommitMessage(for files: [GitFile]) async throws -> CommitMessage
    func getAIModels() async throws -> [String]
    func getSelectedAIModel() async  -> String?
    func getBaseUrl() async  -> String?
    func promptForModelSelection() async throws -> String
    func setModel(_ modelName: String) async throws
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
    
    private let config: Config
    private let logger: Logger
    private var model: String
    private var cachedModels: [String]?
    private var lastFetchTime: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes cache
    
    init(logger: Logger = .init(isVerbose: true), initialModel: String? = nil) {
        self.logger = logger
        let config = Config.loadFromEnvironment()
        self.config = config
        self.model = initialModel ?? config.model
        self.cachedModels = nil
        self.lastFetchTime = nil
    }
    
    private func shouldRefetchModels() -> Bool {
        guard let lastFetch = lastFetchTime,
              let cached = cachedModels,
              !cached.isEmpty else {
            return true
        }
        return Date().timeIntervalSince(lastFetch) > cacheDuration
    }
    
    func getAIModels() async throws -> [String] {
        // Return cached models if they're still valid
        if !shouldRefetchModels(), let cached = cachedModels {
            await logger.debug("Using cached models list (\(cached.count) models)")
            return cached
        }
        
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
        
        // Update cache
        cachedModels = modelNames
        lastFetchTime = Date()
        
        await logger.debug("Found \(modelNames.count) available models")
        return modelNames
    }
    
    func setModel(_ modelName: String) async throws {
        let availableModels = try await getAIModels()
        guard availableModels.contains(modelName) else {
            throw CLIError.aiGenerationFailed("Model '\(modelName)' is not available. Available models: \(availableModels.joined(separator: ", "))")
        }
        model = modelName
        await logger.debug("Model set to: \(model)")
    }
    
    func promptForModelSelection() async throws -> String {
        let models = try await getAIModels()
        guard !models.isEmpty else {
            throw CLIError.aiGenerationFailed("No AI models available")
        }
        
        print("\nAvailable models:")
        for (index, model) in models.enumerated() {
            print("\(index + 1). \(model)")
        }
        
        while true {
            print("\nEnter the number of the model you want to use (1-\(models.count)) or 'q' to quit:")
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
                print("Invalid input. Please try again.")
                continue
            }
            
            if input.lowercased() == "q" || input.lowercased() == "quit" {
                throw CLIError.userCancelled
            }
            
            guard let selection = Int(input),
                  selection > 0 && selection <= models.count else {
                print("Invalid selection. Please enter a number between 1 and \(models.count)")
                continue
            }
            
            let selectedModel = models[selection - 1]
            await logger.debug("Model set to: \(selectedModel)".red)
            return selectedModel
        }
    }
    
    func generateCommitMessage(for files: [GitFile]) async throws -> CommitMessage {
        // Ensure we have a valid model selected
        if model.isEmpty {
            throw CLIError.aiGenerationFailed("No model selected")
        }
        
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
        
        return try parseCommitMessage(message)
    }
    
    private func parseCommitMessage(_ message: String) throws -> CommitMessage {
        // Remove any preceding text if present
        let actualMessage = message.components(separatedBy: ":\n").last ?? message
        let actualMessage2 = actualMessage.contains("`") ?
        actualMessage.split(separator: "`")[safe: 1].map(String.init) ?? actualMessage :
        actualMessage
//        let actualMessage3 = actualMessage2.components(separatedBy: "\"\n").last ?? actualMessage2
        
        let messageParts = actualMessage2.split(separator: ":", maxSplits: 1)
        guard messageParts.count == 2 else {
            print("message is : \(message)")
            throw CLIError.aiGenerationFailed("Invalid commit message format: missing description")
        }
        
        var tempScope = String(messageParts[0])
        tempScope.removeAll(where: { !$0.isLetter && !$0.isNumber && $0 != "(" && $0 != ")" })

        let typeAndScope = tempScope.trimmingCharacters(in: .whitespaces)
        let description = String(messageParts[1]).trimmingCharacters(in: .whitespaces)
        
        // Parse type and scope
        if typeAndScope.contains("(") {
            // Handle type with scope
            let typeScopeParts = typeAndScope.split(separator: "(", maxSplits: 1)
//            print("typeScopeParts is : \(typeScopeParts)")
            guard
                let typeString = typeScopeParts.first.map(String.init),
                let type = CommitType(rawValue: typeString.lowercased()),
                let scopeWithParenthesis = typeScopeParts.last.map(String.init)
            else {
                print("message is : \(message)")
                throw CLIError.aiGenerationFailed("Invalid commit type or scope format")
            }
            
            let scope = scopeWithParenthesis.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            return CommitMessage(type: type, scope: scope, description: description)
        } else {
            // Handle type without scope
            guard let type = CommitType(rawValue: typeAndScope.lowercased()) else {
                print("message is : \(message)")
                print("typeAndScope is : \(typeAndScope)")
                throw CLIError.aiGenerationFailed("Invalid commit type")
            }
            return CommitMessage(type: type, scope: "", description: description)
        }
    }
}

extension OllamaService{
    
    func getSelectedAIModel() async  -> String? {
        return model.isEmpty ? nil : model
    }
    
    func getBaseUrl() async -> String? {
        return config.baseURL.absoluteString
    }
}
// Helper extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
