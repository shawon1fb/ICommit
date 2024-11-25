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
    var commitMessage = try await aiService.generateCommitMessage(for: files)
    await spinner.stop()

    print("\nGenerated commit message: ".yellow + commitMessage.formatted)

    //TODO: add option to regenerate commit message again
    // TODO: add option to edit generated message

    var isMessageConfirmed = false
    while !isMessageConfirmed {
      print("\nGenerated commit message: ".yellow + commitMessage.formatted)

      print("\nOptions:".yellow)
      print("1. Confirm message")
      print("2. Regenerate message")
      print("3. Edit message manually")

      let choice = await consoleIO.askForChoice(options: 3)

      switch choice {
      case 1:
        isMessageConfirmed = true
      case 2:
        await spinner.start(message: "Regenerating commit message")
        commitMessage = try await aiService.generateCommitMessage(for: files)
        await spinner.stop()
      case 3:
        if let editedMessage = await editCommitMessage(commitMessage) {
          commitMessage = editedMessage
        }
      default:
        continue
      }
    }

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
        try await gitService.push(branchName: currentBranch)
        await spinner.stop()
        print("Successfully pushed to remote!".green)
      }
    }
  }

  private func editCommitMessage(_ currentMessage: CommitMessage) async -> CommitMessage? {
    print("\nCurrent message: ".yellow + currentMessage.formatted)

    // Display commit types with numbers and cancel option
    print("\nSelect commit type:".yellow)
    let types = CommitType.allCases
    for (index, type) in types.enumerated() {
      let marker = type == currentMessage.type ? "*" : " "
      print("\(marker) \(index + 1). \(type.rawValue): \(type.description)")
    }
    print("  0. Cancel edit")

    let typeChoice = await consoleIO.askForChoice(options: types.count, includeZero: true)
    if typeChoice == 0 {
      return currentMessage  // Return original message if canceled
    }

    let selectedType = types[typeChoice - 1]

    print("\nCurrent scope: ".yellow + currentMessage.scope)
    guard
      let newScope = await consoleIO.askForInput("Enter new scope (press Enter to keep current):")
    else {
      return nil
    }
    let finalScope = newScope.isEmpty ? currentMessage.scope : newScope

    print("\nCurrent description: ".yellow + currentMessage.description)
    guard
      let newDescription = await consoleIO.askForInput(
        "Enter new description (press Enter to keep current):")
    else {
      return nil
    }
    let finalDescription = newDescription.isEmpty ? currentMessage.description : newDescription

    return CommitMessage(
      type: selectedType,
      scope: finalScope,
      description: finalDescription
    )
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
