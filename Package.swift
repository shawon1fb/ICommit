// Package.swift
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ICommit",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "ICommit",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/GitCommitCLI"
        )
    ]
)

