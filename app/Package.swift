// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeCompanion",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ClaudeCompanion", targets: ["ClaudeCompanion"])
    ],
    targets: [
        .executableTarget(
            name: "ClaudeCompanion",
            path: "ClaudeCompanion"
        )
    ]
)
