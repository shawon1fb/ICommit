
// Sources/GitCommitCLI/main.swift
import Foundation

// The async entry point

struct MainCommand {
    static func main() async throws {
        let cli = GitCommitCLI()
        try await cli.run()
    }
}

do{
    try await MainCommand.main()
}
catch let error{
    print("Error: \(error)")
}

