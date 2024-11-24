//
//  Sequence+Async.swift
//  GitCommitCLI
//
//  Created by shahanul on 11/24/24.
//
// Sources/GitCommitCLI/Extensions/Sequence+Async.swift
import Foundation

@available(macOS 14.0, *)
extension Sequence {
    func concurrentMap<T: Sendable>(_ transform: @Sendable @escaping (Element) async throws -> T) async throws -> [T] where Element: Sendable {
        try await withThrowingTaskGroup(of: (Int, T).self) { group in
            // Create array to store results in correct order
            var results = [(Int, T)]()
            results.reserveCapacity(self.underestimatedCount)
            
            // Add tasks with indexed elements
            for (index, element) in self.enumerated() {
                group.addTask {
                    let result = try await transform(element)
                    return (index, result)
                }
            }
            
            // Collect results
            for try await result in group {
                results.append(result)
            }
            
            // Sort and extract just the transformed values
            return results
                .sorted { $0.0 < $1.0 }
                .map { $1 }
        }
    }
}
