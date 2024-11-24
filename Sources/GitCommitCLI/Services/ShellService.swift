import Foundation

@available(macOS 14.0, *)
protocol ShellServiceProtocol: Sendable {
    func execute(_ command: String) async throws -> String
}

@available(macOS 14.0, *)
actor ShellService: ShellServiceProtocol {
    func execute(_ command: String) async throws -> String {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        process.arguments = ["-c", command]
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        
        // Create a Task to handle the process execution
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()
                
                // Read output data
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                process.terminationHandler = { process in
                    if process.terminationStatus == 0 {
                        if let output = String(data: outputData, encoding: .utf8) {
                            continuation.resume(returning: output)
                        } else {
                            continuation.resume(throwing: CLIError.gitCommandFailed("Could not decode output"))
                        }
                    } else {
                        let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                        continuation.resume(throwing: CLIError.gitCommandFailed(errorMessage))
                    }
                }
            } catch {
                continuation.resume(throwing: CLIError.gitCommandFailed(error.localizedDescription))
            }
        }
    }
}
