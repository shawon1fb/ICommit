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
      files.forEach { print($0.path.green) }

      if let baseURL = await aiService.getBaseUrl() {
          print("\nBaseURL : \(baseURL)".red)
      }
      
    //Check model is selected
    if let _ = await aiService.getSelectedAIModel() {
    } else {
      let _ = try await aiService.getAIModels()
      let selectedModel = try await aiService.promptForModelSelection()
      try await aiService.setModel(selectedModel)
    }

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

      // Show all available branches
      await spinner.start(message: "Fetching branch information")
      let allBranches = try await gitService.getAllBranchNames()
      let currentBranch = try await gitService.getCurrentBranchName()
      await spinner.stop()

      print("\nAvailable branches:".yellow)
      for branch in allBranches {
        if branch == currentBranch {
          print("* \(branch)".green)  // Current branch marked with asterisk
        } else {
          print("  \(branch)")
        }
      }

      print("\nYou are on branch:".yellow + " \(currentBranch)".green)

      // Ask for push
      if await consoleIO.askYesNo("Do you want to push to '\(currentBranch)'?") {
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
