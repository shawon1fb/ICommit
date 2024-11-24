//
//  Services.swift
//  GitCommitCLI
//
//  Created by shahanul on 11/24/24.
//
import Foundation

// Sources/GitCommitCLI/Services/GitService.swift
@available(macOS 14.0, *)
protocol GitServiceProtocol: Sendable {
  func getStagedFiles() async throws -> [GitFile]
  func commit(message: String) async throws
  func push() async throws
  func getAllBranchNames() async throws -> [String]
  func getCurrentBranchName() async throws -> String
}

@available(macOS 14.0, *)
actor GitService: GitServiceProtocol {
  private let shell: ShellServiceProtocol
  private let logger: Logger = Logger(isVerbose: false)
  init(shell: ShellServiceProtocol = ShellService()) {
    self.shell = shell
  }

  func commit(message: String) async throws {
    let _ = try await shell.execute("git commit -m \"\(message)\"")
  }

  func push() async throws {
    let _ = try await shell.execute("git push")
  }
}
@available(macOS 14.0, *)
extension GitService {
  func getStagedFiles() async throws -> [GitFile] {
    await logger.debug("Getting staged files...")
    let command = "git diff --cached --name-only"
    let pwd = "pwd"
    await logger.command(pwd)
    let dir = try await shell.execute(pwd)
    await logger.debug("Current directory: \(dir)")

    // First verify we're in a git repository
    do {
      let b = try await shell.execute("git rev-parse --is-inside-work-tree")
      await logger.debug("git rev-parse --is-inside-work-tree: \(dir) is \(b)")
    } catch {
      throw CLIError.invalidGitRepository
    }

    await logger.command(command)

    let fileNames = try await shell.execute(command)
    let files = try await fileNames.split(separator: "\n")
      .map(String.init)
      .concurrentMap { @Sendable [shell, logger] fileName in
        await logger.debug("Getting changes for file: \(fileName)")
        let changes = try await shell.execute("git diff --cached \(fileName)")
        return GitFile(path: fileName, changes: changes)
      }

    await logger.debug("Found \(files.count) staged files")
    return files
  }
}
@available(macOS 14.0, *)
extension GitService {
  func getAllBranchNames() async throws -> [String] {
    await logger.debug("Getting all branch names...")
    let command = "git branch --format='%(refname:short)'"

    await logger.command(command)

    let branchOutput = try await shell.execute(command)
    let branches =
      branchOutput
      .split(separator: "\n")
      .map(String.init)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }

    await logger.debug("Found \(branches.count) branches")
    return branches
  }

  func getCurrentBranchName() async throws -> String {
    await logger.debug("Getting current branch name...")
    let command = "git rev-parse --abbrev-ref HEAD"

    await logger.command(command)

    let branchName = try await shell.execute(command)
      .trimmingCharacters(in: .whitespacesAndNewlines)

    if branchName.isEmpty {
      throw CLIError.gitBranchError("Unable to determine current branch")
    }

    await logger.debug("Current branch: \(branchName)")
    return branchName
  }
}
