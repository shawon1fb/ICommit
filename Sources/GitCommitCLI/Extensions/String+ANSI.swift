//
//  String+ANSI.swift
//  GitCommitCLI
//
//  Created by shahanul on 11/24/24.
//
import Foundation
// Sources/GitCommitCLI/Extensions/String+ANSI.swift
// Sources/GitCommitCLI/Extensions/String+ANSI.swift
extension String {
    var red: String { "\u{001B}[31m\(self)\u{001B}[0m" }
    var green: String { "\u{001B}[32m\(self)\u{001B}[0m" }
    var yellow: String { "\u{001B}[33m\(self)\u{001B}[0m" }
    var blue: String { "\u{001B}[34m\(self)\u{001B}[0m" }
    var gray: String { "\u{001B}[37m\(self)\u{001B}[0m" }
}
