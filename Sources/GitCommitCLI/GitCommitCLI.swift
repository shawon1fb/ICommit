import ArgumentParser
// Sources/GitCommitCLI/GitCommitCLI.swift
import Foundation

@available(macOS 14.0, *)
struct GitCommitCLI: ParsableCommand, Decodable {
  // Make configuration nonisolated
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: "i-commit",
      abstract: "Generate AI-powered commit messages using Ollama"
    )
  }

  // Non-codable properties marked with @TransientProperty
  @TransientProperty
  private var gitService: GitServiceProtocol
  @TransientProperty
  private var aiService: AIServiceProtocol
  @TransientProperty
  private var consoleIO: ConsoleIO
  @TransientProperty
  private var spinner: LoadingSpinner

  // Decodable initializer
  init(from decoder: Decoder) throws {
    // Initialize services
    self.gitService = GitService()
    self.aiService = OllamaService()
    self.consoleIO = ConsoleIO()
    self.spinner = LoadingSpinner()
  }

  // Default initializer
  init() {
    self.gitService = GitService()
    self.aiService = OllamaService()
    self.consoleIO = ConsoleIO()
    self.spinner = LoadingSpinner()
  }

  // CodingKeys
  enum CodingKeys: String, CodingKey {
    case model
  }

  func run() async throws {
    // Get staged files
    print("Started CLI:".yellow)
    await spinner.start(message: "Checking staged files")
    let files = try await gitService.getStagedFiles()
    await spinner.stop()

    guard !files.isEmpty else {
      throw CLIError.noStagedFiles
    }

    // Display staged files
    print("\nStaged files count: \(files.count)".yellow)
    print("\nStaged files:".yellow)
    files.forEach { print($0.path) }

    // Generate commit message
    await spinner.start(message: "Generating commit message")
    let commitMessage = try await aiService.generateCommitMessage(for: files)
    await spinner.stop()
      

    print("\nGenerated commit message: ".yellow + commitMessage.formatted)

    // Confirm commit message
    if await consoleIO.askYesNo("Confirm the commit message?") {
      await spinner.start(message: "Committing changes")
      try await gitService.commit(message: commitMessage.formatted)
      await spinner.stop()

      print("Successfully committed!".green)

      // Ask for push
      if await consoleIO.askYesNo("Do you want to run 'git push'?") {
        await spinner.start(message: "Pushing to remote")
        try await gitService.push()
        await spinner.stop()
        print("Successfully pushed to remote!".green)
      }
    }
  }
}

// Sources/GitCommitCLI/TransientProperty.swift
@propertyWrapper
struct TransientProperty<T> {
  var wrappedValue: T

  init(wrappedValue: T) {
    self.wrappedValue = wrappedValue
  }
}
