//
//  Models.swift
//  GitCommitCLI
//
//  Created by shahanul on 11/24/24.
//
import Foundation
// Sources/GitCommitCLI/Models/Models.swift
@available(macOS 14.0, *)
enum CommitType: String, CaseIterable, Sendable {
    case feat, fix, docs, style, refactor, test, chore, build
    
    var description: String {
        switch self {
        case .feat: "New feature"
        case .fix: "Bug fix"
        case .docs: "Documentation"
        case .style: "Code style"
        case .refactor: "Code refactoring"
        case .test: "Testing"
        case .chore: "Maintenance"
        case .build: "Build"
        }
    }
}

struct GitFile:Sendable {
    let path: String
    let changes: String
    
    var scope: String {
        path.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? ""
    }
}

struct CommitMessage: Sendable {
    let type: CommitType
    let scope: String
    let description: String
    
    var formatted: String {
        "\(type.rawValue)(\(scope)): \(description)"
    }
}
