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
